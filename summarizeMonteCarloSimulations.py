#!/usr/bin/env python
import glob
import pandas as pd
import os

# Path of folder with your csv files
path = os.getcwd()
files = glob.glob("*.csv")

all_df = []
for f in files:
    df = pd.read_csv(f, sep=',')
    df['file_name'] = f.split('/')[-1]
    all_df.append(df)
    
merged_df = pd.concat(all_df, ignore_index=True)

g_df = merged_df.groupby(['Type','ID', 'Equation'])

def lb_quantile(x):
    return x.quantile(0.025)

def ub_quantile(x):
    return x.quantile(0.975)

summary_df = g_df.agg({'Value':['mean', 'std', 'size', lb_quantile, ub_quantile]})

folder_name = os.path.basename(os.getcwd())

summary_df.reset_index().to_csv(f'stat_{folder_name}.csv', encoding='utf-8', header=True, index=False)