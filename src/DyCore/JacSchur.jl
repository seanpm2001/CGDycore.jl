mutable struct JStruct
    JRhoW::Array{Float64, 3}
    JWTh::Array{Float64, 3}
    JWRho::Array{Float64, 3}
    JThW::Array{Float64, 3}
    JTrW::Array{Float64, 4}
    JWW::Array{Float64, 3}
    tri::Array{Float64, 3}
    sw::Array{Float64, 2}
    CompTri::Bool
    CacheCol1::Array{Float64, 1}
    CacheCol2::Array{Float64, 1}
    CacheCol3::Array{Float64, 1}
end

function JStruct()
  JRhoW=zeros(0,0,0)
  JWTh=zeros(0,0,0)
  JWRho=zeros(0,0,0)
  JThW=zeros(0,0,0)
  JTrW=zeros(0,0,0,0)
  JWW=zeros(0,0,0)
  tri=zeros(0,0,0)
  sw=zeros(0,0)
  CompTri=false
  CacheCol1=zeros(0)
  CacheCol2=zeros(0)
  CacheCol3=zeros(0)
  return JStruct(
    JRhoW,
    JWTh,
    JWRho,
    JThW,
    JTrW,
    JWW,
    tri,
    sw,
    CompTri,
    CacheCol1,
    CacheCol2,
    CacheCol3,
  )
end  

function JStruct(NumG,nz,NumTr)
  JRhoW=zeros(2,nz,NumG)
  JWTh=zeros(2,nz,NumG)
  JWRho=zeros(2,nz,NumG)
  JThW=zeros(2,nz,NumG)
  JTrW=zeros(2,nz,NumG,NumTr)
  JWW=zeros(1,nz,NumG)
  tri=zeros(3,nz,NumG)
  sw=zeros(nz,NumG)
  CompTri=false
  CacheCol1=zeros(nz)
  CacheCol2=zeros(nz)
  CacheCol3=zeros(nz)
  return JStruct(
    JRhoW,
    JWTh,
    JWRho,
    JThW,
    JTrW,
    JWW,
    tri,
    sw,
    CompTri,
    CacheCol1,
    CacheCol2,
    CacheCol3,
  )
end

function JacSchur!(J,U,CG,Global)
  (;  RhoPos,
      uPos,
      vPos,
      wPos,
      ThPos,
      NumV) = Global.Model
  nz=Global.Grid.nz;
  NF=Global.Grid.NumFaces
  dz=Global.Grid.dz;
  nCol=size(U,2);
  nJ=nCol*nz;

  Pres = J.CacheCol1
  D = J.CacheCol2
  Dp = J.CacheCol2
  Dm = J.CacheCol3
  dPdTh = J.CacheCol1
  K = J.CacheCol1

  @inbounds for iC=1:nCol
    @views Rho = U[:,iC,RhoPos]
    @views Th = U[:,iC,ThPos]
    @views Tr = U[:,iC,NumV+1:end]

    @views @. D[1:nz-1] = -0.5*(Rho[1:nz-1] + Rho[2:nz]) / dz;
    @views @. J.JRhoW[1,:,iC] = D
    @views @. J.JRhoW[2,1:nz-1,iC] = -D[1:nz-1]

    dPresdTh!(dPdTh, Th, Global);
    @views @. Dp[1:nz-1] = dPdTh[2:nz] /  (0.5*(Rho[1:nz-1] + Rho[2:nz])) / dz;
    @views @. Dm[1:nz-1] = dPdTh[1:nz-1] / (0.5*(Rho[1:nz-1] + Rho[2:nz])) / dz;
    @views @. J.JWTh[1,2:nz,iC] = -Dp[1:nz-1]
    @views @. J.JWTh[2,:,iC] = Dm

    @views Pressure!(Pres,Th, Rho, Tr, Global);
    @views @. D[1:nz-1] = 0.5*(Pres[2:nz] - Pres[1:nz-1]) / dz  /
      (0.5*(Rho[1:nz-1] + Rho[2:nz]))^2;
    @views @. J.JWRho[1,2:nz,iC] = D[1:nz-1] 
    @views @. J.JWRho[2,1:nz,iC] = D 

    @views @. D[1:nz-1] = -0.5*(Th[1:nz-1] + Th[2:nz]) / dz;
    @views @. J.JThW[1,:,iC] = D
    @views @. J.JThW[2,1:nz-1,iC] = -D[1:nz-1]

    if Global.Model.Damping
      @views DampingKoeff!(J.JWW[1,:,iC],CG,Global)
    end
  end
end

