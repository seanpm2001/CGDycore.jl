function FDiv3Vec!(F,cCG,v1CG,v2CG,v3CG,CG,Param)
# noch uberarbeiten
OP=CG.OrdPoly+1;
NF=Param.Grid.NumFaces;
nz=Param.Grid.nz;
# Contravariant components

vCon = @view Param.CacheC[:,:,:,:,1]
DvCon = @view Param.CacheC[:,:,:,:,2]

@views vCon .= (v1CG.*Param.dXdxIC[:,:,:,:,1,1] .+ v2CG.*Param.dXdxIC[:,:,:,:,1,2]) .* cCG;
mul!(reshape(DvCon,OP,OP*NF*nz),CG.DS,reshape(vCon,OP,OP*nz*NF))
F .= F .- DvCon

@views vCon .= (v1CG.*Param.dXdxIC[:,:,:,:,2,1] .+ v2CG.*Param.dXdxIC[:,:,:,:,2,2]) .* cCG;
mul!(reshape(PermutedDimsArray(DvCon,(2,1,3,4)),OP,OP*NF*nz),CG.DS,reshape(PermutedDimsArray(vCon,(2,1,3,4)),OP,OP*nz*NF))
F .= F .- DvCon

@views vCon[:,:,:,1:end-1] .= 0.5*((v1CG[:,:,:,1:end-1] .+ v1CG[:,:,:,2:end]).*
        Param.dXdxIF[:,:,:,2:end-1,3,1] .+
      (v2CG[:,:,:,1:end-1] .+ v2CG[:,:,:,2:end]).*
        Param.dXdxIF[:,:,:,2:end-1,3,2]) .+
       v3CG[:,:,:,2:end-1].*
        Param.dXdxIF[:,:,:,2:end-1,3,3];

@views vCon[:,:,:,1:end-1] .= 0.5*(cCG[:,:,:,1:end-1] .+ cCG[:,:,:,2:end]).*vCon[:,:,:,1:end-1];
if nz>1
  @views DvCon[:,:,:,1] .= 0.5*vCon[:,:,:,1];
  @views DvCon[:,:,:,2:end-1] .= 0.5*(vCon[:,:,:,2:end-1] .- vCon[:,:,:,1:end-2]);
  @views DvCon[:,:,:,end] .= -0.5*vCon[:,:,:,end-1]; # 0.5 Metric
else
  @views DvCon[:,:,:,1] .= 0
end
F .= F .- DvCon

end

