function FCurlNon3Vec(v1CG,v2CG,wCG,wCCG,CG,Param)
OP=CG.OrdPoly+1;
NF=Param.Grid.NumFaces;
nz=Param.Grid.nz;
dXdxIC = Param.cache.dXdxIC
dXdxIF = Param.cache.dXdxIF
# Fu(1)
# -vv\left(DX(a^{12}u-a^{11}v)+(a^{22}u-a^{21}v)DY^T
# +\frac{d(a^{32}u-a^{31}v)}{dz}\right)
#
# ww(DXa^{11}w+a^{21}wDY^T+\frac{da^{31}w}{dz}-\frac{da^{33}u}{dz})

# Fu(2)
# uu\left(DX(a^{12}u-a^{11}v)+(a^{22}u-a^{21}v)DY^T
# +\frac{d(a^{32}u-a^{31}v)}{dz}\right)
#
# ww(DXa^{12}w+a^{22}wDY^T+\frac{da^{32}w}{dz}-\frac{d a^{33}v}{dz})

# Fw
# -uu((DXa^{11}w+a^{21}wDY^T+\frac{da^{31}w}{dz}-\frac{da^{33}u}{dz})
# -vv*((DXa^{12}w+a^{22}wDY^T+\frac{da^{32}w}{dz}-\frac{da^{33}v}{dz})

vHat1 = dXdxIC[:,:,:,:,1,2].*v1CG .- dXdxIC[:,:,:,:,1,1].*v2CG;
vHat2 = dXdxIC[:,:,:,:,2,2].*v1CG .- dXdxIC[:,:,:,:,2,1].*v2CG;
vHat3 = dXdxIC[:,:,:,:,3,2].*v1CG .- dXdxIC[:,:,:,:,3,1].*v2CG;



DXvHat1=reshape(
  CG.DS*reshape(vHat1,OP,OP*nz*NF),
  OP,OP,NF,nz);
DYvHat2= permute(
  reshape(
  CG.DS*reshape(
  permute(vHat2
  ,[2,1,3,4])
  ,OP,OP*NF*nz)
  ,OP,OP,NF,nz)
  ,[2,1,3,4]);

DZvHat3=zeros(OP,OP,NF,nz);
if nz>1
  DZvHat3[:,:,:,1]=0.5*(vHat3[:,:,:,2]-vHat3[:,:,:,1]);
  DZvHat3[:,:,:,2:nz-1]=0.25*(vHat3[:,:,:,3:nz]-vHat3[:,:,:,1:nz-2]);
  DZvHat3[:,:,:,nz]=0.5*(vHat3[:,:,:,nz]-vHat3[:,:,:,nz-1]);
end

# DXa^{11}w
DXwHat11=reshape(CG.DS*reshape(
  dXdxIF[:,:,:,:,1,1].*wCG
  ,OP,OP*NF*(nz+1))
  ,OP,OP,NF,nz+1);
# DXa^{12}w
DXwHat12=reshape(CG.DS*reshape(
  dXdxIF[:,:,:,:,1,2].*wCG
  ,OP,OP*NF*(nz+1))
  ,OP,OP,NF,nz+1);
# a^{21}wDY^T
DYwHat21=  permute(
  reshape(
  CG.DS*reshape(
  permute(
  reshape(
  dXdxIF[:,:,:,:,2,1].*wCG
  ,OP,OP,NF,nz+1)
  ,[2,1,3,4])
  ,OP,OP*NF*(nz+1))
  ,OP,OP,NF,nz+1)
  ,[2,1,3,4]);
# a^{22}wDY^T
DYwHat22= permute(
  reshape(
  CG.DS*reshape(
  permute(
  reshape(
  dXdxIF[:,:,:,:,2,2].*wCG
  ,OP,OP,NF,nz+1)
  ,[2,1,3,4])
  ,OP,OP*NF*(nz+1))
  ,OP,OP,NF,nz+1)
  ,[2,1,3,4]);

# \frac{da^{31}w}{dz}-\frac{da^{33}u}{dz}
#uHat1=reshape(Param.dXdxI(:,:,:,:,3,3),OP*OP*NF,nz).*v1CG;
uHat1=dXdxIC[:,:,:,:,3,3].*v1CG;
DZuuHat31=zeros(OP,OP,NF,nz+1);
if nz>1
  DZuuHat31[:,:,:,1]=0.5*(uHat1[:,:,:,2]-uHat1[:,:,:,1]);
  DZuuHat31[:,:,:,2:nz]=0.5*(uHat1[:,:,:,2:nz]-uHat1[:,:,:,1:nz-1]);
  DZuuHat31[:,:,:,nz+1]=0.5*(uHat1[:,:,:,nz]-uHat1[:,:,:,nz-1]);
end

wwHat31=dXdxIF[:,:,:,:,3,1].*wCG;
DZwwHat31=0.5*(wwHat31[:,:,:,2:nz+1]-wwHat31[:,:,:,1:nz]);
# \frac{da^{32}w}{dz}-\frac{da^{33}v}{dz}
#uHat2=reshape(Param.dXdxI(:,:,:,:,3,3),OP*OP*NF,nz).*v2CG;
uHat2=dXdxIC[:,:,:,:,3,3].*v2CG;
DZuuHat32=zeros(OP,OP,NF,nz+1);
if nz>1
  DZuuHat32[:,:,:,1]=0.5*(uHat2[:,:,:,2]-uHat2[:,:,:,1]);
  DZuuHat32[:,:,:,2:nz]=0.5*(uHat2[:,:,:,2:nz]-uHat2[:,:,:,1:nz-1]);
  DZuuHat32[:,:,:,nz+1]=0.5*(uHat2[:,:,:,nz]-uHat2[:,:,:,nz-1]);
end
wwHat32=dXdxIF[:,:,:,:,3,2].*wCG;
DZwwHat32=0.5*(wwHat32[:,:,:,2:nz+1]-wwHat32[:,:,:,1:nz]);



FuHat=zeros(OP,OP,NF,nz,3);
#FuHat[:,:,:,1]=reshape(-(DXvHat1+DYvHat2+DZvHat3).*v2CG+(DXwHat11+DYwHat21+DZwHat31).*wC
#  ,OP*OP,NF,nz);
# Fu(1)
# -vv\left(DX(a^{12}u-a^{11}v)+(a^{22}u-a^{21}v)DY^T
# +\frac{d(a^{32}u-a^{31}v)}{dz}\right)
#
# ww(DXa^{11}w+a^{21}wDY^T+\frac{da^{31}w}{dz}-\frac{da^{33}u}{dz})
Vort3=DXvHat1+DYvHat2+DZvHat3;
if Param.Coriolis
  str = Param.CoriolisType
  if str == "Sphere"
      Vort3=Vort3-reshape(2.0*Param.Omega*sin.(
        repmat(reshape(Param.lat[:,:,:],OP*OP*NF,1),1,nz))
        ,OP,OP,NF,nz).*
        Param.JC;
  elseif str == "Beta-Plane"
      Vort3=Vort3-reshape((Param.f0+Param.beta0*(
        reshape(abs.(Param.X[:,:,2,:,:]),OP,OP,NF,nz)-Param.y0)).*
        Param.J[:,:,:,:],OP*OP*NF,nz);
  end
end
FuHat[:,:,:,:,1]= -Vort3.*v2CG+
  (DZwwHat31).*wCCG+
  0.5*((DXwHat11[:,:,:,1:nz]  +DYwHat21[:,:,:,1:nz]-
  DZuuHat31[:,:,:,1:nz]).*wCG[:,:,:,1:nz]+
  (DXwHat11[:,:,:,2:nz+1]+DYwHat21[:,:,:,2:nz+1]-
  DZuuHat31[:,:,:,2:nz+1]).*wCG[:,:,:,2:nz+1]);
FuHat[:,:,:,:,2]= Vort3.*v1CG+
  (DZwwHat32).*wCCG +
  0.5*((DXwHat12[:,:,:,1:nz]  +DYwHat22[:,:,:,1:nz] -
    DZuuHat32[:,:,:,1:nz]).*wCG[:,:,:,1:nz]+
  (DXwHat12[:,:,:,2:nz+1]+DYwHat22[:,:,:,2:nz+1] -
    DZuuHat32[:,:,:,2:nz+1]).*wCG[:,:,:,2:nz+1]);

DZwwHat31=(DZwwHat31).*v1CG;
DZwwHat32=(DZwwHat32).*v2CG;
FuHat[:,:,:,1:nz-1,3]=
  (-DXwHat11[:,:,:,2:nz]-DYwHat21[:,:,:,2:nz]+DZuuHat31[:,:,:,2:nz]).*
    (0.5*(v1CG[:,:,:,1:nz-1]+v1CG[:,:,:,2:nz])) -0.5*
    (DZwwHat31[:,:,:,1:nz-1]+DZwwHat31[:,:,:,2:nz]) +
    (-DXwHat12[:,:,:,2:nz]-DYwHat22[:,:,:,2:nz]+DZuuHat32[:,:,:,2:nz]).*
    (0.5*(v2CG[:,:,:,1:nz-1]+v2CG[:,:,:,2:nz])) -0.5*
    (DZwwHat32[:,:,:,1:nz-1]+DZwwHat32[:,:,:,2:nz]);

return FuHat
end
