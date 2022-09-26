function FGrad3Vec!(F,cCG,CG,Global,iF)
@unpack TCacheC1, TCacheC2, TCacheCC3, TCacheCC4 = Global.ThreadCache
  OP=CG.OrdPoly+1;
  NF=Global.Grid.NumFaces;
  nz=Global.Grid.nz;
  uPos=Global.Model.uPos
  vPos=Global.Model.vPos
  wPos=Global.Model.wPos

  D1cCG = TCacheC1[Threads.threadid()]
  D2cCG = TCacheC2[Threads.threadid()]
  D3cCG = TCacheCC3[Threads.threadid()]
  D3cCGE = TCacheCC4[Threads.threadid()]
  @views dXdxIF = Global.Metric.dXdxIF[:,:,:,:,:,iF];
  @views dXdxIC = Global.Metric.dXdxIC[:,:,:,:,:,iF];


  @inbounds for iz=1:nz-1
    @views @. D3cCG[:,:,iz] = 0.5*(cCG[:,:,iz+1] - cCG[:,:,iz])
    @views @. F[:,:,iz,wPos] -= dXdxIF[:,:,iz+1,3,3]*D3cCG[:,:,iz] 
  end  
  if nz>1
    @views  @. D3cCGE[:,:,1] = 1.5*D3cCG[:,:,1] - 0.5*D3cCG[:,:,2]
    @views mul!(D1cCG[:,:],CG.DS,cCG[:,:,nz])
    @views mul!(D2cCG[:,:],cCG[:,:,nz],CG.DST)
    @views  @. D3cCGE[:,:,nz] = D3cCG[:,:,nz-1]
    @views @. F[:,:,nz,uPos] -= (dXdxIC[:,:,nz,1,1]*D1cCG[:,:] +
      dXdxIC[:,:,nz,2,1]*D2cCG[:,:] +
      dXdxIC[:,:,nz,3,1]*D3cCGE[:,:,nz] )
    @views @. F[:,:,nz,vPos] -= (dXdxIC[:,:,nz,1,2]*D1cCG[:,:] +
      dXdxIC[:,:,nz,2,2]*D2cCG[:,:] +
      dXdxIC[:,:,nz,3,2]*D3cCGE[:,:,nz] )
  else
    @views  @. D3cCGE[:,:,1] = 0.0  
  end  
  @views mul!(D1cCG[:,:],CG.DS,cCG[:,:,1])
  @views mul!(D2cCG[:,:],cCG[:,:,1],CG.DST)
  @views @. F[:,:,1,uPos] -= (dXdxIC[:,:,1,1,1]*D1cCG[:,:] +
    dXdxIC[:,:,1,2,1]*D2cCG[:,:] +
    dXdxIC[:,:,1,3,1]*D3cCGE[:,:,1] ) 
  @views @. F[:,:,1,vPos] -= (dXdxIC[:,:,1,1,2]*D1cCG[:,:] +
    dXdxIC[:,:,1,2,2]*D2cCG[:,:] +
    dXdxIC[:,:,1,3,2].*D3cCGE[:,:,1] )
  @inbounds for iz=2:nz-1
    @views mul!(D1cCG[:,:],CG.DS,cCG[:,:,iz])
    @views mul!(D2cCG[:,:],cCG[:,:,iz],CG.DST)
    @views @. D3cCGE[:,:,iz] = 0.5*(D3cCG[:,:,iz-1] + D3cCG[:,:,iz]);
    @views @. F[:,:,iz,uPos] -= (dXdxIC[:,:,iz,1,1]*D1cCG[:,:] +
      dXdxIC[:,:,iz,2,1]*D2cCG[:,:] +
      dXdxIC[:,:,iz,3,1]*D3cCGE[:,:,iz] )
    @views @. F[:,:,iz,vPos] -= (dXdxIC[:,:,iz,1,2]*D1cCG[:,:] +
      dXdxIC[:,:,iz,2,2]*D2cCG[:,:] +
      dXdxIC[:,:,iz,3,2]*D3cCGE[:,:,iz] )
  end
end

function FGrad3RhoVec!(F,cCG,RhoCG,CG,Global,iF)
@unpack TCacheC1, TCacheC2, TCacheCC3, TCacheCC4 = Global.ThreadCache
  OP=CG.OrdPoly+1;
  NF=Global.Grid.NumFaces;
  nz=Global.Grid.nz;
  uPos=Global.Model.uPos
  vPos=Global.Model.vPos
  wPos=Global.Model.wPos

  D1cCG = TCacheC1[Threads.threadid()]
  D2cCG = TCacheC2[Threads.threadid()]
  D3cCG = TCacheCC3[Threads.threadid()]
  D3cCGE = TCacheCC4[Threads.threadid()]
  @views dXdxIF = Global.Metric.dXdxIF[:,:,:,:,:,iF];
  @views dXdxIC = Global.Metric.dXdxIC[:,:,:,:,:,iF];

  @inbounds for iz=1:nz-1
    @views @. D3cCG[:,:,iz] = 0.5*(cCG[:,:,iz+1] - cCG[:,:,iz])
    @views @. F[:,:,iz,wPos] -= dXdxIF[:,:,iz+1,3,3]*D3cCG[:,:,iz] / 
      (0.5*(RhoCG[:,:,iz]+RhoCG[:,:,iz+1]))
  end  
  if nz>1
    @views  @. D3cCGE[:,:,1] = 1.5*D3cCG[:,:,1] - 0.5*D3cCG[:,:,2]
    @views mul!(D1cCG[:,:],CG.DS,cCG[:,:,nz])
    @views mul!(D2cCG[:,:],cCG[:,:,nz],CG.DST)
    @views  @. D3cCGE[:,:,nz] = D3cCG[:,:,nz-1]
    @views @. F[:,:,nz,uPos] -= (dXdxIC[:,:,nz,1,1]*D1cCG[:,:] +
      dXdxIC[:,:,nz,2,1]*D2cCG[:,:] +
      dXdxIC[:,:,nz,3,1]*D3cCGE[:,:,nz] ) / RhoCG[:,:,nz]
    @views @. F[:,:,nz,vPos] -= (dXdxIC[:,:,nz,1,2]*D1cCG[:,:] +
      dXdxIC[:,:,nz,2,2]*D2cCG[:,:] +
      dXdxIC[:,:,nz,3,2]*D3cCGE[:,:,nz] ) / RhoCG[:,:,nz]
  else
    @views  @. D3cCGE[:,:,1] = 0.0  
  end  
  @views mul!(D1cCG[:,:],CG.DS,cCG[:,:,1])
  @views mul!(D2cCG[:,:],cCG[:,:,1],CG.DST)
  @views @. F[:,:,1,uPos] -= (dXdxIC[:,:,1,1,1]*D1cCG[:,:] +
    dXdxIC[:,:,1,2,1]*D2cCG[:,:] +
    dXdxIC[:,:,1,3,1].*D3cCGE[:,:,1] ) / RhoCG[:,:,1]
  @views @. F[:,:,1,vPos] -= (dXdxIC[:,:,1,1,2]*D1cCG[:,:] +
    dXdxIC[:,:,1,2,2]*D2cCG[:,:] +
    dXdxIC[:,:,1,3,2].*D3cCGE[:,:,1] ) / RhoCG[:,:,1]
  @inbounds for iz=2:nz-1
    @views mul!(D1cCG[:,:],CG.DS,cCG[:,:,iz])
    @views mul!(D2cCG[:,:],cCG[:,:,iz],CG.DST)
    @views @. D3cCGE[:,:,iz] = 0.5*(D3cCG[:,:,iz-1] + D3cCG[:,:,iz]);
    @views @. F[:,:,iz,uPos] -= (dXdxIC[:,:,iz,1,1]*D1cCG[:,:] +
      dXdxIC[:,:,iz,2,1]*D2cCG[:,:] +
      dXdxIC[:,:,iz,3,1].*D3cCGE[:,:,iz] ) / RhoCG[:,:,iz]
    @views @. F[:,:,iz,vPos] -= (dXdxIC[:,:,iz,1,2]*D1cCG[:,:] +
      dXdxIC[:,:,iz,2,2]*D2cCG[:,:] +
      dXdxIC[:,:,iz,3,2]*D3cCGE[:,:,iz] ) / RhoCG[:,:,iz]
  end
end

function FGrad3RhoExpVec!(F,cCG,RhoCG,CG,Global,iF)
@unpack TCacheC1, TCacheC2, TCacheCC3, TCacheCC4 = Global.ThreadCache
  OP=CG.OrdPoly+1;
  NF=Global.Grid.NumFaces;
  nz=Global.Grid.nz;
  uPos=Global.Model.uPos
  vPos=Global.Model.vPos

  D1cCG = TCacheC1[Threads.threadid()]
  D2cCG = TCacheC2[Threads.threadid()]
  D3cCG = TCacheCC3[Threads.threadid()]
  D3cCGE = TCacheCC4[Threads.threadid()]
  @views dXdxIF = Global.Metric.dXdxIF[:,:,:,:,:,iF];
  @views dXdxIC = Global.Metric.dXdxIC[:,:,:,:,:,iF];

  @inbounds for iz=1:nz-1
    @views @. D3cCG[:,:,iz] = 0.5*(cCG[:,:,iz+1] - cCG[:,:,iz])
  end  
  if nz>1
    @views  @. D3cCGE[:,:,1] = 1.5*D3cCG[:,:,1] - 0.5*D3cCG[:,:,2]
    @views mul!(D1cCG[:,:],CG.DS,cCG[:,:,nz])
    @views mul!(D2cCG[:,:],cCG[:,:,nz],CG.DST)
    @views  @. D3cCGE[:,:,nz] = D3cCG[:,:,nz-1]
    @views @. F[:,:,nz,uPos] -= (dXdxIC[:,:,nz,1,1]*D1cCG[:,:] +
      dXdxIC[:,:,nz,2,1]*D2cCG[:,:] +
      dXdxIC[:,:,nz,3,1]*D3cCGE[:,:,nz] ) / RhoCG[:,:,nz]
    @views @. F[:,:,nz,vPos] -= (dXdxIC[:,:,nz,1,2]*D1cCG[:,:] +
      dXdxIC[:,:,nz,2,2]*D2cCG[:,:] +
      dXdxIC[:,:,nz,3,2]*D3cCGE[:,:,nz] ) / RhoCG[:,:,nz]
  else
    @views  @. D3cCGE[:,:,1] = 0.0  
  end  
  @views mul!(D1cCG[:,:],CG.DS,cCG[:,:,1])
  @views mul!(D2cCG[:,:],cCG[:,:,1],CG.DST)
  @views @. F[:,:,1,uPos] -= (dXdxIC[:,:,1,1,1]*D1cCG[:,:] +
    dXdxIC[:,:,1,2,1]*D2cCG[:,:] +
    dXdxIC[:,:,1,3,1].*D3cCGE[:,:,1] ) / RhoCG[:,:,1]
  @views @. F[:,:,1,vPos] -= (dXdxIC[:,:,1,1,2]*D1cCG[:,:] +
    dXdxIC[:,:,1,2,2]*D2cCG[:,:] +
    dXdxIC[:,:,1,3,2].*D3cCGE[:,:,1] ) / RhoCG[:,:,1]
  @inbounds for iz=2:nz-1
    @views mul!(D1cCG[:,:],CG.DS,cCG[:,:,iz])
    @views mul!(D2cCG[:,:],cCG[:,:,iz],CG.DST)
    @views @. D3cCGE[:,:,iz] = 0.5*(D3cCG[:,:,iz-1] + D3cCG[:,:,iz]);
    @views @. F[:,:,iz,uPos] -= (dXdxIC[:,:,iz,1,1]*D1cCG[:,:] +
      dXdxIC[:,:,iz,2,1]*D2cCG[:,:] +
      dXdxIC[:,:,iz,3,1].*D3cCGE[:,:,iz] ) / RhoCG[:,:,iz]
    @views @. F[:,:,iz,vPos] -= (dXdxIC[:,:,iz,1,2]*D1cCG[:,:] +
      dXdxIC[:,:,iz,2,2]*D2cCG[:,:] +
      dXdxIC[:,:,iz,3,2]*D3cCGE[:,:,iz] ) / RhoCG[:,:,iz]
  end
end

function FGrad3RhoImpVec!(F,cCG,RhoCG,CG,Global,iF)
@unpack TCacheC1, TCacheC2, TCacheCC3, TCacheCC4 = Global.ThreadCache
  OP=CG.OrdPoly+1;
  NF=Global.Grid.NumFaces;
  nz=Global.Grid.nz;
  uPos=Global.Model.uPos
  vPos=Global.Model.vPos
  wPos=Global.Model.wPos

  D1cCG = TCacheC1[Threads.threadid()]
  D2cCG = TCacheC2[Threads.threadid()]
  D3cCG = TCacheCC3[Threads.threadid()]
  D3cCGE = TCacheCC4[Threads.threadid()]
  @views dXdxIF = Global.Metric.dXdxIF[:,:,:,:,:,iF];
  @views dXdxIC = Global.Metric.dXdxIC[:,:,:,:,:,iF];

  @inbounds for iz=1:nz-1
    @views @. D3cCG[:,:,iz] = 0.5*(cCG[:,:,iz+1] - cCG[:,:,iz])
    @views @. F[:,:,iz,wPos] -= dXdxIF[:,:,iz+1,3,3]*D3cCG[:,:,iz] / 
      (0.5*(RhoCG[:,:,iz]+RhoCG[:,:,iz+1]))
  end  
end

function FGrad3RhoImpGlobalVec!(F,c,Rho,Global,iG)
  nz=Global.Grid.nz
  @views dz = Global.Metric.dz[:,iG]

  @inbounds for iz=1:nz-1
    F[iz] -= 4.0 * (c[iz+1] - c[iz]) / (dz[iz+1] + dz[iz]) / (Rho[iz+1] + Rho[iz])
  end  
end
