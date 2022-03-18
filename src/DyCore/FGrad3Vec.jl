function FGrad3Vec(cCG,CG,Param)
OP=CG.OrdPoly+1;
NF=Param.Grid.NumFaces;
nz=Param.Grid.nz;
dXdxIF = Param.cache.dXdxIF
dXdxIC = Param.cache.dXdxIC
D1cCG=reshape(
  CG.DS*reshape(cCG,OP,OP*NF*nz)
  ,OP,OP,NF,nz);
D2cCG= permute(
  reshape(
  CG.DS *reshape(permute(cCG
  ,[2 1 3 4])
  ,OP,OP*NF*nz)
  ,OP,OP,NF,nz)
  ,[2 1 3 4]);

D3cCG=0.5*(cCG[:,:,:,2:nz]-cCG[:,:,:,1:nz-1]);

gradCG=zeros(OP,OP,NF,nz,3);
gradCG[:,:,:,1:nz-1,3]=dXdxIF[:,:,:,2:nz,3,3].*D3cCG;
D3cCGE=zeros(OP,OP,NF,nz);
if nz>1
  D3cCGE[:,:,:,1]=D3cCG[:,:,:,1];
  D3cCGE[:,:,:,2:nz-1]=0.5*(D3cCG[:,:,:,1:end-1]+D3cCG[:,:,:,2:end]);
  D3cCGE[:,:,:,nz]=D3cCG[:,:,:,nz-1];
end

gradCG[:,:,:,:,1]=dXdxIC[:,:,:,:,1,1].*D1cCG+
  dXdxIC[:,:,:,:,2,1].*D2cCG+
  dXdxIC[:,:,:,:,3,1].*D3cCGE;
gradCG[:,:,:,:,2]=dXdxIC[:,:,:,:,1,2].*D1cCG+
  dXdxIC[:,:,:,:,2,2].*D2cCG+
  dXdxIC[:,:,:,:,3,2].*D3cCGE;

return gradCG
end
