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

Problem = "LinearBlob"
Param = Examples.Parameters(FTB,Problem)
Examples.InitialProfile!(Model,Problem,Param,Phys)

RefineLevel = 5
RadEarth = 1.0
nz = 1
nPanel = 40
nQuad = 2
Decomp = ""
Decomp = "EqualArea"

#TRI
GridType = "DelaunaySphere"
GridType = "CubedSphere"
Grid, Exchange = Grids.InitGridSphere(backend,FTB,OrdPoly,nz,nPanel,RefineLevel,GridType,Decomp,RadEarth,
  Model,ParallelCom;order=false)
vtkSkeletonMesh = Outputs.vtkStruct{Float64}(backend,Grid)

#MetricFV = FiniteVolumes.MetricFiniteVolume(backend,FTB,Grid,Grid.Type)


#Div = FiniteVolumes.Divergence(backend,FTB,MetricFV,Grid)
#GradFV = FiniteVolumes.Gradient(backend,FTB,MetricFV,Grid)
Grad = FiniteVolumes.GradMPFA(backend,FTB,Grid)
Div = FiniteVolumes.DivMPFA(backend,FTB,Grid)


pPosS = 1
pPosE = Grid.NumFaces
uPosS = pPosE + 1
uPosE = pPosE + Grid.NumEdges
U = zeros(FTB,Grid.NumEdges+Grid.NumFaces)
r = similar(U)
UNew = similar(U)
@views rp = r[pPosS:pPosE]
@views ru = r[uPosS:uPosE]
@views Up = U[pPosS:pPosE]
@views Uu = U[uPosS:uPosE]
@views UNewp = UNew[pPosS:pPosE]
@views UNewu = UNew[uPosS:uPosE]

FiniteVolumes.ProjectFace!(backend,FTB,Up,Grid,Model.InitialProfile)
FileNumber = 0
VelCa = zeros(Grid.NumFaces,Grid.Dim)
VelSp = zeros(Grid.NumFaces,2)
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType*"FV", Proc, ProcNumber, [Up VelCa VelSp], FileNumber)
pNeu = zeros(FTB,Grid.NumFaces)

nAdveVel = 1000
dtau = 0.001
time = 0.0



for i = 1 : nAdveVel
  mul!(rp,Div,Uu)
  mul!(ru,Grad,Up)
  @. ru = -ru
  @. UNew = U + 0.5 * dtau * r  

  mul!(rp,Div,UNewu)
  mul!(ru,Grad,UNewp)
  @. ru = -ru
  @. U = U + dtau * r  


  #time = time + dtau
end


FileNumber += 1
Outputs.vtkSkeleton!(vtkSkeletonMesh, GridType*"FV", Proc, ProcNumber, [Up VelCa VelSp], FileNumber)


#= ToDO
Gleichungen testen mit @show
mehr Quadraturregeln für Dreiecke höhere ordnungen
RT1, DG1
Wiki von github
=#
