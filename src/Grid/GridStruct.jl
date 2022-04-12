mutable struct GridStruct
    nz::Int
    zP::Array{Float64, 1}
    z::Array{Float64, 1}
    dz::Float64
    H::Float64
    NumFaces::Int
    Faces::Array{Face, 1}
    NumEdges::Int
    Edges::Array{Edge, 1}
    NumNodes::Int
    Nodes::Array{Node, 1}
    Form::String
    Type ::String
    Dim::Int
    Rad::Float64
    NumEdgesI::Int
    NumEdgesB::Int
    nBar3::Array{Float64, 2}
    nBar::Array{Float64, 2}
    Topography::NamedTuple
end
function Grid(nz,Topography)
  zP=zeros(nz)
  z=zeros(nz+1)
  dz=0.0
  H=0.0
  NumFaces=0
  Faces=Array{Face}(undef, 0)
  NumEdges=0
  Edges=Array{Edge}(undef, 0)
  NumNodes=0
  Nodes=Array{Node}(undef, 0)
  Form=""
  Type=""
  Dim=0
  Rad=0.0
  NumEdgesI=0
  NumEdgesB=0
  nBar3=zeros(0,0)
  nBar=zeros(0,0)
   return GridStruct(
    nz,
    zP,
    z,
    dz,
    H,
    NumFaces,
    Faces,
    NumEdges,
    Edges, 
    NumNodes,
    Nodes, 
    Form,
    Type,
    Dim,
    Rad,
    NumEdgesI,
    NumEdgesB,
    nBar3,
    nBar,
    Topography
    )
end   
    

