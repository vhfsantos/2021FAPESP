import matplotlib; matplotlib.use('Agg')
from matplotlib_venn import venn3, venn3_circles
from matplotlib import pyplot as plt
import argparse


def GetReadsToRemove(bc):
        with open('Stats/barcode0'+bc+'.fixedMGEs.txt','r') as fxd:
                fixed = []
                for line in fxd.readlines():
                        fixed.append(line)
        with open('Stats/barcode0'+bc+'.optionalMGEs.txt','r') as opt:
                optional = []
                for line in opt.readlines():
                        optional.append(line)
        with open('Stats/barcode0'+bc+'.all-reads.txt', 'r') as allids:
                allreads = []
                for line in allids.readlines():
                        allreads.append(line)
        venn3([set(allreads), 
                   set(fixed),
                   set(optional)],
                   set_labels=('total reads', 'fixed', 'optional'))
        plt.savefig('Stats/bc0'+bc+'.svg')
        print('Writing txt file')
        ToRemove = set(optional).difference(set(fixed))
        with open('Stats/barcode0'+bc+'.to-remove.txt','w') as file:
                for read in ToRemove:
                        file.write(read)

parser = argparse.ArgumentParser(description='Plot Venn diagram of barcode data')
parser.add_argument('--barcode',
                    help='barcode identifier')

args = parser.parse_args()
GetReadsToRemove(args.barcode)
