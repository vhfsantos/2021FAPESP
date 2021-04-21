#!/bin/bash

check_deps() {
    for app in blastn; do
        command -v $app >/dev/null 2>&1 || error_exit "$0\nERROR: Cannot find \
		${app}. Make sure $app is installed and in your PATH variable"
    done
}

check_deps
usage() {
USAGE="
SGAssembly: Supervised Genome Assembly for procariots
vhfsantos, 2020

	Usage: SupAssembly -r <reads.fq> -m <mge.fa> -t <N> \\
                   -o <output.txt> -b <BC01>

		-r          fastq file for basecalled reads to be used as subject
		-m          fasta file containing MGE sequenced to be used as query
		-o          output filename
		-b          barcode identifier (ex.: BC01)
		-t          number of threads (default: 10)
	
"
printf "%s\\n" "$USAGE"
exit 2
}

HOME_DIR=${0%/*}

# parse args

THREADS=10
FMT=6

while getopts  "hr:t:m:o:f:b:" OPT; do
    case $OPT in
    h)
      usage
      ;;
    r)
      READS=${OPTARG}
      ;;
    t)
      THREADS=${OPTARG}
      ;;
    m)
       MGE=${OPTARG}
      ;;
    o)
       OUTPUT=${OPTARG}
      ;;
    b)
      BC=${OPTARG}
     ;;
  esac
done

declare -A array # associative arrays need to be declared!
array=( [-r]="${READS}" [-m]="${MGE}" [-o]="${OUTPUT}" [-b]="${BC}" )

for idx in "${!array[@]}"; do
	if [[ ! ${array[$idx]} ]]; then
	echo "ERROR: $idx argument must be supplied. exiting..."
	usage
	fi
done


echo "
---------------------------------------
reads: ${READS}
mge: ${MGE}
out: ${OUTPUT}
threads: ${THREADS}
bc: ${BC}
--------------------------------------"

#exit 0





# make temp files
mkdir -p ${OUTPUT}

READ_BNAME=`basename ${READS}`

FASTA=${OUTPUT}/${READ_BNAME%.*}.fasta

if [ ! -f ${FASTA} ]; then
	echo "= Converting fastq to fasta..."
	#touch ${FASTA}
	sed -n '1~4s/^@/>/p;2~4p' ${READS} > ${FASTA}
	echo "==== Done"
else 
	echo "==== file ${FASTA} already exists... skipping"
fi

if [ ! -f ${FASTA}.nsq ]; then
	echo "= Creating database for BLAST..."
	makeblastdb -in ${FASTA} \
		-dbtype nucl
	echo "==== Done"
else
	echo "==== blast database already exists... skipping"
fi

MAPPINGOUT=${OUTPUT}/${READ_BNAME%.*}.MGE-mapping

if [ ! -f "${MAPPINGOUT}" ]; then
        echo "= Mapping MGEs with ${MGE}"
        blastn -db ${FASTA} -query ${MGE} \
		-strand plus \
		-evalue 1e-03 \
		-outfmt "7 qacc sacc sstart send qlen slen evalue" \
		-task blastn -num_threads ${THREADS} \
		-out $MAPPINGOUT > ${OUTPUT}/MGE-mapping.err 2>&1
		echo "==== Done"
else
	echo "==== MGE-mapping already done... skipping"
fi

if [ ! -f ${MAPPINGOUT}.cov90p.cannot-extract-150bp-upstream ]; then
	echo "= Parsing BLAST results"

	echo ==== Writting files to be analyzed separetelly:
	echo ==== a. hits for which we cannot extract 150bp upstreeam the MGE	
	grep -v "#" ${MAPPINGOUT} | awk '{if($4-$3+1>=$5*0.9){print $0}}' | \
		awk 'BEGIN{OFS="\t"}{if($3<150){print$0}}' \
		> ${MAPPINGOUT}.cov90p.cannot-extract-150bp-upstream

        echo ==== b. hits for which we cannot extract 150bp downstream the MGE \
		\(read ends before it\)
	grep -v "#" ${MAPPINGOUT} | awk '{if($4-$3+1>=$5*0.9){print $0}}' | \
		awk 'BEGIN{OFS="\t"}{if($4>$6-150){print$0}}' \
		> ${MAPPINGOUT}.cov90p.cannot-extract-150bp-downstream

	echo ==== writing hits that cannot be use \(both 1 and 2 are true\)
	grep -v "#" ${MAPPINGOUT} | awk '{if($4-$3+1>=$5*0.9){print $0}}' | \
		awk 'BEGIN{OFS="\t"}{if($4>$6-150 && $3<150){print$0}}' \
		> ${MAPPINGOUT}.cov90p.cannot-extract-anything

	echo ==== removing all hits written above
	# we have hits that can easily extract the 300bp window

	grep -v "#" ${MAPPINGOUT} | awk '{if($4-$3+1>=$5*0.9){print $0}}' | \
		grep -v -f ${MAPPINGOUT}.cov90p.cannot-extract-150bp-upstream | \
		grep -v -f ${MAPPINGOUT}.cov90p.cannot-extract-150bp-downstream \
		> ${MAPPINGOUT}.cov90p.to-extract


	# here I am writting the query files. I editted the query name so
	# that it contains: (i) the name of the read the MGE was mapped 
	# (ii) the MGE size, and (iii) the MGE name. These three fields are
	# separated by '_' (see the last awk field: $2_$5_$1)
	echo ==== writting 150bp-upstream seqs
	bedtools getfasta -fi ${FASTA} -name -bed <(cat \
		${MAPPINGOUT}.cov90p.to-extract | \
		awk 'BEGIN{OFS="\t"}{ print $2, $3-150, $3, $2"_"$5"_"$1}') | sed 's/::.*//' | \
		awk '/^>/{$0=$0"-"(++i)}1' > ${MAPPINGOUT}.query.upstream

	echo ==== writting 150bp-downstream seqs
	bedtools getfasta -fi ${FASTA} -name -bed <(cat \
		${MAPPINGOUT}.cov90p.to-extract | \
		awk 'BEGIN{OFS="\t"}{ print $2, $4, $4+150, $2"_"$5"_"$1}') | sed 's/::.*//' | \
		awk '/^>/{$0=$0"_"(++i)}1' > ${MAPPINGOUT}.query.downstream

	echo ==== merging...
	python ${HOME_DIR}/MergeUpstreamDownstream.py \
		-u ${MAPPINGOUT}.query.upstream \
		-d ${MAPPINGOUT}.query.downstream \
		-o ${MAPPINGOUT}.query.merged
	echo "==== Done"
else
	echo "==== results already parsed... skipping"
fi

BLASTOUT=${OUTPUT}/${READ_BNAME%.*}.blastn

if [ ! -f "${BLASTOUT}" ]; then
        echo "= Querying 300bp frags with BLASTn"
        blastn -db ${FASTA} -query ${MAPPINGOUT}.query.merged \
		-evalue 1e-03 \
		-outfmt "7 qacc sacc sstart send length qlen slen evalue" \
		-task megablast -num_threads ${THREADS} -strand plus \
		-out $BLASTOUT > ${OUTPUT}/blastn.err 2>&1
		echo "==== Done"
else
	echo "==== MGE-mapping already done... skipping"
fi

#if [ ! -f "${BC}-heatmap.svg" ]; then
#	echo "= Plotting heatmap"
#	python ${HOME_DIR}/ReadBlastnAndPlotHeatmap.py \
#		-i $BLASTOUT -b ${BC}
#else
#	echo "==== Heatmap already plotted... skipping"
#fi
