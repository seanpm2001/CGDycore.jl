using CGDycore
using MPI
using Base
using CUDA
using KernelAbstractions
using StaticArrays

# Model
parsed_args = CGDycore.parse_commandline()
Problem = parsed_args["Problem"]
ProfRho = parsed_args["ProfRho"]
ProfTheta = parsed_args["ProfTheta"]
PertTh = parsed_args["PertTh"]
ProfVel = parsed_args["ProfVel"]
ProfpBGrd = parsed_args["ProfpBGrd"]
ProfRhoBGrd = parsed_args["ProfRhoBGrd"]
HorLimit = parsed_args["HorLimit"]
Upwind = parsed_args["Upwind"]
Damping = parsed_args["Damping"]
Relax = parsed_args["Relax"]
StrideDamp = parsed_args["StrideDamp"]
NumV = parsed_args["NumV"]
NumTr = parsed_args["NumTr"]
BoundaryWE = parsed_args["BoundaryWE"]
BoundarySN = parsed_args["BoundarySN"]
BoundaryBT = parsed_args["BoundaryBT"]
Thermo = parsed_args["Thermo"]
RefProfile = parsed_args["RefProfile"]
Profile = parsed_args["Profile"]
Curl = parsed_args["Curl"]
ModelType = parsed_args["ModelType"]
Equation = parsed_args["Equation"]
Microphysics = parsed_args["Microphysics"]
RelCloud = parsed_args["RelCloud"]
Rain = parsed_args["Rain"]
#Orography
TopoS = parsed_args["TopoS"]
P1 = parsed_args["P1"]
P2 = parsed_args["P2"]
P3 = parsed_args["P3"]
P4 = parsed_args["P4"]

# Parallel
Decomp = parsed_args["Decomp"]
SimDays = parsed_args["SimDays"]
SimHours = parsed_args["SimHours"]
SimMinutes = parsed_args["SimMinutes"]
SimSeconds = parsed_args["SimSeconds"]
SimTime = parsed_args["SimTime"]
dtau = parsed_args["dtau"]
IntMethod = parsed_args["IntMethod"]
Table = parsed_args["Table"]
GridType = parsed_args["GridType"]
Coriolis = parsed_args["Coriolis"]
CoriolisType = parsed_args["CoriolisType"]
Source = parsed_args["Source"]
VerticalDiffusion = parsed_args["VerticalDiffusion"]
JacVerticalDiffusion = parsed_args["JacVerticalDiffusion"]
JacVerticalAdvection = parsed_args["JacVerticalAdvection"]
VerticalDiffusionMom = parsed_args["VerticalDiffusionMom"]
SurfaceFlux = parsed_args["SurfaceFlux"]
SurfaceFluxMom = parsed_args["SurfaceFluxMom"]
# Grid
nx = parsed_args["nx"]
ny = parsed_args["ny"]
nz = parsed_args["nz"]
H = parsed_args["H"]
Stretch = parsed_args["Stretch"]
StretchType = parsed_args["StretchType"]
OrdPoly = parsed_args["OrdPoly"]
Lx = parsed_args["Lx"]
Ly = parsed_args["Ly"]
x0 = parsed_args["x0"]
y0 = parsed_args["y0"]
# Viscosity
HyperVisc = parsed_args["HyperVisc"]
HyperDCurl = parsed_args["HyperDCurl"]
HyperDGrad = parsed_args["HyperDGrad"]
HyperDDiv = parsed_args["HyperDDiv"]
# Output
PrintDays = parsed_args["PrintDays"]
PrintHours = parsed_args["PrintHours"]
PrintMinutes = parsed_args["PrintMinutes"]
PrintSeconds = parsed_args["PrintSeconds"]
PrintTime = parsed_args["PrintTime"]
PrintStartTime = parsed_args["PrintStartTime"]
# Device
Device = parsed_args["Device"]
GPUType = parsed_args["GPUType"]
FloatTypeBackend = parsed_args["FloatTypeBackend"]
Param = CGDycore.Parameters(Problem)


if Device == "CPU"
  backend = CPU()
elseif Device == "GPU"
  if GPUType == "CUDA"
    backend = CUDABackend()
    CUDA.allowscalar(true)
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

KernelAbstractions.synchronize(backend)

MPI.Init()

OrdPolyZ=1
Parallel = true

# Physical parameters
Phys=CGDycore.PhysParameters{FTB}()

#ModelParameters
Model = CGDycore.Model()
# Initial conditions
Model.Equation = Equation
Model.NumV=NumV
Model.NumTr=NumTr
Model.Problem=Problem
if ProfRho == ""
  Model.ProfRho = Problem
else
  Model.ProfRho = ProfRho  
end  
if ProfTheta == ""
  Model.ProfTheta = Problem
else
  Model.ProfTheta = ProfTheta  
end  
Model.PertTh = PertTh
if ProfVel == ""
  Model.ProfVel = Problem
else
  Model.ProfVel = ProfVel  
end  
Model.ProfpBGrd = ProfpBGrd
Model.ProfRhoBGrd = ProfRhoBGrd
Model.RefProfile = RefProfile
Model.Profile = Profile
Model.RhoPos=1
Model.uPos=2
Model.vPos=3
Model.wPos=4
Model.ThPos=5
if Model.Equation == "CompressibleMoist"
  Model.RhoVPos = 1
  Model.RhoCPos = 2
end
Model.HorLimit = HorLimit
Model.Upwind = Upwind
Model.Damping = Damping
Model.StrideDamp = StrideDamp
Model.Relax = Relax
Model.Coriolis = Coriolis
Model.CoriolisType = CoriolisType
Model.VerticalDiffusion = VerticalDiffusion
Model.JacVerticalDiffusion = JacVerticalDiffusion
Model.JacVerticalAdvection = JacVerticalAdvection
Model.VerticalDiffusionMom = VerticalDiffusionMom
Model.Source = Source
Model.Microphysics = Microphysics
Model.RelCloud = RelCloud
Model.Rain = Rain
Model.Source = Source
Model.SurfaceFlux = SurfaceFlux
Model.SurfaceFluxMom = SurfaceFluxMom
Model.Thermo = Thermo
Model.Curl = Curl
Model.Stretch = Stretch
Model.StretchType = StretchType
Model.ModelType = ModelType
Model.HyperVisc = HyperVisc
Model.HyperDCurl = HyperDCurl # =7.e15
Model.HyperDGrad = HyperDGrad # =7.e15
Model.HyperDDiv = HyperDDiv # =7.e15




Boundary = CGDycore.Boundary()
Boundary.WE = BoundaryWE
Boundary.SN = BoundarySN
Boundary.BT = BoundaryBT
Topography=(TopoS=TopoS,
            H=H,
            P1=P1,
            P2=P2,
            P3=P3,
            P4=P4,
            )

(CG, Metric, Global) = CGDycore.InitCart(backend,FTB,OrdPoly,OrdPolyZ,nx,ny,Lx,Ly,x0,y0,nz,H,
  Boundary,GridType,Topography,Decomp,Model,Phys)

Profile = CGDycore.WarmBubbleCartExample()(Param,Phys)
# Initial values
if Problem == "Stratified" || Problem == "HillAgnesiXCart"
  Profile = CGDycore.StratifiedExample()(Param,Phys)
elseif Problem == "WarmBubble"
  Profile = CGDycore.WarmBubbleCartExample()(Param,Phys)
end

U = CGDycore.InitialConditions(backend,FTB,CG,Metric,Phys,Global,Profile,Param)

# Output
Global.Output.vtkFileName=string(Problem*"_")
Global.Output.vtk=0
Global.Output.Flat=true
Global.Output.H=H
if ModelType == "VectorInvariant" || ModelType == "Advection"
  if Model.Equation == "Compressible"
    Global.Output.cNames = [
      "Rho",
      "u",
      "v",
      "wB",
      "Th",
      "Pres",
      ]
  elseif Model.Equation == "CompressibleMoist"
    Global.Output.cNames = [
      "Rho",
      "u",
      "v",
      "wB",
      "Th",
      "ThE",
      "Pres",
      "Tr1",
      "Tr2",
      ]
  end    
elseif ModelType == "Conservative"
  Global.Output.cNames = [
    "Rho",
    "Rhou",
    "Rhov",
    "w",
    "Th",
    "Vort",
    ]
end

Global.Output.PrintDays = PrintDays
Global.Output.PrintHours = PrintHours
Global.Output.PrintMinutes = PrintMinutes
Global.Output.PrintSeconds = PrintSeconds
Global.Output.PrintTime = PrintTime
Global.Output.PrintStartTime = PrintStartTime
Global.Output.OrdPrint=CG.OrdPoly
Global.vtkCache = CGDycore.vtkStruct{FTB}(backend,Global.Output.OrdPrint,CGDycore.TransCartX!,CG,Metric,Global)


# TimeStepper
time=[0.0]
Global.TimeStepper.IntMethod = IntMethod
Global.TimeStepper.Table = Table
Global.TimeStepper.dtau = dtau
Global.TimeStepper.SimDays = SimDays
Global.TimeStepper.SimHours = SimHours
Global.TimeStepper.SimMinutes = SimMinutes
Global.TimeStepper.SimSeconds = SimSeconds
Global.TimeStepper.SimTime = SimTime
if ModelType == "VectorInvariant" || ModelType == "Advection"
  DiscType = Val(:VectorInvariant)
elseif ModelType == "Conservative"
  DiscType = Val(:Conservative)
end
if Device == "CPU"  || Device == "GPU"
  nT = max(9 + NumTr, NumV + NumTr)
  CGDycore.TimeStepper!(U,CGDycore.FcnGPU!,CGDycore.FcnPrepareGPU!,CGDycore.JacSchurGPU!,CGDycore.TransCartX,
    CG,Metric,Phys,Global,Param,DiscType)
else    
  nT = max(9 + NumTr, NumV + NumTr)
  CGDycore.InitExchangeData3D(nz,nT,Global.Exchange)
  CGDycore.TimeStepper!(U,CGDycore.Fcn!,CGDycore.FcnPrepare!,CGDycore.JacSchur!,
    CGDycore.TransCartX,CG,Metric,Phys,Global,Param,DiscType)
end    
