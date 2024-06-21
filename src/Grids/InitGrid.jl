function InitGridSphere(backend,FT,OrdPoly,nz,nPanel,RefineLevel,GridType,Decomp,RadEarth,Model,
  ParallelCom;order=true,ChangeOrient=3)

  ProcNumber = ParallelCom.ProcNumber
  Proc = ParallelCom.Proc

  if GridType == "HealPix"
  # Grid=CGDycore.InputGridH("Grid/mesh_H12_no_pp.nc",
  # CGDycore.OrientFaceSphere,Phys.RadEarth,Grid)
    Grid=Grids.InputGridH(backend,FT,"Grid/mesh_H24_no_pp.nc", Grids.OrientFaceSphere,RadEarth,nz)
  elseif GridType == "SQuadGen"
    Grid = Grids.InputGrid(backend,FT,"Grid/baroclinic_wave_2deg_x4.g",Grids.OrientFaceSphere,RadEarth,nz)
  elseif GridType == "Msh"
#   Grid = Grids.InputGridMsh(backend,FT,"Grid/natural_earth.msh",Grids.OrientFaceSphere,RadEarth,nz)
    Grid = Grids.InputGridMsh(backend,FT,"Grid/Quad.msh",Grids.OrientFaceSphere,RadEarth,nz)
  elseif GridType == "CubedSphere"
    Grid = Grids.CubedGrid(backend,FT,nPanel,Grids.OrientFaceSphere,RadEarth,nz,order=order)
  elseif GridType == "TriangularSphere"
    Grid = TriangularGrid(backend,FT,RefineLevel,RadEarth,nz;ChangeOrient=ChangeOrient)
  elseif GridType == "DelaunaySphere"
    Grid = DelaunayGrid(backend,FT,RefineLevel,RadEarth,nz)
  elseif GridType == "MPASO"
    Grid=Grids.InputGridMPASO(backend,FT,"Grid/QU240.nc", Grids.OrientFaceSphere,RadEarth,nz)
  elseif GridType == "MPAS"
    Grid=Grids.InputGridMPASO(backend,FT,"Grid/x4.163842.grid.nc", Grids.OrientFaceSphere,RadEarth,nz)
  else
    @show "False GridType"
  end

  if Decomp == "Hilbert"
    Parallels.HilbertFaceSphere!(Grid)
    CellToProc = Grids.Decompose(Grid,ProcNumber)
  elseif Decomp == "EqualArea"
    CellToProc = Grids.DecomposeEqualArea(Grid,ProcNumber)
  else
    CellToProc = ones(Int,Grid.NumFaces)
    println(" False Decomp method ")
  end
  SubGrid = Grids.ConstructSubGrid(Grid,CellToProc,Proc,order=order)

  Exchange = Parallels.ExchangeStruct{FT}(backend,SubGrid,OrdPoly,CellToProc,Proc,ProcNumber,Model.HorLimit)
  return SubGrid, Exchange
end  

function InitGridCart(backend,FT,OrdPoly,nx,ny,Lx,Ly,x0,y0,Boundary,nz,Model,ParallelCom;order=true)

  ProcNumber = ParallelCom.ProcNumber
  Proc = ParallelCom.Proc

  Grid = Grids.CartGrid(backend,FT,nx,ny,Lx,Ly,x0,y0,Grids.OrientFaceCart,Boundary,nz;order)
  CellToProc = Grids.Decompose(Grid,ProcNumber)
  SubGrid = Grids.ConstructSubGrid(Grid,CellToProc,Proc;order)
  Exchange = Parallels.ExchangeStruct{FT}(backend,SubGrid,OrdPoly,CellToProc,Proc,ProcNumber,Model.HorLimit)

  return SubGrid, Exchange
end  
