mutable struct CacheStruct
CacheE1::Array{Float64, 2}
CacheE2::Array{Float64, 2}
CacheE3::Array{Float64, 2}
CacheE4::Array{Float64, 2}
CacheE5::Array{Float64, 2}
CacheF1::Array{Float64, 3}
CacheF2::Array{Float64, 3}
CacheF3::Array{Float64, 3}
CacheF4::Array{Float64, 3}
CacheF5::Array{Float64, 3}
CacheF6::Array{Float64, 3}
CacheC1::Array{Float64, 3}
CacheC2::Array{Float64, 3}
CacheC3::Array{Float64, 3}
CacheC4::Array{Float64, 3}
CacheC5::Array{Float64, 3}
CacheC6::Array{Float64, 3}
Cache1::Array{Float64, 2}
Cache2::Array{Float64, 2}
Cache3::Array{Float64, 2}
Cache4::Array{Float64, 2}
Pres::Array{Float64, 3}
KE::Array{Float64, 3}
FCG::Array{Float64, 4}
Vn::Array{Float64, 3}
RhoCG::Array{Float64, 3}
v1CG::Array{Float64, 3}
v2CG::Array{Float64, 3}
wCG::Array{Float64, 3}
wCCG::Array{Float64, 3}
ThCG::Array{Float64, 3}
Rot1CG::Array{Float64, 3}
Rot2CG::Array{Float64, 3}
Grad1CG::Array{Float64, 3}
Grad2CG::Array{Float64, 3}
DivCG::Array{Float64, 3}
Rot1::Array{Float64, 2}
Rot2::Array{Float64, 2}
Grad1::Array{Float64, 2}
Grad2::Array{Float64, 2}
Div::Array{Float64, 2}
k::Array{Float64, 4}
fV::Array{Float64, 3}
f::Array{Float64, 4}
end
function CacheStruct()
CacheE1=zeros(0,0);
CacheE2=zeros(0,0);
CacheE3=zeros(0,0);
CacheE4=zeros(0,0);
CacheE5=zeros(0,0);
CacheF1=zeros(0,0,0);
CacheF2=zeros(0,0,0);
CacheF3=zeros(0,0,0);
CacheF4=zeros(0,0,0);
CacheF5=zeros(0,0,0);
CacheF6=zeros(0,0,0);
CacheC1 = view(CacheF1,:,:,:)
CacheC2 = view(CacheF2,:,:,:)
CacheC3 = view(CacheF3,:,:,:)
CacheC4 = view(CacheF4,:,:,:)
CacheC5 = view(CacheF5,:,:,:)
CacheC6 = view(CacheF6,:,:,:)
Cache1=zeros(0,0)
Cache2=zeros(0,0)
Cache3=zeros(0,0)
Cache4=zeros(0,0)
Pres=zeros(0,0,0)
KE=zeros(0,0,0)
FCG=zeros(0,0,0,0)
Vn=zeros(0,0,0)
RhoCG=zeros(0,0,0)
v1CG=zeros(0,0,0)
v2CG=zeros(0,0,0)
wCG=zeros(0,0,0)
wCCG=zeros(0,0,0)
ThCG=zeros(0,0,0)
Rot1CG=zeros(0,0,0)
Rot2CG=zeros(0,0,0)
Grad1CG=zeros(0,0,0)
Grad2CG=zeros(0,0,0)
DivCG=zeros(0,0,0)
Rot1=zeros(0,0)
Rot2=zeros(0,0)
Grad1=zeros(0,0)
Grad2=zeros(0,0)
Div=zeros(0,0)
k=zeros(0,0,0,0)
fV=zeros(0,0,0)
f=zeros(0,0,0,0)
return CacheStruct(
  CacheE1,
  CacheE2,
  CacheE3,
  CacheE4,
  CacheE5,
  CacheF1,
  CacheF2,
  CacheF3,
  CacheF4,
  CacheF5,
  CacheF6,
  CacheC1,
  CacheC2,
  CacheC3,
  CacheC4,
  CacheC5,
  CacheC6,
  Cache1,
  Cache2,
  Cache3,
  Cache4,
  Pres,
  KE,
  FCG,
  Vn,
  RhoCG,
  v1CG,
  v2CG,
  wCG,
  wCCG,
  ThCG,
  Rot1CG,
  Rot2CG,
  Grad1CG,
  Grad2CG,
  DivCG,
  Rot1,
  Rot2,
  Grad1,
  Grad2,
  Div,
  k,
  fV,
  f,
)
end

function CacheCreate(OP,NF,NumG,nz,NumV)
CacheE1=zeros(OP,OP);
CacheE2=zeros(OP,OP);
CacheE3=zeros(OP,OP);
CacheE4=zeros(OP,OP);
CacheE5=zeros(OP,OP);
CacheF1=zeros(OP,OP,nz+1);
CacheF2=zeros(OP,OP,nz+1);
CacheF3=zeros(OP,OP,nz+1);
CacheF4=zeros(OP,OP,nz+1);
CacheF5=zeros(OP,OP,nz+1);
CacheF6=zeros(OP,OP,nz+1);
CacheC1 = view(CacheF1,:,:,1:nz)
CacheC2 = view(CacheF2,:,:,1:nz)
CacheC3 = view(CacheF3,:,:,1:nz)
CacheC4 = view(CacheF4,:,:,1:nz)
CacheC5 = view(CacheF5,:,:,1:nz)
CacheC6 = view(CacheF6,:,:,1:nz)
Cache1=zeros(nz,NumG)
Cache2=zeros(nz,NumG)
Cache3=zeros(nz,NumG)
Cache4=zeros(nz,NumG)
Pres=zeros(OP,OP,nz)
KE=zeros(OP,OP,nz)
FCG=zeros(OP,OP,nz,NumV)
Vn=zeros(nz,NumG,NumV)
RhoCG=zeros(OP,OP,nz)
v1CG=zeros(OP,OP,nz)
v2CG=zeros(OP,OP,nz)
wCG=zeros(OP,OP,nz+1)
wCCG=zeros(OP,OP,nz)
ThCG=zeros(OP,OP,nz)
Rot1CG=zeros(OP,OP,nz)
Rot2CG=zeros(OP,OP,nz)
Grad1CG=zeros(OP,OP,nz)
Grad2CG=zeros(OP,OP,nz)
DivCG=zeros(OP,OP,nz)
Rot1=zeros(nz,NumG)
Rot2=zeros(nz,NumG)
Grad1=zeros(nz,NumG)
Grad2=zeros(nz,NumG)
Div=zeros(nz,NumG)
k=zeros(0,0,0,0)
fV=zeros(0,0,0)
f=zeros(0,0,0,0)
return CacheStruct(
  CacheE1,
  CacheE2,
  CacheE3,
  CacheE4,
  CacheE5,
  CacheF1,
  CacheF2,
  CacheF3,
  CacheF4,
  CacheF5,
  CacheF6,
  CacheC1,
  CacheC2,
  CacheC3,
  CacheC4,
  CacheC5,
  CacheC6,
  Cache1,
  Cache2,
  Cache3,
  Cache4,
  Pres,
  KE,
  FCG,
  Vn,
  RhoCG,
  v1CG,
  v2CG,
  wCG,
  wCCG,
  ThCG,
  Rot1CG,
  Rot2CG,
  Grad1CG,
  Grad2CG,
  DivCG,
  Rot1,
  Rot2,
  Grad1,
  Grad2,
  Div,
  k,
  fV,
  f,
)
end

mutable struct OutputStruct
  vtk::Int
  vtkFileName::String
  Flat::Bool
  cNames::Array{String, 1}
  nPanel::Int
  RadPrint::Float64
  H::Float64
  Topography::NamedTuple
end
function Output(Topography::NamedTuple)
  vtk=0
  vtkFileName=""
  Flat=false
  cNames=[]
  nPanel=1
  RadPrint=1000.0
  H=1000.0
  return OutputStruct(
  vtk,
  vtkFileName,
  Flat,
  cNames,
  nPanel,
  RadPrint,
  H,
  Topography,
  )
end  

mutable struct MetricStruct
  lat::Array{Float64, 3}
  JC::Array{Float64, 4}
  JF::Array{Float64, 4}
  J::Array{Float64, 5}
  X::Array{Float64, 6}
  dXdxIF::Array{Float64, 6}
  dXdxIC::Array{Float64, 6}
end
function MetricStruct()
    lat    = zeros(0,0,0)
    JC     = zeros(0,0,0,0)
    JF     = zeros(0,0,0,0)
    J      = zeros(0,0,0,0,0)
    X      = zeros(0,0,0,0,0,0)
    dXdxIF = zeros(0,0,0,0,0,0)
    dXdxIC = zeros(0,0,0,0,0,0)
    return MetricStruct(
        lat,
        JC,
        JF,
        J,
        X,
        dXdxIF,
        dXdxIC,
    )
end
function Metric(OP,OPZ,NF,nz)
    lat    = zeros(OP,OP,NF)
    JC     = zeros(OP,OP,nz,NF)
    JF     = zeros(OP,OP,nz+1,NF)
    J      = zeros(OP,OP,OPZ,nz,NF)
    X      = zeros(OP,OP,OPZ,3,nz,NF)
    dXdxIF = zeros(OP,OP,nz+1,3,3,NF)
    dXdxIC = zeros(OP,OP,nz,3,3,NF)
    return MetricStruct(
        lat,
        JC,
        JF,
        J,
        X,
        dXdxIF,
        dXdxIC,
    )
end

mutable struct PhysParameters
  RadEarth::Float64 
  Grav::Float64 
  Cpd::Float64
  Cvd::Float64
  Rd::Float64
  p0::Float64
  Gamma::Float64
  kappa::Float64
  Omega::Float64
end
function PhysParameters()
  RadEarth = 6.37122e+6
  Grav = 9.81e0
  Cpd=1004.0e0
  Cvd=717.0e0
  Rd=Cpd-Cvd
  p0=1.0e5
  Gamma=Cpd/Cvd
  kappa=Rd/Cpd
  Omega=2*pi/24.0/3600.0
 return PhysParameters(
  RadEarth,
  Grav,
  Cpd,
  Cvd,
  Rd,
  p0,
  Gamma,
  kappa,
  Omega,
  )
end 

mutable struct ModelStruct
  ProfRho::String
  ProfTheta::String
  ProfVel::String
  RhoPos::Int
  uPos::Int
  vPos::Int
  wPos::Int
  ThPos::Int
  NumV::Int
  Equation::String
  Thermo::String
  ModelType::String
  Source::Bool
  Damping::Bool
  Relax::Float64
  StrideDamp::Float64
  Coriolis::Bool
  CoriolisType::String
  Buoyancy::Bool
  RefProfile::Bool
  HyperVisc::Bool
  HyperDCurl::Float64
  HyperDGrad::Float64
  HyperDDiv::Float64
  Upwind::Bool
  Param::NamedTuple
end
function Model(Param::NamedTuple)
  ProfRho=""
  ProfTheta=""
  ProfVel=""
  RhoPos = 0
  uPos = 0
  vPos = 0
  wPos = 0
  ThPos = 0
  NumV = 0
  Equation="Compressible"
  Thermo=""
  ModelType="Curl"
  Source=false
  Damping=false
  Relax=0.0
  StrideDamp=0.0
  Coriolis=false
  CoriolisType=""
  Buoyancy=true
  RefProfile=false
  HyperVisc=false
  HyperDCurl=0.0
  HyperDGrad=0.0
  HyperDDiv=0.0
  Upwind=false
  return ModelStruct(
   ProfRho,
   ProfTheta,
   ProfVel,
   RhoPos,
   uPos,
   vPos,
   wPos,
   ThPos,
   NumV,
   Equation,
   Thermo,
   ModelType,
   Source,
   Damping,
   Relax,
   StrideDamp,
   Coriolis,
   CoriolisType,
   Buoyancy,
   RefProfile,
   HyperVisc,
   HyperDCurl,
   HyperDGrad,
   HyperDDiv,
   Upwind,
   Param,

   )
end  

mutable struct GlobalStruct
  Metric::MetricStruct
  Grid::GridStruct
  Model::ModelStruct
  Phys::PhysParameters
  Output::OutputStruct
  ROS::RosenbrockStruct
  RK::RungeKuttaStruct
  Cache::CacheStruct
  J::JStruct
  latN::Array{Float64, 1}
end
function Global(Grid::GridStruct,
                Model::ModelStruct,
                Phys::PhysParameters,
                Output::OutputStruct)
  Metric=MetricStruct()
  ROS=RosenbrockMethod()
  RK=RungeKuttaMethod()
  Cache=CacheStruct()
  J=JStruct()
  latN=zeros(0)
  return GlobalStruct(
    Metric,
    Grid,
    Model,
    Phys,
    Output,
    ROS,
    RK,
    Cache,
    J,
    latN,
    )
end  
