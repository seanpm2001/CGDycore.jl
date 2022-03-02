function [Vort]=FVort2VecDSS(v1,v2,CG,Param)
OP=CG.OrdPoly+1;
NF=Param.Grid.NumFaces;
nz=Param.Grid.nz;
v1CG=reshape(v1(reshape(CG.Glob,OP*OP*NF,1),:)...
  ,OP,OP,NF,nz);
v2CG=reshape(v2(reshape(CG.Glob,OP*OP*NF,1),:)...
  ,OP,OP,NF,nz);
vC1=reshape(...
  CG.DS*reshape(Param.dXdxIC(:,:,:,:,1,1).*v2CG...
  -Param.dXdxIC(:,:,:,:,1,2).*v1CG...
  ,OP,OP*NF*nz)...
  ,OP,OP,NF,nz)...
  -permute(...
  reshape(...
  CG.DS*reshape(...
  permute(...
  -v2CG.*Param.dXdxIC(:,:,:,:,2,1)...
  +v1CG.*Param.dXdxIC(:,:,:,:,2,2)...
  ,[2 1 3 4])...
  ,OP,OP*NF*nz)...
  ,OP,OP,NF,nz)...
  ,[2 1 3 4]);


Vort=zeros(CG.NumG,nz);
for iM=1:size(CG.FaceGlob,2)
  Vort(reshape(CG.Glob(:,CG.FaceGlob(iM).Ind,:)...
    ,OP*OP*size(CG.FaceGlob(iM).Ind,1),1),:)...
    =Vort(reshape(CG.Glob(:,CG.FaceGlob(iM).Ind,:)...
    ,OP*OP*size(CG.FaceGlob(iM).Ind,1),1),:)...
    +reshape(vC1(:,:,CG.FaceGlob(iM).Ind,:)...
    ,OP*OP*size(CG.FaceGlob(iM).Ind,1),nz);
end
Vort=Vort./CG.M;
end
