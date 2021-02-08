# Estudo da instabilidade genômica de _Halobacterium salinarum_ via sequenciamento de _reads_ longas

__Vinícius H. F. Santos, Tie Koide__

---
# Intro

Este repositório contém _scripts_ utilizados na segunda etapa do (trabalho de iniciação científica)[https://bv.fapesp.br/pt/bolsas/186664/estudo-da-instabilidade-genomica-de-halobacterium-salinarum-nrc-1-via-sequenciamento-de-reads-longas/] intitulado **Estudo da instabilidade genômica de _Halobacterium salinarum_ via sequenciamento de _reads_ longas**, financiado pela Fundação de Amparo à Pesquisa do Estado de São Paulo (FAPESP).

As análises que aqui se seguem tomam como partida o sequênciamento de seis linhagens de _H. salinarum_ com o dispositivo minION. Os arquivos (não disponíveis neste repositório) já passaram pela etapa de demultiplex, basecalling e de remoção de adaptadores, e estão em formato `.fastq` organizados da seguinte forma:

```
analysis/
  └ porechop_output/
    ├ barcode01.fastq
    ├ barcode02.fastq
    ├ ...
    └ barcode06.fastq
```
