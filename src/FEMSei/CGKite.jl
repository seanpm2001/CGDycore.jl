mutable struct CG0KitePrimalStruct{FT<:AbstractFloat,
                        IT2<:AbstractArray} <: ScalarKitePElement
  Glob::IT2
  DoF::Int
  Comp::Int                      
  phi::Array{Polynomial,2}                       
  NumG::Int
  NumI::Int
  Type::Grids.ElementType
  M::AbstractSparseMatrix
end

function CG0KitePrimalStruct{FT}(::Grids.Quad,backend,Grid) where FT<:AbstractFloat
  Glob = KernelAbstractions.zeros(backend,Int,0,0)
  Type = Grids.QuadPrimal()
  DoF = 1
  Comp = 1
  @polyvar x1 x2
  phi = Array{Polynomial,2}(undef,DoF,Comp)
  x, w = gaussradau(1)
  phi[1,1] = 1 + 0*x1 + 0*x2
  
  NumNodes = Grid.NumNodes
  NumFaces = Grid.NumFaces
  Nodes = Grid.Nodes


  iKite = 1
  iOff = 1
  NumG = 0
  Glob = KernelAbstractions.zeros(backend,Int,DoF,NumFaces)
  GlobCPU = zeros(Int,DoF,NumFaces)
  for iN = 1 : NumNodes
    if Nodes[iN].Type == 'F'
      NumF = length(Nodes[iN].F)
      Offset = 1 
      for i = 1 : NumF
        GlobCPU[1,iKite] = iOff
        iKite +=1 
      end 
      iOff += Offset
      NumG += Offset
    end 
  end
  NumI = NumG
  copyto!(Glob,GlobCPU)
  M = spzeros(0,0)
  return CG0KitePrimalStruct{FT,
                  typeof(Glob)}( 
    Glob,
    DoF,
    Comp,
    phi,                      
    NumG,
    NumI,
    Type,
    M,
      )
end
mutable struct CG1KitePrimalStruct{FT<:AbstractFloat,
                        IT2<:AbstractArray} <: ScalarKitePElement
  Glob::IT2
  DoF::Int
  Comp::Int                      
  phi::Array{Polynomial,2}                       
  Gradphi::Array{Polynomial,2}                       
  NumG::Int
  NumI::Int
  Type::Grids.ElementType
  M::AbstractSparseMatrix
end

function CG1KitePrimalStruct{FT}(::Grids.Quad,backend,Grid) where FT<:AbstractFloat
  Glob = KernelAbstractions.zeros(backend,Int,0,0)
  Type = Grids.QuadPrimal()
  DoF = 4
  Comp = 1
  @polyvar x y
  phi = Array{Polynomial,2}(undef,DoF,Comp)
  xP, w = gaussradau(2)
  lx0 = (x - xP[2])/(xP[1] - xP[2])
  lx1 = (x - xP[1])/(xP[2] - xP[1])
  ly0 = (y - xP[2])/(xP[1] - xP[2])
  ly1 = (y - xP[1])/(xP[2] - xP[1])
  phi[1,1] = lx0 * ly0
  phi[2,1] = lx1 * ly0
  phi[3,1] = lx0 * ly1
  phi[4,1] = lx1 * ly1
  Gradphi = Array{Polynomial,2}(undef,DoF,2)
  for i = 1 : DoF
    Gradphi[i,1] = differentiate(phi[i,1],x)
    Gradphi[i,2] = differentiate(phi[i,1],y)
  end  
  
  NumNodes = Grid.NumNodes
  NumFaces = Grid.NumFaces
  Nodes = Grid.Nodes


  iKite = 1
  iOff = 0
  NumG = 0
  Glob = KernelAbstractions.zeros(backend,Int,DoF,NumFaces)
  GlobCPU = zeros(Int,DoF,NumFaces)
  for iN = 1 : NumNodes
    if Nodes[iN].Type == 'F'
      NumF = length(Nodes[iN].F)
      Offset = 1 + 2 * NumF
      for i = 1 : NumF
        GlobCPU[1,iKite] = iOff + 1
        GlobCPU[2,iKite] = iOff + 1 + i
        if i < NumF
          GlobCPU[3,iKite] = iOff + 1 + i + 1
        else    
          GlobCPU[3,iKite] = iOff + 1 + 1
        end  
        GlobCPU[4,iKite] = iOff + 1 + NumF + i
        iKite +=1 
      end 
      iOff += Offset
      NumG += Offset
    end 
  end
  NumI = NumG
  copyto!(Glob,GlobCPU)
  M = spzeros(0,0)
  return CG1KitePrimalStruct{FT,
                  typeof(Glob)}( 
    Glob,
    DoF,
    Comp,
    phi,                      
    Gradphi,                      
    NumG,
    NumI,
    Type,
    M,
      )
end

mutable struct CG1KiteDualStruct{FT<:AbstractFloat,
                        IT2<:AbstractArray} <: HDivKiteDElement
  Glob::IT2
  DoF::Int
  Comp::Int                      
  phi::Array{Polynomial,2}                       
  Divphi::Array{Polynomial,2}                       
  NumG::Int
  NumI::Int
  Type::Grids.ElementType
  M::AbstractSparseMatrix
end

function CG1KiteDualStruct{FT}(::Grids.Quad,backend,Grid) where FT<:AbstractFloat
  Glob = KernelAbstractions.zeros(backend,Int,0,0)
  Type = Grids.QuadDual()
  DoF = 8
  Comp = 2
  @polyvar x y
  phi = Array{Polynomial,2}(undef,DoF,Comp)
  Divphi = Array{Polynomial,2}(undef,DoF,1)
  xP, w = gaussradau(2)
  xP .= -xP
  lx0 = (x - xP[2])/(xP[1] - xP[2])
  lx1 = (x - xP[1])/(xP[2] - xP[1])
  ly0 = (y - xP[2])/(xP[1] - xP[2])
  ly1 = (y - xP[1])/(xP[2] - xP[1])
  p0 = 0.0*x + 0.0*y
  phi[1,1] = p0
  phi[1,2] = lx0 * ly0
  phi[2,1] = p0
  phi[2,2] = lx1 * ly0
  
  phi[3,1] = -lx0 * ly0
  phi[3,2] = p0
  phi[4,1] = -lx0 * ly1
  phi[4,2] = p0

  phi[5,1] = lx1 * ly0
  phi[5,2] = p0
  phi[6,1] = lx1 * ly1
  phi[6,2] = p0

  phi[7,1] = p0
  phi[7,2] = lx0 * ly1
  phi[8,1] = p0
  phi[8,2] = lx1 * ly1


  Divphi[1,1] =  (differentiate(phi[1,1],x) + differentiate(phi[1,2],y))
  Divphi[2,1] =  (differentiate(phi[2,1],x) + differentiate(phi[2,2],y))
  Divphi[3,1] =  (differentiate(phi[3,1],x) + differentiate(phi[3,2],y))
  Divphi[4,1] =  (differentiate(phi[4,1],x) + differentiate(phi[4,2],y))
  Divphi[5,1] =  (differentiate(phi[5,1],x) + differentiate(phi[5,2],y))
  Divphi[6,1] =  (differentiate(phi[6,1],x) + differentiate(phi[6,2],y))
  Divphi[7,1] =  (differentiate(phi[7,1],x) + differentiate(phi[7,2],y))
  Divphi[8,1] =  (differentiate(phi[8,1],x) + differentiate(phi[8,2],y))

  NumFaces = Grid.NumFaces
  NumEdges = Grid.NumEdges
  NumNodes = Grid.NumNodes
  Faces = Grid.Faces
  Edges = Grid.Edges
  Nodes = Grid.Nodes

# Kite list  
  KiteList = Dict()
  iKite = 1
  for iN = 1 : NumNodes
    if Nodes[iN].Type == 'F' 
      NumF = length(Nodes[iN].F)
      Offset = 1 + 2 * NumF
      for i = 1 : NumF
        iF = Nodes[iN].F[i]  
        N1 = Faces[iF].N[1]
        N3 = Faces[iF].N[3]  
        KiteList[(N1,N3)] = iKite
        iKite +=1 
      end 
    end 
  end 



  Glob = KernelAbstractions.zeros(backend,Int,DoF,NumFaces)
  GlobCPU = zeros(Int,DoF,NumFaces)
  iOff = 0
  for iN = 1 : NumNodes
    if Nodes[iN].Type == 'N'  
      NumF = length(Nodes[iN].F)  
      OffsetE = 2 * NumF
      for i = 1 : NumF
        iF = Nodes[iN].F[i]
        N1 = Faces[iF].N[1]
        N3 = Faces[iF].N[3]
        iKite = KiteList[(N1,N3)]
        #Edge e1
        GlobCPU[1,iKite] = iOff + 2 * i -1 
        GlobCPU[2,iKite] = iOff + 2 * i
        #Edge e2
        if i < NumF
          GlobCPU[3,iKite] = iOff + 2 * (i + 1) - 1
          GlobCPU[4,iKite] = iOff + 2 * (i + 1)
        else  
          GlobCPU[3,iKite] = iOff + 2 * 1 - 1
          GlobCPU[4,iKite] = iOff + 2 * 1
        end    
        # Interior e1
        GlobCPU[5,iKite] = iOff + OffsetE + 4 * i - 3
        GlobCPU[6,iKite] = iOff + OffsetE + 4 * i - 2
        # Interior e2
        GlobCPU[7,iKite] = iOff + OffsetE + 4 * i - 1
        GlobCPU[8,iKite] = iOff + OffsetE + 4 * i 
      end 
      iOff += 6 * NumF
    end 
  end
  NumG = iOff
  NumI = NumG
  copyto!(Glob,GlobCPU)
  M = spzeros(0,0)
  return CG1KiteDualStruct{FT,
                  typeof(Glob)}( 
    Glob,
    DoF,
    Comp,
    phi,                      
    Divphi,                      
    NumG,
    NumI,
    Type,
    M,
      )
end

