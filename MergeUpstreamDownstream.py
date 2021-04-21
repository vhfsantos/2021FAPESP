import argparse
from pyfaidx import Fasta

def main():

	parser = argparse.ArgumentParser()
	parser.add_argument("-u","--upstream", type=str, help="upstream fasta file", required = True)
	parser.add_argument("-d","--downstream", type=str, help="downstream fasta file", required = True)
	parser.add_argument("-o","--output", type=str, help="output fasta name", required = True)

	args = parser.parse_args()

	with Fasta(args.upstream) as upstream,\
		Fasta(args.downstream) as downstream, \
		open(args.output,'w') as result:
		for a,b in zip(upstream, downstream):
			result.write('>' + a.name)
			result.write('\n'+str(a))
			result.write(str(b)+'\n')

if __name__ == "__main__":
    main()
