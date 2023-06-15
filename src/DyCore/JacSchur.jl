mutable struct JStruct
    JRhoW::Array{Float64, 3}
    JWTh::Array{Float64, 3}
    JWRho::Array{Float64, 3}
    JWRhoV::Array{Float64, 3}
    JThW::Array{Float64, 3}
    JTrW::Array{Float64, 4}
    JWW::Array{Float64, 3}
    tri::Array{Float64, 3}
    sw::Array{Float64, 2}
    JDiff::Array{Float64, 3}
    JAdvC::Array{Float64, 3}
    JAdvF::Array{Float64, 3}
    CompTri::Bool
    CompJac::Bool
    CacheCol1::Array{Float64, 1}
    CacheCol2::Array{Float64, 1}
    CacheCol3::Array{Float64, 1}
end

function JStruct()
  JRhoW=zeros(0,0,0)
  JWTh=zeros(0,0,0)
  JWRho=zeros(0,0,0)
  JWRhoV=zeros(0,0,0)
  JThW=zeros(0,0,0)
  JTrW=zeros(0,0,0,0)
  JWW=zeros(0,0,0)
  tri=zeros(0,0,0)
  sw=zeros(0,0)
  JDiff=zeros(0,0,0)
  JAdvC=zeros(0,0,0)
  JAdvF=zeros(0,0,0)
  CompTri=false
  CompJac=false
  CacheCol1=zeros(0)
  CacheCol2=zeros(0)
  CacheCol3=zeros(0)
  return JStruct(
    JRhoW,
    JWTh,
    JWRho,
    JWRhoV,
    JThW,
    JTrW,
    JWW,
    tri,
    sw,
    JDiff,
    JAdvC,
    JAdvF,
    CompTri,
    CompJac,
    CacheCol1,
    CacheCol2,
    CacheCol3,
  )
end  

function JStruct(NumG,nz,NumTr)
  JRhoW=zeros(2,nz,NumG)
  JWTh=zeros(2,nz,NumG)
  JWRho=zeros(2,nz,NumG)
  JWRhoV=zeros(2,nz,NumG)
  JThW=zeros(2,nz,NumG)
  JTrW=zeros(2,nz,NumG,NumTr)
  JWW=zeros(1,nz,NumG)
  tri=zeros(3,nz,NumG)
  sw=zeros(nz,NumG)
  JDiff=zeros(3,nz,NumG)
  JAdvC=zeros(3,nz,NumG)
  JAdvF=zeros(3,nz-1,NumG)
  CompTri=false
  CompJac=false
  CacheCol1=zeros(nz)
  CacheCol2=zeros(nz)
  CacheCol3=zeros(nz)
  return JStruct(
    JRhoW,
    JWTh,
    JWRho,
    JWRhoV,
    JThW,
    JTrW,
    JWW,
    tri,
    sw,
    JDiff,
    JAdvC,
    JAdvF,
    CompTri,
    CompJac,
    CacheCol1,
    CacheCol2,
    CacheCol3,
  )
end
function JacSchur!(J,U,CG,Global,Param,::Val{:VectorInvariant})
  (;  RhoPos,
      uPos,
      vPos,
      wPos,
      ThPos,
      NumV,
      NumTr) = Global.Model
  nz=Global.Grid.nz;
  NF=Global.Grid.NumFaces
  nCol=size(U,2);
  nJ=nCol*nz;

  D = J.CacheCol2
  abswConF = J.CacheCol2
  abswConC = J.CacheCol2
  @views DF = J.CacheCol2[1:nz-1]
  Dp = J.CacheCol2
  Dm = J.CacheCol3
  dPdTh = J.CacheCol1
  dPdRhoV = J.CacheCol1
  K = J.CacheCol1

  @inbounds for iC=1:nCol
    @views Pres = Global.Cache.AuxG[:,iC,1]
    @views Rho = U[:,iC,RhoPos]
    @views Th = U[:,iC,ThPos]
    @views Tr = U[:,iC,NumV+1:end]
    @views dz = Global.Metric.dz[:,iC]

    @views @. D[1:nz-1] = -(Rho[1:nz-1] * dz[1:nz-1] + Rho[2:nz] * dz[2:nz]) /
      (dz[1:nz-1] + dz[2:nz])
    # JRhoW low bidiagonal matrix
    # First row diagonal
    # Second row lower diagonal
    @views @. J.JRhoW[1,:,iC] = D / dz
    @views @. J.JRhoW[2,1:nz-1,iC] = -D[1:nz-1] / dz[2:nz]

    dPresdTh!(dPdTh, Th, Rho, Tr, Global);
    @views @. Dp[1:nz-1] = dPdTh[2:nz] /  (0.5 * (Rho[1:nz-1] * dz[1:nz-1] + 
      Rho[2:nz] * dz[2:nz])) 
    @views @. Dm[1:nz-1] = dPdTh[1:nz-1] / (0.5 * (Rho[1:nz-1] * dz[1:nz-1] +
      Rho[2:nz] * dz[2:nz])) 
    # JWRhoTh upper bidiagonal matrix
    # First row upper diagonal
    # Second row diagonal
    @views @. J.JWTh[1,2:nz,iC] = -Dp[1:nz-1]
    @views @. J.JWTh[2,:,iC] = Dm

    if Global.Model.Equation == "CompressibleMoist"
      dPresdRhoV!(dPdRhoV, Th, Rho, Tr, Pres, Global);
      @views @. Dp[1:nz-1] = dPdRhoV[2:nz] /  (0.5 * (Rho[1:nz-1] * dz[1:nz-1] + 
        Rho[2:nz] * dz[2:nz])) 
      @views @. Dm[1:nz-1] = dPdRhoV[1:nz-1] / (0.5 * (Rho[1:nz-1] * dz[1:nz-1] +
        Rho[2:nz] * dz[2:nz])) 
      @views @. J.JWRhoV[1,2:nz,iC] = -Dp[1:nz-1]
      @views @. J.JWRhoV[2,:,iC] = Dm
    end  

    # JWRho upper bidiagonal matrix
    # First row upper diagonal
    # Second row diagonal
    @views @. D[1:nz-1] = Global.Phys.Grav  / (Rho[1:nz-1] * dz[1:nz-1] + Rho[2:nz] * dz[2:nz])
    @views @. J.JWRho[1,2:nz,iC] = -D[1:nz-1] * dz[2:nz]
    @views @. J.JWRho[2,1:nz,iC] = -D * dz

    # JRhoThW low bidiagonal matrix
    # First row diagonal
    # Second row lower diagonal
    @views @. D[1:nz-1] = -(Th[1:nz-1] * dz[1:nz-1] + Th[2:nz] * dz[2:nz]) /
      (dz[1:nz-1] + dz[2:nz])
    @views @. J.JThW[1,:,iC] = D / dz
    @views @. J.JThW[2,1:nz-1,iC] = -D[1:nz-1] / dz[2:nz]
    if Global.Model.Thermo == "TotalEnergy" 
      @views @. D[1:nz-1] -= 0.5*(Pres[1:nz-1] + Pres[2:nz]) 
    elseif Global.Model.Thermo == "InternalEnergy"
      @views @. D = Pres / dz
      @views @. J.JThW[1,:,iC] = J.JThW[1,:,iC] - D
      @views @. J.JThW[2,1:nz-1,iC] = J.JThW[2,1:nz-1,iC] + D[2:nz]
    end  

    @inbounds for iT = 1 : NumTr
      @views @. D[1:nz-1] = -(Tr[1:nz-1,iT] * dz[1:nz-1] + Tr[2:nz,iT] * dz[2:nz]) /
        (dz[1:nz-1] + dz[2:nz])
      @views @. J.JTrW[1,:,iC,iT] = D / dz
      @views @. J.JTrW[2,1:nz-1,iC,iT] = -D[1:nz-1] / dz[2:nz]
    end    

    if Global.Model.Damping
      @views DampingKoeff!(J.JWW[1,:,iC],CG,Global)
    end
    if Global.Model.VerticalDiffusion
      @views JDiff = J.JDiff[:,:,iC]
      @. JDiff = 0.0
      @views KV = Global.Cache.AuxG[:,iC,2]
      # The Rho factor is already included in KV
      @views @. DF = - (KV[1:nz-1] + KV[2:nz]) / (dz[1:nz-1] + dz[2:nz])
      # J tridiagonal matrix
      # First row upper diagonal
      # Second row diagonal
      # Third row lower diagonal
      @views @. JDiff[1,2:nz] = DF / Rho[2:nz] / dz[1:nz-1]
      @views @. JDiff[3,1:nz-1] = DF / Rho[1:nz-1] / dz[2:nz]
      @views @. JDiff[2,2:nz] = -DF
      @views @. JDiff[2,1:nz-1] += -DF
      @views @. JDiff[2,1:nz] /= (Rho * dz)
    end
    @views JAdvC = J.JAdvC[:,:,iC]
    @. JAdvC = 0.0
    @views wConF = Global.Cache.AuxG[:,iC,3]
    @. abswConF = abs(wConF)
    @views @. JAdvC[1,2:nz] = -(abswConF[1:nz-1] - wConF[1:nz-1]) / (2.0 * Rho[2:nz] * dz[1:nz-1])
    @views @. JAdvC[3,1:nz-1] = (-abswConF[1:nz-1] - wConF[1:nz-1]) / (2.0 * Rho[1:nz-1] * dz[2:nz]) 
    @views @. JAdvC[2,2:nz] = +abswConF[1:nz-1] - wConF[1:nz-1] 
    @views @. JAdvC[2,1:nz-1] += +abswConF[1:nz-1] + wConF[1:nz-1]
    @views @. JAdvC[2,1:nz] /= (2.0 * Rho * dz)

    @views JAdvF = J.JAdvF[:,:,iC]
    @. JAdvF = 0.0
    @views wConC = Global.Cache.AuxG[1:nz,iC,4]
    @. abswConC = abs(wConC)
    @views @. JAdvF[1,2:nz-1] = -(abswConC[2:nz-1] - wConC[2:nz-1]) / (dz[1:nz-2] + dz[2:nz-1])
    @views @. JAdvF[3,1:nz-2] = (-abswConC[2:nz-1] - wConC[2:nz-1]) / (dz[2:nz-1] + dz[3:nz]) 
    @views @. JAdvF[2,1:nz-1] = +abswConC[1:nz-1] - wConC[1:nz-1] 
    @views @. JAdvF[2,1:nz-1] += +abswConC[2:nz] + wConC[2:nz]
    @views @. JAdvF[2,1:nz-1] /= (dz[1:nz-1] + dz[2:nz])
  end
end

function JacSchur!(J,U,CG,Global,Param,::Val{:Conservative})
  (;  RhoPos,
      uPos,
      vPos,
      wPos,
      ThPos,
      NumV,
      NumTr) = Global.Model
  nz=Global.Grid.nz;
  NF=Global.Grid.NumFaces
  nCol=size(U,2);
  nJ=nCol*nz;

  D = J.CacheCol2
  Dp = J.CacheCol2
  Dm = J.CacheCol3
  dPdTh = J.CacheCol1
  K = J.CacheCol1

  @inbounds for iC=1:nCol
    @views Pres = Global.Cache.AuxG[:,iC,1]
    @views Rho = U[:,iC,RhoPos]
    @views Th = U[:,iC,ThPos]
    @views Tr = U[:,iC,NumV+1:end]
    @views dz = Global.Metric.dz[:,iC]

    @views @. J.JRhoW[1,:,iC] = -1.0 / dz
    @views @. J.JRhoW[2,1:nz-1,iC] = 1.0 / dz[2:nz]

    dPresdTh!(dPdTh, Th, Rho, Tr, Global);
    @views @. Dp[1:nz-1] = dPdTh[2:nz] /  (0.5 * (dz[1:nz-1] + dz[2:nz]))
    @views @. Dm[1:nz-1] = dPdTh[1:nz-1] / (0.5 * (dz[1:nz-1] + dz[2:nz]))
    @views @. J.JWTh[1,2:nz,iC] = -Dp[1:nz-1]
    @views @. J.JWTh[2,:,iC] = Dm

    if Global.Model.Equation == "CompressibleMoist"
      dPresdRhoV!(dPdTh, Th, Rho, Tr, Pres, Global);
      @views @. Dp[1:nz-1] = dPdTh[2:nz] /  (0.5 * (dz[1:nz-1] + dz[2:nz]))
      @views @. Dm[1:nz-1] = dPdTh[1:nz-1] / (0.5 *(dz[1:nz-1] + dz[2:nz]))
      @views @. J.JWRhoV[1,2:nz,iC] = -Dp[1:nz-1]
      @views @. J.JWRhoV[2,:,iC] = Dm
    end  

    @views @. D[1:nz-1] = 0.5 * Global.Phys.Grav 
    @views @. J.JWRho[1,2:nz,iC] = -D[1:nz-1] 
    @views @. J.JWRho[2,1:nz,iC] = -D 

    @views @. D[1:nz-1] = -(Th[1:nz-1] / Rho[1:nz-1] * dz[1:nz-1] + Th[2:nz] / Rho[2:nz] * dz[2:nz]) /
      (dz[1:nz-1] + dz[2:nz])
    @views @. J.JThW[1,:,iC] = D / dz
    @views @. J.JThW[2,1:nz-1,iC] = -D[1:nz-1] / dz[2:nz]
    if Global.Model.Thermo == "TotalEnergy" 
      @views @. D[1:nz-1] -= 0.5*(Pres[1:nz-1] + Pres[2:nz]) 
    elseif Global.Model.Thermo == "InternalEnergy"
      @views @. D = Pres / dz
      @views @. J.JThW[1,:,iC] = J.JThW[1,:,iC] - D
      @views @. J.JThW[2,1:nz-1,iC] = J.JThW[2,1:nz-1,iC] + D[2:nz]
    end  

    @inbounds for iT = 1 : NumTr
      @views @. D[1:nz-1] = -(Tr[1:nz-1,iT] / Rho[1:nz-1] * dz[1:nz-1] + Tr[2:nz,iT] / Rho[2:nz] * dz[2:nz]) /
        (dz[1:nz-1] + dz[2:nz])
      @views @. J.JTrW[1,:,iC,iT] = D / dz
      @views @. J.JTrW[2,1:nz-1,iC,iT] = -D[1:nz-1] / dz[2:nz]
    end    

    if Global.Model.Damping
      @views DampingKoeff!(J.JWW[1,:,iC],CG,Global)
    end
    if Global.Model.VerticalDiffusion
      @show "JDiff"  
      @views JDiff = J.JDiff[:,:,iC]
      @views KV = Global.Cache.AuxG[:,iC,2]
      # The Rho factor is already included in KV
      @views @. DF = - (KV[1:nz-1] + KV[2:nz]) / (dz[1:nz-1] + dz[2:nz])
      # J tridiagonal matrix
      # First row upper diagonal
      # Second row diagonal
      # Third row lower diagonal
      @views @. JDiff[1,1:nz-1] = DF / Rho[2:nz] / dz[1:nz-1]
      @views @. JDiff[3,2:nz] = DF / Rho[1:nz-1] / dz[2:nz]
      @views @. JDiff[2,:] = JDiff[1,:] + JDiff[3,:]
    end    
  end
end
