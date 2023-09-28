Rad = 1.0

#struct Point{FT}
#  x::FT
#  y::FT
#  z::FT
#end 

function Norm(P::Point)
  sqrt(P.x * P.x + P.y * P.y + P.z * P.z)
end  

function Div(P::Point,s)
  return Point(P.x / s, P.y / s, P.z / s)
end  

function MidPoint(P1::Point,P2::Point)
  P = Point(0.5 * (P1.x + P2.x),
    0.5 * (P1.y + P2.y), 0.5 * (P1.z + P2.z))
  M = Div(P, Norm(P) / Rad)
end  

mutable struct NodeTri_T
  P::Point
  Edge::Array{Int,1}
  Number::Int
end

function NodeTri_T(P)
  Edge = zeros(Int,0)
  NodeTri_T(P,Edge,0)
end  

mutable struct EdgeTri_T{TN}
  Node1::ListNode{TN}
  Node2::ListNode{TN}
  Face::Array{Int,1}
  Number::Int
end

function EdgeTri_T(Node1,Node2)
  Face = zeros(Int,0)
  EdgeTri_T(Node1,Node2,Face,0)
end  

mutable struct FaceTri_T{TE}
  Edge1::ListNode{TE}
  Edge2::ListNode{TE}
  Edge3::ListNode{TE}
  OrientE1::Int
  OrientE2::Int
  OrientE3::Int
  Number::Int
end

function FaceTri_T(Edge1,Edge2,Edge3,OrientE1,OrientE2,OrientE3)
  FaceTri_T(Edge1,Edge2,Edge3,OrientE1,OrientE2,OrientE3,0)
end  
  
mutable struct TriangularGrid_T{TN,TE,TF}
  NodeList::DoublyLinkedList{TN}
  EdgeList::DoublyLinkedList{TE}
  FaceList::DoublyLinkedList{TF}
  NumNodes::Int
  NumEdges::Int
  NumFaces::Int
end

function TriangularGrid_T()
  NodeList = DoublyLinkedList{NodeTri_T}()
  EdgeList = DoublyLinkedList{EdgeTri_T}()
  FaceList = DoublyLinkedList{FaceTri_T}()
  NumNodes = 0
  NumEdges = 0
  NumFaces = 0
  return TriangularGrid_T{NodeTri_T,EdgeTri_T,FaceTri_T}(
    NodeList,
    EdgeList,
    FaceList,
    NumNodes,
    NumEdges,
    NumFaces,
    )
end  

function CreateIcosahedronGrid()
  Rad = 1.0
  IcosahedronGrid = TriangularGrid_T()

# Nodes
  Node = NodeTri_T(Point(0.0,0.0,Rad))
  push!(IcosahedronGrid.NodeList, Node)
  phi = atan(0.5)
  lam = 0.0
  for i = 1 : 5
    Node = NodeTri_T(Point(Rad*cos(lam)*cos(phi),Rad*sin(lam)*cos(phi),Rad*sin(phi)))  
    push!(IcosahedronGrid.NodeList, Node)
    lam = lam + 2.0 * pi / 5.0
  end
  phi = -atan(0.5)
  lam = pi / 5.0
  for i = 1 : 5
    Node = NodeTri_T(Point(Rad*cos(lam)*cos(phi),Rad*sin(lam)*cos(phi),Rad*sin(phi)))  
    push!(IcosahedronGrid.NodeList, Node)
    lam = lam + 2.0 * pi / 5.0
  end
  Node = NodeTri_T(Point(0.0,0.0,-Rad))
  push!(IcosahedronGrid.NodeList, Node)

  NodeTop = getnode(IcosahedronGrid.NodeList,1)
  NodeLayerTopFirst = getnode(IcosahedronGrid.NodeList,2)
  NodeLayerBottomFirst = getnode(IcosahedronGrid.NodeList,7)
  NodeBottom = getnode(IcosahedronGrid.NodeList,12)

# Edges
  NodeLayerTop = NodeLayerTopFirst
  for i = 1 : 5
    Edge = EdgeTri_T(NodeLayerTop,NodeTop)
    push!(IcosahedronGrid.EdgeList, Edge)
    NodeLayerTop = NodeLayerTop.next
  end  
  NodeLayerTop = NodeLayerTopFirst
  for i = 1 : 4
    Edge = EdgeTri_T(NodeLayerTop,NodeLayerTop.next)
    push!(IcosahedronGrid.EdgeList, Edge)
    NodeLayerTop = NodeLayerTop.next
  end  
  Edge = EdgeTri_T(NodeLayerTop,NodeLayerTopFirst)
  push!(IcosahedronGrid.EdgeList, Edge)

  NodeLayerTop = NodeLayerTopFirst
  NodeLayerBottom = NodeLayerBottomFirst
  for i = 1 : 4
    Edge = EdgeTri_T(NodeLayerBottom,NodeLayerTop)
    push!(IcosahedronGrid.EdgeList, Edge)
    Edge = EdgeTri_T(NodeLayerBottom,NodeLayerTop.next)
    push!(IcosahedronGrid.EdgeList, Edge)
    NodeLayerTop = NodeLayerTop.next
    NodeLayerBottom = NodeLayerBottom.next
  end  
  Edge = EdgeTri_T(NodeLayerBottom,NodeLayerTop)
  push!(IcosahedronGrid.EdgeList, Edge)
  Edge = EdgeTri_T(NodeLayerBottom,NodeLayerTopFirst)
  push!(IcosahedronGrid.EdgeList, Edge)

  NodeLayerBottom = NodeLayerBottomFirst
  for i = 1 : 4
    Edge = EdgeTri_T(NodeLayerBottom,NodeLayerBottom.next)
    push!(IcosahedronGrid.EdgeList, Edge)
    NodeLayerBottom = NodeLayerBottom.next
  end  
  Edge = EdgeTri_T(NodeLayerBottom,NodeLayerBottomFirst)
  push!(IcosahedronGrid.EdgeList, Edge)

  NodeLayerBottom = NodeLayerBottomFirst
  for i = 1 : 5
    Edge = EdgeTri_T(NodeBottom,NodeLayerBottom)
    push!(IcosahedronGrid.EdgeList, Edge)
    NodeLayerBottom = NodeLayerBottom.next
  end  

  EdgeTopFirst = getnode(IcosahedronGrid.EdgeList,1)
  EdgeLayerTopFirst = getnode(IcosahedronGrid.EdgeList,6)
  EdgeMidFirst = getnode(IcosahedronGrid.EdgeList,11)
  EdgeLayerBottomFirst = getnode(IcosahedronGrid.EdgeList,21)
  EdgeBottomFirst = getnode(IcosahedronGrid.EdgeList,26)

  #Faces
  EdgeTop = EdgeTopFirst
  EdgeLayerTop = EdgeLayerTopFirst
  for i = 1 : 4
    Face = FaceTri_T(EdgeLayerTop,EdgeTop.next,EdgeTop,1,1,-1)
    push!(IcosahedronGrid.FaceList, Face)
    EdgeTop = EdgeTop.next
    EdgeLayerTop = EdgeLayerTop.next
  end  
  Face = FaceTri_T(EdgeLayerTop,EdgeTopFirst,EdgeTop,1,1,-1)
  push!(IcosahedronGrid.FaceList, Face)

  EdgeLayerTop = EdgeLayerTopFirst
  EdgeMid = EdgeMidFirst
  EdgeLayerBottom = EdgeLayerBottomFirst
  for i = 1 : 4
    Face = FaceTri_T(EdgeMid,EdgeMid.next,EdgeLayerTop,-1,1,-1)
    push!(IcosahedronGrid.FaceList, Face)
    EdgeMid = EdgeMid.next
    Face = FaceTri_T(EdgeMid.next,EdgeMid,EdgeLayerBottom,1,-1,1)
    push!(IcosahedronGrid.FaceList, Face)
    EdgeLayerTop = EdgeLayerTop.next
    EdgeMid = EdgeMid.next
    EdgeLayerBottom = EdgeLayerBottom.next
  end  
  Face = FaceTri_T(EdgeMid,EdgeMid.next,EdgeLayerTop,-1,1,-1)
  push!(IcosahedronGrid.FaceList, Face)
  EdgeMid = EdgeMid.next
  Face = FaceTri_T(EdgeMidFirst,EdgeMid,EdgeLayerBottom,1,-1,1)
  push!(IcosahedronGrid.FaceList, Face)

  EdgeLayerBottom = EdgeLayerBottomFirst
  EdgeBottom = EdgeBottomFirst
  for i = 1 : 4
    Face = FaceTri_T(EdgeLayerBottom,EdgeBottom.next,EdgeBottom,1,-1,1)
    push!(IcosahedronGrid.FaceList, Face)
    EdgeLayerBottom = EdgeLayerBottom.next
    EdgeBottom = EdgeBottom.next
  end  
  Face = FaceTri_T(EdgeLayerBottom,EdgeBottomFirst,EdgeBottom,1,-1,1)
  push!(IcosahedronGrid.FaceList, Face)
  return IcosahedronGrid
      
end

function RefineEdge!(Edge,NodeList,EdgeList)
  P1 = Edge.data.Node1.data.P
  P2 = Edge.data.Node2.data.P
  NodeM = newnode(NodeList, NodeTri_T(MidPoint(P1,P2)))
  insertafter!(NodeM, Edge.data.Node1)
  EdgeNew = newnode(EdgeList, EdgeTri_T(NodeM,Edge.data.Node2))
  insertafter!(EdgeNew, Edge)
  Edge.data.Node2 = NodeM
end  

function RefineEdgeTriangularGrid!(TriangularGrid)

  NodeList = TriangularGrid.NodeList
  EdgeList = TriangularGrid.EdgeList

  Edge = head(TriangularGrid.EdgeList)
  while ~attail(Edge)
    RefineEdge!(Edge,NodeList,EdgeList)
    Edge = Edge.next.next
  end  
end

function RefineFace!(Face,EdgeList,FaceList)

 Edge1 = Face.data.Edge1
 Edge1N = Edge1.next
 Edge2 = Face.data.Edge2
 Edge2N = Edge2.next
 Edge3 = Face.data.Edge3
 Edge3N = Edge3.next
 if Face.data.OrientE1  == 1 
   Face2Edge2 = Edge1
   Face2OrientE2 = 1
   Face3Edge1 = Edge1N
   Face3OrientE1 = 1
 else
   Face2Edge2 = Edge1N
   Face2OrientE2 = -1
   Face3Edge1 = Edge1
   Face3OrientE1 = -1
 end  
 if Face.data.OrientE2 == 1
   Face3Edge2 = Edge2
   Face3OrientE2 = 1
   Face1Edge1 = Edge2N
   Face1OrientE1 = 1
 else
   Face3Edge2 = Edge2N
   Face3OrientE2 = -1
   Face1Edge1 = Edge2
   Face1OrientE1 = -1
 end
 if Face.data.OrientE3 == 1
   Face1Edge2 = Edge3
   Face1OrientE2 = 1
   Face2Edge1 = Edge3N
   Face2OrientE1 = 1
 else
   Face1Edge2 = Edge3N
   Face1OrientE2 = -1
   Face2Edge1 = Edge3
   Face2OrientE1 = -1
 end
 EdgeI1 = newnode(EdgeList, EdgeTri_T(Edge2.data.Node2,Edge3.data.Node2))
 insertafter!(EdgeI1, Edge1N)
 EdgeI2 = newnode(EdgeList, EdgeTri_T(Edge3.data.Node2,Edge1.data.Node2))
 insertafter!(EdgeI2, Edge2N)
 EdgeI3 = newnode(EdgeList, EdgeTri_T(Edge1.data.Node2,Edge2.data.Node2))
 insertafter!(EdgeI3, Edge3N)

 Face1Edge3 = EdgeI1
 Face1OrientE3 = -1
 Face1 = newnode(FaceList,FaceTri_T(Face1Edge1,Face1Edge2,Face1Edge3,Face1OrientE1,
   Face1OrientE2,Face1OrientE3))
 insertafter!(Face1, Face)

 Face2Edge3 = EdgeI2
 Face2OrientE3 = -1
 Face2 = newnode(FaceList,FaceTri_T(Face2Edge1,Face2Edge2,Face2Edge3,Face2OrientE1,
   Face2OrientE2,Face2OrientE3))
 insertafter!(Face2, Face)

 Face3Edge3 = EdgeI3
 Face3OrientE3 = -1
 Face3 = newnode(FaceList,FaceTri_T(Face3Edge1,Face3Edge2,Face3Edge3,Face3OrientE1,
   Face3OrientE2,Face3OrientE3))
 insertafter!(Face3, Face)

 Face.data.Edge1 = EdgeI1
 Face.data.OrientE1 = 1
 Face.data.Edge2 = EdgeI2
 Face.data.OrientE2 = 1
 Face.data.Edge3 = EdgeI3
 Face.data.OrientE3 = 1

end

function RefineFaceTriangularGrid!(TriangularGrid)

  EdgeList = TriangularGrid.EdgeList
  FaceList = TriangularGrid.FaceList

  Face = head(FaceList)
  while ~attail(Face)
    RefineFace!(Face,EdgeList,FaceList)
    Face = Face.next
    Face = Face.next
    Face = Face.next
    Face = Face.next
  end
end


function NumberingTriangularGrid!(TriangularGrid)

  NumNodes = 0
  NodeL = head(TriangularGrid.NodeList)
  while ~attail(NodeL)
    NumNodes += 1
    NodeL.data.Number = NumNodes
    NodeL = NodeL.next
  end
  TriangularGrid.NumNodes = NumNodes


  NumEdges = 0
  EdgeL = head(TriangularGrid.EdgeList)
  while ~attail(EdgeL)
    NumEdges += 1
    EdgeL.data.Number = NumEdges
    push!(EdgeL.data.Node1.data.Edge,NumEdges)
    push!(EdgeL.data.Node2.data.Edge,NumEdges)
    EdgeL = EdgeL.next
  end
  TriangularGrid.NumEdges = NumEdges


  NumFaces = 0
  FaceL = head(TriangularGrid.FaceList)
  while ~attail(FaceL)
    NumFaces += 1
    FaceL.data.Number = NumFaces
    push!(FaceL.data.Edge1.data.Face,NumFaces)
    push!(FaceL.data.Edge2.data.Face,NumFaces)
    push!(FaceL.data.Edge3.data.Face,NumFaces)
    FaceL = FaceL.next
  end
  TriangularGrid.NumFaces = NumFaces

end

function MidPoint(Face)

  P = Point()
  if Face.data.OrientE1 == 1
    P = Face.data.Edge1.data.Node1.data.P
  else
    P = Face.data.Edge1.data.Node2.data.P
  end
  if Face.data.OrientE2 == 1
    P = P + Face.data.Edge2.data.Node1.data.P
  else
    P = P + Face.data.Edge2.data.Node2.data.P
  end
  if Face.data.OrientE3 == 1
    P = P + Face.data.Edge3.data.Node1.data.P
  else
    P = P + Face.data.Edge3.data.Node2.data.P
  end
  M = Div(P, Norm(P) / (3.0 * Rad))
end

function TriangularGridToGrid(TriangularGrid,Rad,Grid)
  Grid.nBar=[ 0  1   0   1
             -1  0  -1   0]
  Grid.Dim = 3
  Grid.Type = "Tri"
  Grid.Rad = Rad
  Grid.Form = "Sphere"

  NumNodes = TriangularGrid.NumNodes

  Nodes = map(1:NumNodes) do i
    Node()
  end

  NodeL = head(TriangularGrid.NodeList)
  NumNodes = 0
  while ~attail(NodeL)
    NumNodes += 1
    Nodes[NumNodes] = Node(NodeL.data.P,NumNodes)
    NodeL = NodeL.next
  end
  Grid.Nodes = Nodes

  NumEdges = TriangularGrid.NumEdges

  Edges = map(1:NumEdges) do i
    Edge()
  end

  EdgeL = head(TriangularGrid.EdgeList)
  NumEdges = 0
  while ~attail(EdgeL)
    NumEdges += 1
    n1 = EdgeL.data.Node1.data.Number
    n2 = EdgeL.data.Node2.data.Number
    Edges[NumEdges] = Edge([n1,n2],Grid,NumEdges,NumEdges,"",NumEdges)
    EdgeL = EdgeL.next
  end
  Grid.Edges = Edges

  NumFaces = TriangularGrid.NumFaces

  Faces = map(1:NumFaces) do i
    Face()
  end

  FaceL = head(TriangularGrid.FaceList)
  NumFaces = 0
  while ~attail(FaceL)
    NumFaces += 1
    e1 = FaceL.data.Edge1.data.Number
    e2 = FaceL.data.Edge2.data.Number
    e3 = FaceL.data.Edge3.data.Number
    (Faces[NumFaces], Grid) = Face([e1,e2,e3],Grid,NumFaces,"",OrientFaceSphere;P=zeros(Float64,0,0))
    FaceL = FaceL.next
  end
  Grid.Faces = Faces
  Grid.NumNodes = size(Grid.Nodes,1)
  Grid.NumEdges = size(Grid.Edges,1)
  Grid.NumFaces = size(Grid.Faces,1)

  Grid=Renumbering(Grid)
  @show "Triangular, vor FacesInNodes"
  Grid=FacesInNodes(Grid)

  #Boundary/Interior faces
  BoundaryFaces = zeros(Int,0)
  @inbounds for iE = 1 : Grid.NumEdges
    if Grid.Edges[iE].F[1] == 0 || Grid.Edges[iE].F[2] == 0
      @inbounds for iN in Grid.Edges[iE].N
        @inbounds for iF in Grid.Nodes[iN].F
          push!(BoundaryFaces,iF)
        end
      end
    end
  end
  BoundaryFaces = unique(BoundaryFaces)
  Grid.BoundaryFaces = BoundaryFaces
  Grid.InteriorFaces = setdiff(collect(UnitRange(1,Grid.NumFaces)),Grid.BoundaryFaces)

  return Grid
end

function DelaunayGridToPolyGrid(TriangularGrid,Rad,Grid)
  Grid.nBar=[ 0  1   0   1
             -1  0  -1   0]
  Grid.Dim = 3
  Grid.Type = "Tri"
  Grid.Rad = Rad
  Grid.Form = "Sphere"

  NumNodes = TriangularGrid.NumFaces

  Nodes = map(1:NumNodes) do i
    Node()
  end

  FaceL = head(TriangularGrid.FaceList)
  NumNodes = 0
  while ~attail(FaceL)
    NumNodes += 1
    Nodes[NumNodes] = Node(MidPoint(FaceL),NumNodes)
    FaceL = FaceL.next
  end
  Grid.Nodes = Nodes

  NumEdges = TriangularGrid.NumEdges

  Edges = map(1:NumEdges) do i
    Edge()
  end

  EdgeL = head(TriangularGrid.EdgeList)
  NumEdges = 0
  while ~attail(EdgeL)
    NumEdges += 1
    n1 = EdgeL.data.Face[1]
    n2 = EdgeL.data.Face[2]
    Edges[NumEdges] = Edge([n1,n2],Grid,NumEdges,NumEdges,"",NumEdges)
    EdgeL = EdgeL.next
  end
  Grid.Edges = Edges

  NumFaces = TriangularGrid.NumNodes

  Faces = map(1:NumFaces) do i
    Face()
  end

  NodeL = head(TriangularGrid.NodeList)
  NumFaces = 0
  while ~attail(NodeL)
    NumFaces += 1
    e = NodeL.data.Edge
    (Faces[NumFaces], Grid) = Face(e,Grid,NumFaces,"",OrientFaceSphere;P=zeros(Float64,0,0))
    NodeL = NodeL.next
  end
  Grid.Faces = Faces
  Grid.NumNodes = size(Grid.Nodes,1)
  Grid.NumEdges = size(Grid.Edges,1)
  Grid.NumFaces = size(Grid.Faces,1)

  Grid=Renumbering(Grid)
  @show "Triangular, vor FacesInNodes"
  Grid=FacesInNodes(Grid)

  #Boundary/Interior faces
  BoundaryFaces = zeros(Int,0)
  @inbounds for iE = 1 : Grid.NumEdges
    if Grid.Edges[iE].F[1] == 0 || Grid.Edges[iE].F[2] == 0
      @inbounds for iN in Grid.Edges[iE].N
        @inbounds for iF in Grid.Nodes[iN].F
          push!(BoundaryFaces,iF)
        end
      end
    end
  end
  BoundaryFaces = unique(BoundaryFaces)
  Grid.BoundaryFaces = BoundaryFaces
  Grid.InteriorFaces = setdiff(collect(UnitRange(1,Grid.NumFaces)),Grid.BoundaryFaces)

  return Grid
end
