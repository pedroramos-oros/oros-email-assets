// sticker(src,{w,outline,sx,sy,shadowGrow}) -> Promise<canvas>  (contorno branco + sombra dura noite)
function loadImg(src){return new Promise((res,rej)=>{const i=new Image();i.onload=()=>res(i);i.onerror=rej;i.src=src;});}
function tint(img,w,h,S,color){const c=document.createElement('canvas');c.width=w*S;c.height=h*S;const x=c.getContext('2d');x.drawImage(img,0,0,w*S,h*S);x.globalCompositeOperation='source-in';x.fillStyle=color;x.fillRect(0,0,w*S,h*S);return c;}
async function sticker(src,o){
  const S=2,w=o.w,img=await loadImg(src),h=Math.round(w*img.naturalHeight/img.naturalWidth);
  const out=o.outline||5,sx=o.sx??4,sy=o.sy??5,sg=o.shadowGrow??2,pad=out+Math.max(sx,sy)+sg+2;
  const cw=w+pad*2,ch=h+pad*2,c=document.createElement('canvas');c.width=cw*S;c.height=ch*S;c.style.width=cw+'px';c.style.height=ch+'px';
  const x=c.getContext('2d'),white=tint(img,w,h,S,'#fff'),dark=tint(img,w,h,S,'#0D0C08');
  const ring=(cv,R,ox,oy)=>{for(let a=0;a<360;a+=6){const r=a*Math.PI/180;x.drawImage(cv,(pad+Math.cos(r)*R+ox)*S,(pad+Math.sin(r)*R+oy)*S);}x.drawImage(cv,(pad+ox)*S,(pad+oy)*S);};
  ring(dark,out+sg,sx,sy);ring(white,out,0,0);
  x.drawImage(img,pad*S,pad*S,w*S,h*S);
  c.dataset.pad=pad;return c;
}
