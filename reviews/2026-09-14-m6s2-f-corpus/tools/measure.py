from PIL import Image
import numpy as np, sys, json
BASE='/Users/jacklusher/development/comtran-compiler/comtran-manuals/F28-8043/images/page-%d.png'
def rows(page, thr):
    a=np.array(Image.open(BASE%page).convert('L'))
    dark=(a<128).sum(axis=1); out=[];inr=False
    for y,v in enumerate(dark):
        if v>thr and not inr: s=y;inr=True
        elif v<=thr and inr: out.append((s,y));inr=False
    return a,out
def groups(a,y0,y1,gap=7):
    band=a[y0:y1]; c=(band<128).sum(axis=0); out=[];inr=False
    for x,v in enumerate(c):
        if v>0 and not inr: s=x;inr=True
        elif v==0 and inr: out.append((s,x));inr=False
    if inr: out.append((s,len(c)))
    m=[]
    for s,e in out:
        if m and s-m[-1][1]<gap: m[-1]=(m[-1][0],e)
        else: m.append((s,e))
    return m
page=int(sys.argv[1]); thr=int(sys.argv[2]); P=float(sys.argv[3])
a,rs=rows(page,thr)
print(len(rs))
for i,(y0,y1) in enumerate(rs):
    g=groups(a,y0,y1)
    if not g: continue
    x0=g[0][0]
    print(i,y0,y1,[(round((s-x0)/P)+1) for s,e in g])
