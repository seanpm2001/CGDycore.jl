import CGDycore:
  Examples, Parallels, Models, Grids, Outputs, Integration,  GPU, DyCore
using MPI
using Base
using CUDA
using AMDGPU
using Metal
using KernelAbstractions
using StaticArrays
using ArgParse

MPI.Init()
comm = MPI.COMM_WORLD
Proc = MPI.Comm_rank(comm) + 1
ProcNumber = MPI.Comm_size(comm)
ParallelCom = DyCore.ParallelComStruct()
ParallelCom.Proc = Proc
ParallelCom.ProcNumber  = ProcNumber

FTB = Float32

# Physical parameters
Phys = DyCore.PhysParameters{FTB}()

#ModelParameters
Model = DyCore.ModelStruct{FTB}()

backend = CPU()
nz = 1
Rad = 1.0
RefineLevel = 5
OrdPoly = 3
nPanel = 10
RadEarth = 1.0
Decomp = "EqualArea"

GridType = "DelaunaySphere"
Grid, Exchange = Grids.InitGrid(backend,FTB,OrdPoly,nz,nPanel,RefineLevel,GridType,Decomp,RadEarth,Model,ParallelCom)
vtkSkeletonMesh = Outputs.vtkStruct{Float64}(backend,Grid)
c = ones(FTB,Grid.NumFaces) * Proc
Outputs.vtkSkeleton(vtkSkeletonMesh, GridType, Proc, ProcNumber , c)

GridType = "TriangularSphere"
Grid, Exchange = Grids.InitGrid(backend,FTB,OrdPoly,nz,nPanel,RefineLevel,GridType,Decomp,RadEarth,Model,ParallelCom)
vtkSkeletonMesh = Outputs.vtkStruct{Float64}(backend,Grid)
c = ones(FTB,Grid.NumFaces) * Proc
Outputs.vtkSkeleton(vtkSkeletonMesh, GridType, Proc, ProcNumber , c)

GridType = "SQuadGen"
Grid, Exchange = Grids.InitGrid(backend,FTB,OrdPoly,nz,nPanel,RefineLevel,GridType,Decomp,RadEarth,Model,ParallelCom)
vtkSkeletonMesh = Outputs.vtkStruct{Float64}(backend,Grid)
c = ones(FTB,Grid.NumFaces) * Proc
Outputs.vtkSkeleton(vtkSkeletonMesh, GridType, Proc, ProcNumber , c)

GridType = "Msh"
Grid, Exchange = Grids.InitGrid(backend,FTB,OrdPoly,nz,nPanel,RefineLevel,GridType,Decomp,RadEarth,Model,ParallelCom)
vtkSkeletonMesh = Outputs.vtkStruct{Float64}(backend,Grid)
c = ones(FTB,Grid.NumFaces) * Proc
Outputs.vtkSkeleton(vtkSkeletonMesh, GridType, Proc, ProcNumber , c)


