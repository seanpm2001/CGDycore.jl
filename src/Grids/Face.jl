mutable struct Face
  N::Array{Int, 1}
  E::Array{Int, 1}
  F::Int
  FG::Int
  n::Point
  Mid::Point
  OrientE::Array{Int, 1}
  Type::String
  P::Array{Point, 1}
  Stencil::Array{Int, 1}
  Area::Float64
  Radius::Float64
  Orientation::Int64
end

function Face()
  N=zeros(Int,0)
  E=zeros(Int,0)
  F=0
  FG=0
  n=Point()
  Mid=Point()
  OrientE=zeros(Int,0)
  Type=""
  P=Array{Point}(undef, 0)
  Stencil=zeros(Int,0)
  Area::Float64 = 0
  Radius::Float64 = 0
  Orientation::Int = 1
  return Face(
    N,
    E,
    F,
    FG,
    n,
    Mid,
    OrientE,
    Type,
    P,
    Stencil,
    Area,
    Radius,
    Orientation,
  )
end  

function Face(EdgesF::Array{Int, 1},Nodes,Edges,Pos,Type,OrientFace;Form="Cart",Rad=1.0,
  P::Array{Float64,2}=[],ChangeOrient=3,MidFace=nothing)
  F = Face()
  if EdgesF[1]==0
    return (F,Edges)
  end

  nE=size(EdgesF,1);
  F.F=Pos;
  F.Type=Type
  # TODO: check translation
  @inbounds for iE=1:nE
    Edges[EdgesF[iE]].NumF +=1  
    Edges[EdgesF[iE]].F[Edges[EdgesF[iE]].NumF]=Pos;
  end
  #Sort edges
  F.E=zeros(Int,nE);
  F.E[1]=EdgesF[1];
  N2=Edges[F.E[1]].N[2];
  @inbounds for iE=2:nE
    @inbounds for iE1=iE:nE
      if N2==Edges[EdgesF[iE1]].N[1]
        F.E[iE]=EdgesF[iE1];
        N2=Edges[EdgesF[iE1]].N[2];
        EdgesF[iE1]=EdgesF[iE];
        EdgesF[iE]=F.E[iE];
        break
      elseif N2==Edges[EdgesF[iE1]].N[2]
        F.E[iE]=EdgesF[iE1];
        N2=Edges[EdgesF[iE1]].N[1];
        EdgesF[iE1]=EdgesF[iE];
        EdgesF[iE]=F.E[iE];
        break
      end
    end
  end
  F.N=zeros(Int,nE);
  F.N[1:2]=Edges[F.E[1]].N;
  @inbounds for iE=2:nE-1
    if F.N[iE]==Edges[F.E[iE]].N[1]
      F.N[iE+1]=Edges[F.E[iE]].N[2];
    else
      F.N[iE+1]=Edges[F.E[iE]].N[1];
    end
  end
  if P == zeros(Float64,0,0)
    F.P=Array{Point}(undef, size(F.N,1))  
    @inbounds for i=1:size(F.N,1)
      F.P[i]=Nodes[F.N[i]].P;
    end
  else
    F.P=Array{Point}(undef, size(F.N,1))  
    @inbounds for i=1:size(F.N,1)
      F.P[i]=Point(P[:,i])
    end
  end
  if Form == "Sphere"
    F.Area = AreaFace(F,Nodes) * Rad * Rad
  else  
    PT=Point([0.0, 0.0, 0.0]);
    @inbounds for i=1:nE-1
      PT=PT+cross(F.P[i],F.P[i+1]);
    end
    PT=PT+cross(F.P[nE],F.P[1]);
    F.Area = 0.5*norm(PT);
  end
  if MidFace === nothing
    @inbounds for i=1:nE
      F.Mid = F.Mid + F.P[i]
    end
    F.Mid = F.Mid / Float64(nE)
  else
    F.Mid.x = MidFace.x
    F.Mid.y = MidFace.y
    F.Mid.z = MidFace.z
  end  
  if Form == "Sphere"
    F.Mid = F.Mid / norm(F.Mid) * Rad
  end  
  if Form == "Sphere"
    F.Radius = Rad
  else
  end    


  NumE=size(EdgesF,1);
  F.n=cross(F.P[NumE],F.P[1]);
  @inbounds for i=1:NumE-1
    F.n=F.n+cross(F.P[i],F.P[i+1]);
  end
  F.n=F.n/norm(F.n);
  if OrientFace(F.n,F.Mid) < 0 
    F.Orientation = -1  
    if NumE > ChangeOrient
      #Change Orientation
      NTemp=copy(F.N);
      ETemp=copy(F.E);
      PTemp=copy(F.P);
      @inbounds for i=1:nE
        F.N[i]=NTemp[nE-i+1];
        F.P[i]=PTemp[nE-i+1];
      end
      @inbounds for i=1:nE-1
        F.E[i]=ETemp[nE-i];
      end
      F.n=-F.n;
      F.Orientation = 1  
    end  
  end
  F.OrientE = zeros(Int,NumE)
  for i = 1 : NumE
    iE = F.E[i]  
    if Edges[iE].N[1] == F.N[i]
      F.OrientE[i] = F.Orientation
    else
      F.OrientE[i] = -F.Orientation
    end  
  end  
  return F, Edges
end
