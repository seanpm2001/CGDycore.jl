mutable struct RT0Struct{FT<:AbstractFloat,
                        IT2<:AbstractArray}
  Glob::IT2                        
  Stencil::IT2
end
function RT0Struct{FT}(backend) where FT<:AbstractFloat
  Glob = KernelAbstractions.zeros(backend,Int,0,0)
  Stencil = KernelAbstractions.zeros(backend,Int,0,0)
 return CGStruct{FT,
                 typeof(Glob)}( 
    Glob,
    Stencil,
  )
end
mutable struct CGStruct{FT<:AbstractFloat,
                        AT1<:AbstractArray,
                        AT2<:AbstractArray,
                        IT1<:AbstractArray,
                        IT2<:AbstractArray}
    OrdPoly::Int
    OrdPolyZ::Int
    DoF::Int
    Glob::IT2
    Stencil::IT2
    NumG::Int
    NumI::Int
    w::AT1
    xw::AT1
    xwCPU::Array{FT, 1}
    xe::Array{FT, 1}
    IntXE2F::Array{FT, 2}
    xwZ::AT1
    xwZCPU::Array{FT, 1}
    IntZE2F::Array{FT, 2}
    DW::AT2
    DWT::Array{FT, 2}
    DS::AT2
    DST::Array{FT, 2}
    DSZ::Array{FT, 2}
    S::Array{FT, 2}
    M::AT2
    MMass::AT2
    MW::AT2
    Boundary::Array{Int, 1}
    MasterSlave::IT1
end

function CGStruct{FT}(backend,OrdPoly,OrdPolyZ,Grid) where FT<:AbstractFloat
# Discretization
  OP=OrdPoly+1
  OPZ=OrdPolyZ+1
  nz = Grid.nz

# CG = CGStruct{FT}(backend)
  OrdPoly=OrdPoly
  OrdPolyZ=OrdPolyZ
  DoF = OP * OP

  (wCPU,xwCPU)=DG.GaussLobattoQuad(OrdPoly)
  w = KernelAbstractions.zeros(backend,FT,size(wCPU))
  xw = KernelAbstractions.zeros(backend,FT,size(xwCPU))
  copyto!(w,wCPU)
  copyto!(xw,xwCPU)
  
  (wZ,xwZCPU)=DG.GaussLobattoQuad(OrdPolyZ)
  xwZ = KernelAbstractions.zeros(backend,FT,size(xwZCPU))
  copyto!(xwZ,xwZCPU)
  xe = zeros(OrdPoly+1)
  xe[1] = -1.0
  for i = 2 : OrdPoly
    xe[i] = xe[i-1] + 2.0/OrdPoly
  end
  xe[OrdPoly+1] = 1.0

  IntXE2F = zeros(OrdPoly+1,OrdPoly+1)
  for j = 1 : OrdPoly + 1
    for i = 1 : OrdPoly +1
      IntXE2F[i,j] = DG.Lagrange(xwCPU[i],xe,j)
    end
  end

  IntZE2F = zeros(OrdPolyZ+1,OrdPolyZ+1)
  for j = 1 : OrdPolyZ + 1
    for i = 1 : OrdPolyZ +1
      IntZE2F[i,j] = DG.Lagrange(xwZCPU[i],xwZCPU,j)
    end
  end

  (DWCPU,DSCPU)=DG.DerivativeMatrixSingle(OrdPoly)
  DS = KernelAbstractions.zeros(backend,FT,size(DSCPU))
  copyto!(DS,DSCPU)
  DW = KernelAbstractions.zeros(backend,FT,size(DWCPU))
  copyto!(DW,DWCPU)
  DST=DS'
  DWT=DW'

  Q = diagm(wCPU) * DSCPU
  S = Q - Q'
  (DWZ,DSZ)=DG.DerivativeMatrixSingle(OrdPolyZ)
  (GlobCPU,NumG,NumI,StencilCPU,MasterSlaveCPU) =
    NumberingFemCG(Grid,OrdPoly)  

  Glob = KernelAbstractions.zeros(backend,Int,size(GlobCPU))
  copyto!(Glob,GlobCPU)
  Stencil = KernelAbstractions.zeros(backend,Int,size(StencilCPU))
  copyto!(Stencil,StencilCPU)
  MasterSlave = KernelAbstractions.zeros(backend,Int,size(MasterSlaveCPU))
  copyto!(MasterSlave,MasterSlaveCPU)


# Boundary nodes
  Boundary = zeros(Int,0)
  for iF = 1 : Grid.NumFaces
    Side = 0
    for iE in Grid.Faces[iF].E
       Side += 1 
       if Grid.Edges[iE].F[1] == 0 || Grid.Edges[iE].F[2] == 0
          @views GlobLoc = reshape(Glob[:,iF],OP,OP) 
         if Side == 1
           for i in GlobLoc[1:OP-1,1]   
             push!(Boundary,i)
           end
         elseif Side == 2  
           for i in GlobLoc[OP,1:OP-1]
             push!(Boundary,i)
           end
         elseif Side == 3  
           for i in GlobLoc[2:OP,OP]
             push!(Boundary,i)
           end
         elseif Side == 4  
           for i in GlobLoc[1,2:OP]
             push!(Boundary,i)
           end
         end  
       end  
    end
  end  
  M = KernelAbstractions.zeros(backend,FT,nz,NumG)
  MMass = KernelAbstractions.zeros(backend,FT,nz,NumG)
  MW = KernelAbstractions.zeros(backend,FT,nz-1,NumG)
  return CGStruct{FT,
                 typeof(w),
                 typeof(DW),
                 typeof(MasterSlave),
                 typeof(Stencil)}(
    OrdPoly,
    OrdPolyZ,
    DoF,
    Glob,
    Stencil,
    NumG,
    NumI,
    w,
    xw,
    xwCPU,
    xe,
    IntXE2F,
    xwZ,
    xwZCPU,
    IntZE2F,
    DW,
    DWT,
    DS,
    DST,
    DSZ,
    S,
    M,
    MMass,
    MW,
    Boundary,
    MasterSlave,
 )
end
