#function testNHBaroWaveSphere

using CGDycore

OrdPoly = 4
OrdPolyZ=1
nz = 1
nPanel = 32
NF = 6 * nPanel * nPanel


# Physical parameters
Phys=CGDycore.PhysParameters();

#ModelParameters
lat0G=pi/7.0
lat1G=pi/2.0-lat0G
eN=exp(-4.0/(lat1G-lat0G)^2.0)
Param=(alphaG=1.0/3.0,
       betaG=1.0/15.0,
       hH=120.0,
       H0G=10000.0,
       uM=80.0,
       lat0G=lat0G,
       lat1G=lat1G,
       eN=eN,
       Deep=false,
       Omega=Phys.Omega,
       )

Model = CGDycore.Model(Param)
Model.Coriolis=true
Model.CoriolisType="Sphere";
Model.Equation="Shallow"
Model.Buoyancy=false

# Grid
H = 2.0
Topography=(TopoS="",H=H,Rad=Phys.RadEarth)
Grid=CGDycore.Grid(nz,Topography)
Grid=CGDycore.CubedGrid(nPanel,CGDycore.OrientFaceSphere,Phys.RadEarth,Grid);
CGDycore.AddVerticalGrid!(Grid,nz,H)

Output=CGDycore.Output()

Global = CGDycore.Global(Grid,Model,Phys,Output)
Global.Metric=CGDycore.Metric(OrdPoly+1,OrdPolyZ+1,Grid.NumFaces,nz)


# Discretization
(CG,Global)=CGDycore.Discretization(OrdPoly,OrdPolyZ,CGDycore.JacobiSphere3,Global);
Model.HyperVisc=true;
Model.HyperDCurl=2.e14;
Model.HyperDGrad=2.e14;
Model.HyperDDiv=0;


# Initial conditions 
Model.NumV=5;
U=zeros(nz,CG.NumG,Model.NumV);
Model.ProfRho="Galewsky"
Model.ProfTheta="Galewsky"
Model.ProfVel="Galewsky"
Model.RhoPos=1;
Model.uPos=2;
Model.vPos=3;
Model.wPos=4;
Model.ThPos=5;
U[:,:,Model.RhoPos]=CGDycore.Project(CGDycore.fRho,CG,Global);
(U[:,:,Model.uPos],U[:,:,Model.vPos])=CGDycore.ProjectVec(CGDycore.fVel,CG,Global);
U[:,:,Model.ThPos]=CGDycore.Project(CGDycore.fTheta,CG,Global).*U[:,:,Model.RhoPos];

# Output
Output.vtkFileName="Galewsky";
Output.vtk=0;
Output.Flat=true
Output.nPanel=nPanel
Output.RadPrint=H
Output.H=H
Output.cNames = [
  "Rho",
  "u",
  "v",
  "Th",
  "Vort"
]
vtkGrid=CGDycore.vtkCGGrid(CG,CGDycore.TransSphere,CGDycore.Topo,Global);

#Integration
IntMethod="RungeKutta";
if IntMethod == "Rosenbrock"
  dtau=200;
else
  dtau=100;
end
Global.ROS=CGDycore.RosenbrockMethod("SSP-Knoth");
Global.RK=CGDycore.RungeKuttaMethod("RK4");
time=[0.0];
SimDays=6;
PrintDay=.5;
nIter=24*3600*SimDays/dtau;
PrintInt=24*3600*PrintDay/dtau;

Global.Cache=CGDycore.CacheCreate(CG.OrdPoly+1,Global.Grid.NumFaces,CG.NumG,Global.Grid.nz,Model.NumV)
str = IntMethod
if str == "Rosenbrock"
  Global.J = CGDycore.JStruct(CG.NumG,nz)
  Global.Cache.k=zeros(size(U)..., Global.ROS.nStage);
  Global.Cache.fV=zeros(size(U))
elseif str == "RungeKutta"
  Global.Cache.f=zeros(size(U)..., Global.RK.nStage);
end

# Print initial conditions
Global.Output.vtk=CGDycore.vtkOutput(U,vtkGrid,CG,Global);

if str == "Rosenbrock"
    @time begin
      for i=1:nIter
        Δt = @elapsed begin
          CGDycore.RosenbrockSchur!(U,dtau,CGDycore.FcnNHCurlVec!,CGDycore.JacSchur!,CG,Global);
          time[1] += dtau;
          if mod(i,PrintInt)==0
            Global.Output.vtk=CGDycore.vtkOutput(U,vtkGrid,CG,Global);
          end
        end
        percent = i/nIter*100
        @info "Iteration: $i took $Δt, $percent% complete"
      end
    end

elseif str == "RungeKutta"
    @time begin
      for i=1:nIter
        Δt = @elapsed begin
          CGDycore.RungeKuttaExplicit!(U,dtau,CGDycore.FcnNHCurlVec!,CG,Global);

          time[1] += dtau;
          if mod(i,PrintInt)==0
            Global.Output.vtk=CGDycore.vtkOutput(U,vtkGrid,CG,Global);
          end
        end
        percent = i/nIter*100
        @info "Iteration: $i took $Δt, $percent% complete"
      end
    end
else
  error("Bad str")
end
