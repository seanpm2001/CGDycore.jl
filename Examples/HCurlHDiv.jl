import CGDycore:
  Examples, Parallels, Models, Grids, Outputs, Integration,  GPU, DyCore, FEMSei, FiniteVolumes
using MPI
using Base
using CUDA
using AMDGPU
using Metal
using KernelAbstractions
using StaticArrays
using ArgParse
using LinearAlgebra

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

MPI.Init()
comm = MPI.COMM_WORLD
Proc = MPI.Comm_rank(comm) + 1
ProcNumber = MPI.Comm_size(comm)
ParallelCom = DyCore.ParallelComStruct()
ParallelCom.Proc = Proc
ParallelCom.ProcNumber  = ProcNumber

# Physical parameters
Phys = DyCore.PhysParameters{FTB}()

#ModelParameters
Model = DyCore.ModelStruct{FTB}()

RefineLevel = 4
nz = 1
nPanel = 60
nQuad = 3
Decomp = ""
Decomp = "EqualArea"
Problem = "GalewskiSphere"
RadEarth = Phys.RadEarth
#Problem = "LinearBlob"
#RadEarth = 1.0
Param = Examples.Parameters(FTB,Problem)
Examples.InitialProfile!(Model,Problem,Param,Phys)

#TRI
GridType = "CubedSphere"
#GridType = "TriangularSphere" # Achtung Orientierung
Grid, Exchange = Grids.InitGridSphere(backend,FTB,OrdPoly,nz,nPanel,RefineLevel,GridType,Decomp,RadEarth,
  Model,ParallelCom;order=false)
vtkSkeletonMesh = Outputs.vtkStruct{Float64}(backend,Grid)
p = ones(Grid.NumFaces,1)
for i = 1 : Grid.NumFaces
  p[i] = i
end  
global FileNumber = 0
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType, Proc, ProcNumber, p, FileNumber)


DG0 = FEMSei.DG0Struct{FTB}(Grids.Quad(),backend,Grid)
DG0.M = FEMSei.MassMatrix(backend,FTB,DG0,Grid,nQuad,FEMSei.Jacobi!)
FpM = lu(DG0.M)

RT = FEMSei.RT0Struct{FTB}(Grids.Quad(),backend,Grid)
RT.M = FEMSei.MassMatrix(backend,FTB,RT,Grid,nQuad,FEMSei.Jacobi!)
FuM = lu(RT.M)
Div = FEMSei.DivMatrix(backend,FTB,RT,DG0,Grid,nQuad,FEMSei.Jacobi!)

ND = FEMSei.Nedelec0Struct{FTB}(Grids.Quad(),backend,Grid)
ND.M = FEMSei.MassMatrix(backend,FTB,ND,Grid,nQuad,FEMSei.Jacobi!)
Curl = FEMSei.CurlMatrix(backend,FTB,ND,DG0,Grid,nQuad,FEMSei.Jacobi!)

pPosS = 1
pPosE = DG0.NumG
uPosS = DG0.NumG + 1
uPosE = DG0.NumG + RT.NumG
UDiv = zeros(FTB,DG0.NumG+RT.NumG)
qDiv = zeros(FTB,DG0.NumG)
UCurl = zeros(FTB,DG0.NumG+RT.NumG)
qCurl = zeros(FTB,DG0.NumG)

pM = zeros(Grid.NumFaces)
VelCa = zeros(Grid.NumFaces,Grid.Dim)
VelSp = zeros(Grid.NumFaces,2)

@views FEMSei.Project!(backend,FTB,UDiv[uPosS:uPosE],RT,Grid,nQuad,
  FEMSei.Jacobi!,Model.InitialProfile)
@views FEMSei.Project!(backend,FTB,UDiv[pPosS:pPosE],DG0,Grid,nQuad,
  FEMSei.Jacobi!,Model.InitialProfile)
@views pM = FEMSei.ComputeScalar(backend,FTB,DG0,Grid,UDiv[pPosS:pPosE])
@views FEMSei.ConvertVelocityCart!(backend,FTB,VelCa,UDiv[uPosS:uPosE],RT,Grid,FEMSei.Jacobi!)
@views FEMSei.ConvertVelocitySp!(backend,FTB,VelSp,UDiv[uPosS:uPosE],RT,Grid,FEMSei.Jacobi!)
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType, Proc, ProcNumber, [pM VelCa VelSp], FileNumber)
FileNumber += 1




@views FEMSei.Project!(backend,FTB,UCurl[uPosS:uPosE],ND,Grid,nQuad,
  FEMSei.Jacobi!,Model.InitialProfile)
@views FEMSei.ConvertVelocityCart!(backend,FTB,VelCa,UCurl[uPosS:uPosE],ND,Grid,FEMSei.Jacobi!)
@views FEMSei.ConvertVelocitySp!(backend,FTB,VelSp,UCurl[uPosS:uPosE],ND,Grid,FEMSei.Jacobi!)
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType, Proc, ProcNumber, [pM VelCa VelSp], FileNumber)
FileNumber += 1


#Curl Matrix
Curl = FEMSei.CurlMatrix(backend,FTB,ND,DG0,Grid,nQuad,FEMSei.Jacobi!)
mul!(qCurl,Curl,UCurl[uPosS:uPosE])
ldiv!(FpM,qCurl)
pMCurl = FEMSei.ComputeScalar(backend,FTB,DG0,Grid,qCurl)
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType, Proc, ProcNumber, [pMCurl VelCa VelSp], FileNumber)
FileNumber += 1

#Projection HDiv HCurl
@views FEMSei.ProjectHDivHCurl!(backend,FTB,UCurl[uPosS:uPosE],ND,UDiv[uPosS:uPosE],RT,
  Grid,Grids.Quad(),nQuad,FEMSei.Jacobi!)
mul!(qCurl,Curl,UCurl[uPosS:uPosE])
ldiv!(FpM,qCurl)
pMCurl = FEMSei.ComputeScalar(backend,FTB,DG0,Grid,qCurl)
@show FileNumber
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType, Proc, ProcNumber, [pMCurl VelCa VelSp], FileNumber)
FileNumber += 1


#=
F = similar(UDiv)
# Test Gradient
@views FEMSei.Project!(backend,FTB,UDiv[pPosS:pPosE],DG0,Grid,nQuad,
  FEMSei.Jacobi!,Model.InitialProfile)
@. F = 0
@views FEMSei.GradKinHeight!(backend,FTB,F[uPosS:uPosE],UDiv[pPosS:pPosE],DG0,
  UDiv[uPosS:uPosE],RT,RT,Grid,Grids.Quad(),nQuad,FEMSei.Jacobi!)
@views ldiv!(FuM,F[uPosS:uPosE])
@views pM = FEMSei.ComputeScalar(backend,FTB,DG0,Grid,UDiv[pPosS:pPosE])
@views FEMSei.ConvertVelocityCart!(backend,FTB,VelCa,F[uPosS:uPosE],RT,Grid,FEMSei.Jacobi!)
@views FEMSei.ConvertVelocitySp!(backend,FTB,VelSp,F[uPosS:uPosE],RT,Grid,FEMSei.Jacobi!)
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType, Proc, ProcNumber, [pM VelCa VelSp], FileNumber)
FileNumber += 1

@views FEMSei.Project!(backend,FTB,UDiv[pPosS:pPosE],DG0,Grid,nQuad,
  FEMSei.Jacobi!,Model.InitialProfile)
@views mul!(F[uPosS:uPosE],Div',UDiv[pPosS:pPosE])
@views ldiv!(FuM,F[uPosS:uPosE])
@views pM = FEMSei.ComputeScalar(backend,FTB,DG0,Grid,F[pPosS:pPosE])
@views FEMSei.ConvertVelocityCart!(backend,FTB,VelCa,F[uPosS:uPosE],RT,Grid,FEMSei.Jacobi!)
@views FEMSei.ConvertVelocitySp!(backend,FTB,VelSp,UDiv[uPosS:uPosE],RT,Grid,FEMSei.Jacobi!)
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType, Proc, ProcNumber, [pM VelCa VelSp], FileNumber)
FileNumber += 1


#Test Divergenz
@views FEMSei.Project!(backend,FTB,UDiv[uPosS:uPosE],RT,Grid,nQuad,
  FEMSei.Jacobi!,Model.InitialProfile)
@. F = 0
@views @. UDiv[pPosS:pPosE] = 1
@views FEMSei.DivHeight!(backend,FTB,F[pPosS:uPosE],UDiv[pPosS:pPosE],DG0,
  UDiv[uPosS:uPosE],RT,DG0,Grid,nQuad,FEMSei.Jacobi!)
@views ldiv!(FpM,F[pPosS:pPosE])
@views pM = FEMSei.ComputeScalar(backend,FTB,DG0,Grid,F[pPosS:pPosE])
@views FEMSei.ConvertVelocityCart!(backend,FTB,VelCa,UDiv[uPosS:uPosE],RT,Grid,FEMSei.Jacobi!)
@views FEMSei.ConvertVelocitySp!(backend,FTB,VelSp,UDiv[uPosS:uPosE],RT,Grid,FEMSei.Jacobi!)
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType, Proc, ProcNumber, [pM VelCa VelSp], FileNumber)
FileNumber += 1

@views FEMSei.Project!(backend,FTB,UDiv[uPosS:uPosE],RT,Grid,nQuad,
  FEMSei.Jacobi!,Model.InitialProfile)
@. F = 0
@views @. UDiv[pPosS:pPosE] = 1
@views mul!(F[pPosS:pPosE],Div,UDiv[uPosS:uPosE])
@views ldiv!(FpM,F[pPosS:pPosE])
@views pM = FEMSei.ComputeScalar(backend,FTB,DG0,Grid,F[pPosS:pPosE])
@views FEMSei.ConvertVelocityCart!(backend,FTB,VelCa,UDiv[uPosS:uPosE],RT,Grid,FEMSei.Jacobi!)
@views FEMSei.ConvertVelocitySp!(backend,FTB,VelSp,UDiv[uPosS:uPosE],RT,Grid,FEMSei.Jacobi!)
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType, Proc, ProcNumber, [pM VelCa VelSp], FileNumber)



@views FEMSei.VortCrossVel!(backend,FTB,F[uPosS:uPosE],UDiv[uPosS:uPosE],RT,
  qCurl,DG0,RT,Grid,nQuad,FEMSei.Jacobi!)
@views FEMSei.DivHeight!(backend,FTB,F[pPosS:pPosE],UDiv[uPosS:uPosE],RT,
  UDiv[pPosS:pPosE],DG0,DG0,Grid,nQuad,FEMSei.Jacobi!)

=#





