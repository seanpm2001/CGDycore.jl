import CGDycore:
  DG, Examples, Parallels, Models, Grids, Outputs, Integration, GPU, DyCore, Seifert
using MPI
using Base
using CUDA
using AMDGPU
using Metal
using KernelAbstractions
using StaticArrays
using ArgParse

# Model
parsed_args = DyCore.parse_commandline()
Problem = parsed_args["Problem"]
ProfRho = parsed_args["ProfRho"]
ProfTheta = parsed_args["ProfTheta"]
PertTh = parsed_args["PertTh"]
ProfVel = parsed_args["ProfVel"]
ProfVelGeo = parsed_args["ProfVelGeo"]
RhoVPos = parsed_args["RhoVPos"]
RhoCPos = parsed_args["RhoCPos"]
RhoIPos = parsed_args["RhoIPos"]
RhoRPos = parsed_args["RhoRPos"]
HorLimit = parsed_args["HorLimit"]
Upwind = parsed_args["Upwind"]
Damping = parsed_args["Damping"]
Relax = parsed_args["Relax"]
StrideDamp = parsed_args["StrideDamp"]
Geos = parsed_args["Geos"]
Coriolis = parsed_args["Coriolis"]
CoriolisType = parsed_args["CoriolisType"]
Buoyancy = parsed_args["Buoyancy"]
Equation = parsed_args["Equation"]
RefProfile = parsed_args["RefProfile"]
ProfpBGrd = parsed_args["ProfpBGrd"]
ProfRhoBGrd = parsed_args["ProfRhoBGrd"]
Microphysics = parsed_args["Microphysics"]
TypeMicrophysics = parsed_args["TypeMicrophysics"]
RelCloud = parsed_args["RelCloud"]
Rain = parsed_args["Rain"]
Source = parsed_args["Source"]
Forcing = parsed_args["Forcing"]
VerticalDiffusion = parsed_args["VerticalDiffusion"]
JacVerticalDiffusion = parsed_args["JacVerticalDiffusion"]
JacVerticalAdvection = parsed_args["JacVerticalAdvection"]
SurfaceFlux = parsed_args["SurfaceFlux"]
SurfaceFluxMom = parsed_args["SurfaceFluxMom"]
NumV = parsed_args["NumV"]
NumTr = parsed_args["NumTr"]
Curl = parsed_args["Curl"]
ModelType = parsed_args["ModelType"]
Thermo = parsed_args["Thermo"]
# Parallel
Decomp = parsed_args["Decomp"]
# Time integration
SimDays = parsed_args["SimDays"]
SimHours = parsed_args["SimHours"]
SimMinutes = parsed_args["SimMinutes"]
SimSeconds = parsed_args["SimSeconds"]
StartAverageDays = parsed_args["StartAverageDays"]
dtau = parsed_args["dtau"]
IntMethod = parsed_args["IntMethod"]
Table = parsed_args["Table"]
# Grid
nz = parsed_args["nz"]
nPanel = parsed_args["nPanel"]
H = parsed_args["H"]
Stretch = parsed_args["Stretch"]
StretchType = parsed_args["StretchType"]
TopoS = parsed_args["TopoS"]
GridType = parsed_args["GridType"]
RadEarth = parsed_args["RadEarth"]
# CG Element
OrdPoly = parsed_args["OrdPoly"]
# Viscosity
HyperVisc = parsed_args["HyperVisc"]
HyperDCurl = parsed_args["HyperDCurl"]
HyperDGrad = parsed_args["HyperDGrad"]
HyperDRhoDiv = parsed_args["HyperDRhoDiv"]
HyperDDiv = parsed_args["HyperDDiv"]
HyperDDivW = parsed_args["HyperDDivW"]
# Output
PrintDays = parsed_args["PrintDays"]
PrintHours = parsed_args["PrintHours"]
PrintMinutes = parsed_args["PrintMinutes"]
PrintSeconds = parsed_args["PrintSeconds"]
PrintStartTime = parsed_args["PrintStartTime"]
Flat = parsed_args["Flat"]

# Device
Device = parsed_args["Device"]
GPUType = parsed_args["GPUType"]
FloatTypeBackend = parsed_args["FloatTypeBackend"]
NumberThreadGPU = parsed_args["NumberThreadGPU"]

MPI.Init()

Device = "CPU"
FloatTypeBackend = "Float64"

if Device == "CPU" 
  backend = CPU()
elseif Device == "GPU" 
  if GPUType == "CUDA"
    backend = CUDABackend()
    CUDA.allowscalar(true)
#   CUDA.device!(MPI.Comm_rank(MPI.COMM_WORLD))
  elseif GPUType == "AMD"
    backend = ROCBackend()
    AMDGPU.allowscalar(false)
  elseif GPUType == "Metal"
    backend = MetalBackend()
    Metal.allowscalar(true)
  end
else
  backend = CPU()
end

if FloatTypeBackend == "Float64"
  FTB = Float64
elseif FloatTypeBackend == "Float32"
  FTB = Float32
else
  @show "False FloatTypeBackend"
  stop
end

RefineLevel = 3
RadEarth = 1.0
nz = 1
nPanel = 10
nQuad = 3

#TRI
GridTri = Grids.TriangularGrid(backend,FTB,RefineLevel,RadEarth,nz)
RT0Tri = Seifert.RT0Struct{FTB}(GridTri.Type,backend,GridTri)
DG0Tri = Seifert.DG0Struct{FTB}(GridTri.Type,backend,GridTri)
QQ = Seifert.QuadRule{FTB}(GridTri.Type,backend,nQuad)

MuTri = Seifert.MassMatrix(backend,FTB,RT0Tri,GridTri,nQuad,Seifert.Jacobi) 
MpTri = Seifert.MassMatrix(backend,FTB,DG0Tri,GridTri,nQuad,Seifert.Jacobi)


#QUAD
GridQuad = Grids.CubedGrid(backend,FTB,nPanel,Grids.OrientFaceSphere,RadEarth,nz)
RT0Quad = Seifert.RT0Struct{FTB}(GridQuad.Type,backend,GridQuad)
DG0Quad = Seifert.DG0Struct{FTB}(GridQuad.Type,backend,GridQuad)
QQ = Seifert.QuadRule{FTB}(GridQuad.Type,backend,nQuad)
MuQuad = Seifert.MassMatrix(backend,FTB,RT0Quad,GridQuad,nQuad,Seifert.Jacobi)
MpQuad = Seifert.MassMatrix(backend,FTB,DG0Quad,GridQuad,nQuad,Seifert.Jacobi) 


#=for iF=1:1
  for i=1:QQ.NumQuad
    J = Seifert.Jacobi(GridQuad.Type,QQ.Points[i,1],QQ.Points[i,2],GridQuad.Faces[iF],GridQuad)
  end
end
=#


#GridTri = Grids.TriangularGrid(backend,FTB,RefineLevel,RadEarth,nz)
#RT0Tri = Seifert.RT0Struct{FTB}(GridTri.Type,backend,GridTri)
#fRef = Seifert.MassMatrixVec(backend,FTB,RT0Quad,Grid,nQuad,Seifert.JacobiTri)

#nFeGlob = Seifert.MassMatrixVec(backend,FTB,RT0Quad,Grid,nQuad,Seifert.JacobiTri)
#MLoc = Seifert.MassMatrixVec(backend,FTB,RT0Quad,Grid,nQuad,Seifert.JacobiTri)