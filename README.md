# Estudo da instabilidade genômica de _Halobacterium salinarum_ via sequenciamento de _reads_ longas

__Vinícius H. F. Santos, Tie Koide__

---
Este repositório contém _scripts_ utilizados na segunda etapa do trabalho de iniciação científica intitulado [Estudo da instabilidade genômica de _Halobacterium salinarum_ via sequenciamento de _reads_ longas](https://bv.fapesp.br/pt/bolsas/186664/estudo-da-instabilidade-genomica-de-halobacterium-salinarum-nrc-1-via-sequenciamento-de-reads-longas/), financiado pela Fundação de Amparo à Pesquisa do Estado de São Paulo (FAPESP).

As análises que aqui se seguem tomam como partida o sequênciamento de seis linhagens de _H. salinarum_ com o dispositivo minION. Os arquivos (não disponíveis neste repositório) já passaram pela etapa de demultiplex, basecalling e de remoção de adaptadores, e estão em formato `.fastq`.

Além desses arquivos, as análises a seguir utilizam também o arquivo de anotação de elementos genético móveis (MGEs) em _H. salinarum_. Para gerá-lo, extraímos os MGEs completos anotados por [Pfeiffer et al 2020](https://pubmed.ncbi.nlm.nih.gov/31296677/), e em seguida, agrupamos elementos compartilhando 95% de similaridade ou mais. Assim, o arquivo `Hsal-MGEs-0.95.fasta` contém a sequência dos agrupamentos formados. 

```
porechop_output/
  ├ barcode01.fastq
  ├ barcode02.fastq
  ├ ...
  └ barcode06.fastq
```

## Execução das etapas do proesso de supervisão

Para executar as etapas do processo de supervisão, o _script_ `00-GetReadsToRemove.sh` foi executado da seguinte maneira:

```
$ for BC in {01..06}; do
    00-GetReadsToRemove.sh \
        -r porechop_output/barcode${BC}.fastq \
        -m Hsal-MGEs-0.95.fasta \
        -o supervision_barcode${BC} \
        -t 15
done
```

Depois dessa etapa, tivemos a seguinte estrutura de diretórios:

```
┌ porechop_output/
├ supervision_barcode01/
├ supervision_barcode02/
├ ...
└ supervision_barcode06/

```

## Análise exploratória

A próxima etapa foi rodar os _scripts_ de análise exploratório dos resultados. Esses _scripts_ criam arquivos de texto utilizados para plotar todos os gráficos mostrados no relatório do trabalho. Além disso, criam também os arquivos `barcode??.to-remove.txt` com os nomes das _reads_ que devem ser removidas no processo de supervisão.

```
$ python 01-GetStats.py
$ for BC in {01..06}; do python 02-GetReadsToRemove.py --barcode ${BC}; done
$ Rscipt 03-PlotRidges.R
```

Essa etapa resultou na seguinte estrutura:

```
┌ porechop_output/
├ supervision_barcode01/
├ supervision_barcode02/
├ ...
├ supervision_barcode06/
└ Stats/
```

## Remoção das _reads_ contendo MGEs opcionais

Finalmente, os arquivos `barcode??.to-remove.txt` foram utilizados para remover as _reads_ contendo MGEs opcionais, finalizando assim o processo de supervisão. Essa etapa foi feita utilizando o _scripts_ `filterbyname.sh` do pacote [BBMap](https://sourceforge.net/projects/bbmap/):


```
$ for i in {01..06}; do
    filterbyname.sh in=porechop_output/barcode${i}.fastq \
        names=Stats/barcode${i}-to-remove.txt \
        out=barcode${i}-to-assembly.fastq \
        include=f qin=33
done
```

Com isso, foram gerados arquivos `barcode??-to-assembly.fastq`, que serviram de _input_ para os montadores de genoma.
