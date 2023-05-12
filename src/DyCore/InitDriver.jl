function InitSphere(OrdPoly,OrdPolyZ,nz,nPanel,H,GridType,Topography,Decomp,Model,Phys)    

  comm = MPI.COMM_WORLD
  Proc = MPI.Comm_rank(comm) + 1 
  ProcNumber = MPI.Comm_size(comm)
  ParallelCom = ParallelComStruct()
  ParallelCom.Proc = Proc
  ParallelCom.ProcNumber  = ProcNumber

  TimeStepper = TimeStepperStruct()
  Grid = GridStruct(nz,Topography)

  if GridType == "HealPix"
  # Grid=CGDycore.InputGridH("Grid/mesh_H12_no_pp.nc",
  # CGDycore.OrientFaceSphere,Phys.RadEarth,Grid)
    Grid=InputGridH("Grid/mesh_H24_no_pp.nc", OrientFaceSphere,Phys.RadEarth,Grid)
  elseif GridType == "SQuadGen"
    Grid = InputGrid("Grid/baroclinic_wave_2deg_x4.g",OrientFaceSphere,Phys.RadEarth,Grid)
  elseif GridType == "CubedSphere"
    Grid = CubedGrid(nPanel,OrientFaceSphere,Phys.RadEarth,Grid)
  end

  if Decomp == "Hilbert"
    HilbertFaceSphere!(Grid)
    CellToProc = Decompose(Grid,ProcNumber)
  elseif Decomp == "EqualArea"
    CellToProc = DecomposeEqualArea(Grid,ProcNumber)
  else
    CellToProc = ones(Int,Grid.NumFaces)
    println(" False Decomp method ")
  end

  SubGrid = ConstructSubGrid(Grid,CellToProc,Proc)

  if Model.Stretch
    if Model.StretchType == "ICON"  
      sigma = 1.0
      lambda = 3.16
      AddStretchICONVerticalGrid!(SubGrid,nz,H,sigma,lambda)
    elseif Model.StretchType == "Exp"  
      @show "AddExpStretchVerticalGrid"
      AddExpStretchVerticalGrid!(SubGrid,nz,H,30.0,1500.0)
    else
      AddVerticalGrid!(SubGrid,nz,H)
    end
  else  
    AddVerticalGrid!(SubGrid,nz,H)
  end

  Exchange = ExchangeStruct(SubGrid,OrdPoly,CellToProc,Proc,ProcNumber,Model.HorLimit)
  Output = OutputStruct(Topography)
  Global = GlobalStruct{Float64}(SubGrid,Model,TimeStepper,ParallelCom,Phys,Output,Exchange,OrdPoly+1,nz,
    Model.NumV,Model.NumTr,())
  Global.Metric = Metric(OrdPoly+1,OrdPolyZ+1,SubGrid.NumFaces,nz)
  (CG,Global) = DiscretizationCG(OrdPoly,OrdPolyZ,JacobiSphere3,Global)

  # Output partition
  nzTemp = Global.Grid.nz
  Global.Grid.nz = 1
  vtkCachePart = vtkStruct(1,TransSphereX,CG,Global)
  unstructured_vtkPartition(vtkCachePart, Global.Grid.NumFaces, Proc, ProcNumber)
  Global.Grid.nz = nzTemp

  if Topography.TopoS == "EarthOrography"
    zS = Orography(CG,Global)
    Output.RadPrint = H
    Output.Flat=false
    nzTemp = Global.Grid.nz
    Global.Grid.nz = 1
    vtkCacheOrography = vtkStruct(OrdPoly,TransSphereX,CG,Global)
    unstructured_vtkOrography(zS,vtkCacheOrography, Global.Grid.NumFaces, CG,  Proc, ProcNumber)
    Global.Grid.nz = nzTemp
  end

  if Topography.TopoS == "EarthOrography"
    (CG,Global)=CGDycore.DiscretizationCG(OrdPoly,OrdPolyZ,CGDycore.JacobiSphere3,Global,zS)
  else
    (CG,Global)=CGDycore.DiscretizationCG(OrdPoly,OrdPolyZ,CGDycore.JacobiSphere3,Global)
  end

  return CG,Global
end  


function InitCart(OrdPoly,OrdPolyZ,nx,ny,Lx,Ly,x0,y0,nz,H,Boundary,GridType,Topography,Decomp,Model,Phys)    

  comm = MPI.COMM_WORLD
  Proc = MPI.Comm_rank(comm) + 1 
  ProcNumber = MPI.Comm_size(comm)
  ParallelCom = ParallelComStruct()
  ParallelCom.Proc = Proc
  ParallelCom.ProcNumber  = ProcNumber

  TimeStepper = TimeStepperStruct()
  Grid = GridStruct(nz,Topography)

  Grid = CartGrid(nx,ny,Lx,Ly,x0,y0,OrientFaceCart,Boundary,Grid)

  CellToProc = Decompose(Grid,ProcNumber)
  SubGrid = ConstructSubGrid(Grid,CellToProc,Proc)

  if Model.Stretch
    if Model.StretchType == "ICON"  
      sigma = 1.0
      lambda = 3.16
      AddStretchICONVerticalGrid!(SubGrid,nz,H,sigma,lambda)
    elseif Model.StretchType == "Exp"  
      AddExpStretchVerticalGrid!(SubGrid,nz,H,30.0,1500.0)
    else
      AddVerticalGrid!(SubGrid,nz,H)
    end
  else  
    AddVerticalGrid!(SubGrid,nz,H)
  end

  Exchange = ExchangeStruct(SubGrid,OrdPoly,CellToProc,Proc,ProcNumber,Model.HorLimit)
  Output = OutputStruct(Topography)
  Global = GlobalStruct{Float64}(SubGrid,Model,TimeStepper,ParallelCom,Phys,Output,Exchange,OrdPoly+1,nz,
    Model.NumV,Model.NumTr,())
  Global.Metric = Metric(OrdPoly+1,OrdPolyZ+1,SubGrid.NumFaces,nz)
  (CG,Global) = DiscretizationCG(OrdPoly,OrdPolyZ,JacobiDG3Neu,Global)

  # Output partition
  nzTemp = Global.Grid.nz
  Global.Grid.nz = 1
  vtkCachePart = vtkStruct(1,TransCartX,CG,Global)
  unstructured_vtkPartition(vtkCachePart, Global.Grid.NumFaces, Proc, ProcNumber)
  Global.Grid.nz = nzTemp

  if Topography.TopoS == "EarthOrography"
    zS = Orography(CG,Global)
    Output.RadPrint = H
    Output.Flat=false
    nzTemp = Global.Grid.nz
    Global.Grid.nz = 1
    vtkCacheOrography = vtkStruct(OrdPoly,TransCartX,CG,Global)
    unstructured_vtkOrography(zS,vtkCacheOrography, Global.Grid.NumFaces, CG,  Proc, ProcNumber)
    Global.Grid.nz = nzTemp
  end

  return Global
end  


