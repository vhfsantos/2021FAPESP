import matplotlib; matplotlib.use('Agg')
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os
from operator import xor

def WriteFeatDic(file):
    FeatDic = dict()
    with open(file, 'r') as blast:
        for line in blast.readlines():
            if line.startswith("#"):
                continue
            row = line.strip().split('\t')
            key = row[0]+"..."+row[1]
            if key not in FeatDic.keys():
                FeatDic[key] = [{'start': row[2],
                                                        'end': row[3],
                                                        'MGE-size': (int(row[0]
                                                                                .split('_')[1]
                                                                                .split('-')[0])),
                                                        'read-size': row[6] }]
            else:
                FeatDic[key].append({'start': row[2],
                                                           'end': row[3],
                                                           'MGE-size': (int(row[0]
                                                                                .split('_')[1]
                                                                                .split('-')[0])),
                                                           'read-size': row[6] })
    return FeatDic

def GetFeatLength(FeatDic, barcode):
        LenList = []
        for k,v in FeatDic.items():
                if len(v) == 1:
                        end = int(v[0]['end'])
                        start = int(v[0]['start'])
                        LenList.append(end - start)
        with open('Stats/'+barcode+'LengthOfSingleHits.txt','w') as file:
                for Len in LenList:
                        file.write(str(Len)+'\n')

def GetFixedMGEs(FeatDic, barcode):
    with open('Stats/'+str(barcode)+'.fixedMGEs.txt','w') as FILEout:
        LenList = []
        ToRemove = []
        for k,v in FeatDic.items():
            if len(v) == 2:
                MGEsize = int(k.split('...')[0].split('_')[1].split('-')[0])
                end = int(v[0]['end'])
                start = int(v[1]['start'])
                GAPsize = int(start - end)
                if abs(GAPsize) >= MGEsize * 0.9 and abs(GAPsize) <= MGEsize * 1.9:
                    READname = k.split('...')[1]
                    READsize = v[1]['read-size']
                    FILEout.write('{}\n'.format(READname))
                LenList.append(str(end - start)+','+str(MGEsize))
        with open('Stats/'+barcode+'GapSizeDoubleHits.txt','w') as file:
            for Len in LenList:
                file.write(str(Len)+'\n')

def GetOptionalMGEs(FeatDic, barcode):
        with open('Stats/'+str(barcode)+'.optionalMGEs.txt','w') as FILEout:
                LenList = []
                ToRemove = []
                for k,v in FeatDic.items():
                        if len(v) == 1:
                                end = int(v[0]['end'])
                                start = int(v[0]['start'])
                                GAPsize = int(start - end)
                                if abs(GAPsize) >= 300 * 0.9 and abs(GAPsize) <= 300 * 1.9:
                                        READname = k.split('...')[1]
                                        READsize = v[0]['read-size']
                                        FILEout.write('{}\n'.format(READname))

def GetFeatCount(FeatDic):
        CountDic = dict()
        for key, value in FeatDic.items():
                CountDic[key] = len(value)
        return CountDic

def CountValues(CountDic):
        import pandas as pd
        df = pd.DataFrame.from_dict(CountDic, orient = 'index')
        return df

def GetRows(file, barcode):
    print(1)
    data = WriteFeatDic(file)
    print(1)
    GetFeatLength(data, barcode)
    print(1)
    GetFixedMGEs(data, barcode)
    print(1)
    GetOptionalMGEs(data, barcode)
    print(1)
    data = GetFeatCount(data)
    print(1)
    data = CountValues(data)
    print(1)
    serie = data[0].value_counts()
    serie = pd.Series(serie.div(sum(serie)), name = barcode)
    return pd.DataFrame(serie).T

def PlotUngrafmentedSingleHitsCount():
    df = pd.DataFrame()
    for bc in range(6,0,-1):
        barcode = 'barcode'+str(bc).zfill(2)
        df[barcode] = pd.read_csv('Stats/'+barcode+'LengthOfSingleHits.txt', header=None)[0]
        
    df = df[df.columns[::-1]]
    f1 = df >= 300 * 0.9
    f2 = df <= 300 * 1.9

    plt.rcParams.update({'font.size': 15})
    (f1 & f2).astype(int).sum().sort_values(ascending=False).plot.bar(figsize=(6,5))
    plt.title('# Unfragmented single hits')
    plt.savefig('Stats/UnfragmentedSingleHitsCount.svg')


def main():
    for dir in ['Stats']:
        try:
            os.mkdir(dir)
        except FileExistsError:
            pass
        
    plot_df = pd.DataFrame()
    for bc in range(6,0,-1):
        barcode = 'barcode'+str(bc).zfill(2)
        file = 'supervision-'+barcode+'/'+barcode+'.blastn'
        print('-- parsing '+file)
        plot_df = plot_df.append(GetRows(file, barcode))
                # ------------
    PlotUngrafmentedSingleHitsCount()
    ax = plot_df.plot.barh(stacked=True) #, cmap = 'viridis')
    plt.xlabel("Proportion of reads containing locus")
    plt.legend(loc='upper center', ncol=4, title='# Hits for the locus')
    ax.spines['left'].set_visible(False)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    plt.savefig('Stats/NumberofHits.svg')

if __name__ == "__main__":
        main()
