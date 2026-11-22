import sys, struct, zlib
# Uso: quant.py in.raw out.png ncolors [dither 0/1]   (PNG de paleta com 3 niveis de transparencia parcial)
raw=open(sys.argv[1],'rb').read(); n=int(sys.argv[3]); dither=len(sys.argv)>4 and sys.argv[4]=='1'
w,h=struct.unpack('<II',raw[:8]); px=raw[8:]
cls=bytearray(w*h); hist={}
for i in range(w*h):
    a=px[i*4+3]
    c=3 if a>=192 else 2 if a>=112 else 1 if a>=32 else 0
    cls[i]=c
    if c==3:
        o=i*4;k=((px[o]>>3)<<10)|((px[o+1]>>3)<<5)|(px[o+2]>>3);hist[k]=hist.get(k,0)+1
boxes=[list(hist.items())]
def rng(b):
    mn=[31]*3;mx=[0]*3
    for k,_ in b:
        c=((k>>10)&31,(k>>5)&31,k&31)
        for j in range(3):
            mn[j]=min(mn[j],c[j]);mx[j]=max(mx[j],c[j])
    return [mx[j]-mn[j] for j in range(3)]
while len(boxes)<n-1:
    best=None;bs=0
    for i,b in enumerate(boxes):
        if len(b)<2:continue
        r=rng(b);s=max(r)*sum(c for _,c in b)**0.5
        if s>bs:bs=s;best=(i,r)
    if best is None:break
    i,r=best;b=boxes.pop(i);ch=r.index(max(r));sh=[10,5,0][ch]
    b.sort(key=lambda kc:(kc[0]>>sh)&31)
    tot=sum(c for _,c in b);acc=0;cut=1
    for j,(k,c) in enumerate(b):
        acc+=c
        if acc>=tot/2:cut=max(1,min(len(b)-1,j+1));break
    boxes.append(b[:cut]);boxes.append(b[cut:])
pal=[(0,0,0)];alp=[0]
for b in boxes:
    tot=sum(c for _,c in b);rs=gs=bs_=0
    for k,c in b:
        rs+=((k>>10)&31)*c;gs+=((k>>5)&31)*c;bs_+=(k&31)*c
    pal.append((int(round(rs/tot*8+4)),int(round(gs/tot*8+4)),int(round(bs_/tot*8+4))));alp.append(255)
nop=len(pal);cache={}
def near(r,g,b):
    k=(r>>2,g>>2,b>>2);v=cache.get(k)
    if v is None:
        bd=1e18;bi=1
        for i in range(1,nop):
            p=pal[i];d=(p[0]-r)**2+(p[1]-g)**2+(p[2]-b)**2
            if d<bd:bd=d;bi=i
        cache[k]=bi;v=bi
    return v
idx=bytearray(w*h);extra={}
if dither:
    er=[[0.0]*(w+2) for _ in range(2)];eg=[[0.0]*(w+2) for _ in range(2)];eb=[[0.0]*(w+2) for _ in range(2)]
for y in range(h):
    if dither:
        er[0],er[1]=er[1],[0.0]*(w+2);eg[0],eg[1]=eg[1],[0.0]*(w+2);eb[0],eb[1]=eb[1],[0.0]*(w+2)
    for x in range(w):
        i=y*w+x;c=cls[i]
        if c==0:continue
        o=i*4;r,g,b=px[o],px[o+1],px[o+2]
        if c<3:
            j=near(r,g,b);key=(j,c)
            if key not in extra:
                if len(pal)<256:
                    pal.append(pal[j]);alp.append(85*c);extra[key]=len(pal)-1
                else:extra[key]=j
            idx[i]=extra[key];continue
        if dither:
            r=min(255,max(0,r+er[0][x+1]));g=min(255,max(0,g+eg[0][x+1]));b=min(255,max(0,b+eb[0][x+1]))
        j=near(int(r),int(g),int(b));idx[i]=j
        if dither:
            p=pal[j];dr,dg,db=r-p[0],g-p[1],b-p[2]
            for (dx,dy,f) in ((1,0,7/16),(-1,1,3/16),(0,1,5/16),(1,1,1/16)):
                xx=x+dx+1;t=0 if dy==0 else 1
                er[t][xx]+=dr*f;eg[t][xx]+=dg*f;eb[t][xx]+=db*f
def chunk(t,d):
    c=struct.pack('>I',len(d))+t+d
    return c+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
rows=bytearray();prev=bytearray(w)
for y in range(h):
    row=idx[y*w:(y+1)*w]
    sub=bytes((row[x]-(row[x-1] if x else 0))&255 for x in range(w))
    up=bytes((row[x]-prev[x])&255 for x in range(w))
    best=min([(0,bytes(row)),(1,sub),(2,up)],key=lambda c:sum(min(v,256-v) for v in c[1]))
    rows.append(best[0]);rows+=best[1];prev=row
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,3,0,0,0))+chunk(b'PLTE',b''.join(bytes(p) for p in pal))+chunk(b'tRNS',bytes(alp))+chunk(b'IDAT',zlib.compress(bytes(rows),9))+chunk(b'IEND',b'')
open(sys.argv[2],'wb').write(png)
print(sys.argv[2],len(png),'bytes',len(pal),'entradas')
