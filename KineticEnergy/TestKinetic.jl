using LinearAlgebra
include("GaussLobattoQuad.jl")
include("GaussLegendreQuad.jl")
include("Lagrange.jl")
include("DLagrange.jl")
include("Oro.jl")
include("JacobiDG2.jl")
include("DSS.jl")
include("DSSF.jl")
include("udwdx.jl")
include("wdwdx.jl")
include("IntCell.jl")
include("IntFace.jl")
include("dcdx.jl")
include("divdx.jl")
include("Sdwdz.jl")
include("Sdudz.jl")
include("dRhoSdz.jl")

function main()
  Nz = 20
  Nx = 10
  OrdPolyX=3
  H = 400
  hHill = 200
  L=1000
  if OrdPolyX>0
    #Horizontal Grid
    (wX,xw)=GaussLobattoQuad(OrdPolyX)
    I12 = ones(2,1)
    I21 = 0.5*ones(1,2)


    Dx=zeros(OrdPolyX+1,OrdPolyX+1)
    for i=1:OrdPolyX+1
      for j=1:OrdPolyX+1
        Dx[i,j]=DLagrange(xw[i],xw,j)
      end
    end
    #  Vertical Grid
    OrdPolyZ=1
    (wZ,zw)=GaussLobattoQuad(OrdPolyZ)
    (wZLG,zwLG)=GaussLegendreQuad(OrdPolyZ)

    IntLG2LGL = zeros(Float64,OrdPolyZ+1,OrdPolyZ)
    IntLGL2LG = zeros(Float64,OrdPolyZ,OrdPolyZ+1)
    @show zw
    @show zwLG
    for j = 1 : OrdPolyZ+1
      for i = 1 : OrdPolyZ
        IntLGL2LG[i,j]=Lagrange(zwLG[i],zw,j)
        IntLG2LGL[j,i]=Lagrange(zw[j],zwLG,i)
      end
    end
    @show IntLG2LGL
    @show IntLGL2LG

    Dz=zeros(OrdPolyZ+1,OrdPolyZ+1)
    for i=1:OrdPolyZ+1
      for j=1:OrdPolyZ+1
        Dz[i,j]=DLagrange(zw[i],zw,j)
      end
    end
  end
  xP=zeros(Nx,OrdPolyX+1)
  xP[1,1]=0
  dx=L/Nx
  for i=1:Nx
    for j=1:OrdPolyX+1
      xP[i,j]=xP[i,1]+(1+xw[j])/2*dx
    end
    if i<Nx
      xP[i+1,1]=xP[i,OrdPolyX+1]
    end
  end  

  xP[Nx,OrdPolyX+1]=L

  zP=zeros(Nx,Nz+1,OrdPolyX+1)
  for j=1:Nx
    for k=1:OrdPolyX+1
      zP[j,1,k]=Oro(xP[j,k],L,hHill)
      zP[j,Nz+1,k]=H
      dzLoc=(zP[j,Nz+1,k]-zP[j,1,k])/Nz
      for i=2:Nz
        zP[j,i,k]=zP[j,i-1,k]+dzLoc
      end
    end
  end
  zM=zeros(Nx,Nz,OrdPolyX+1)
  for i=1:Nz
    zM[:,i,:]=0.5*(zP[:,i,:]+zP[:,i+1,:])
  end
  dz=zeros(Nx,Nz,OrdPolyX+1)
  for i=1:Nz
    dz[:,i,:]=zP[:,i+1,:]-zP[:,i,:]
  end
  dzF=zeros(Nx,Nz+1,OrdPolyX+1)
  dzF[:,1,:]=dz[:,1,:]
  dzF[:,Nz+1,:]=dz[:,Nz,:]
  for i=2:Nz
    dzF[:,i,:]=0.5*(dz[:,i-1,:]+dz[:,i,:])
  end
# Metric
  ZZ=zeros(OrdPolyX+1,OrdPolyZ+1)
  X=zeros(Nx,Nz,OrdPolyX+1,OrdPolyZ+1,2)
  J=zeros(Nx,Nz,OrdPolyX+1,OrdPolyZ+1)
  dXdx=zeros(Nx,Nz,OrdPolyX+1,OrdPolyZ+1,2,2)
  dXdxI=zeros(Nx,Nz,OrdPolyX+1,OrdPolyZ+1,2,2)

  for i=1:Nz
    for j=1:Nx
      @views @. ZZ[:,1]=zP[j,i,:]
      @views @. ZZ[:,2]=zP[j,i+1,:]
      @views (XLoc,JLoc,dXdxLoc,dXdxILoc)=JacobiDG2(xP[j,:],ZZ,Dx,xw,Dz,zw)
      @views @. X[j,i,:,:,:] = XLoc
      @views @. J[j,i,:,:] = JLoc
      @views @. dXdx[j,i,:,:,:,:] = dXdxLoc
      @views @. dXdxI[j,i,:,:,:,:] = dXdxILoc
    end
  end

  u=rand(Nx,Nz,OrdPolyX+1,OrdPolyZ)
  @views @. u[:,2:Nz,:]=0.0
  #@views @. u[:,1,:]=0.0
  #@. u = 0.0
  Average!(u)
  wF=2.0*rand(Nx,Nz,OrdPolyX+1,OrdPolyZ+1)
  Average!(wF)
  DSSF!(wF,J)

  Rho=rand(Nx,Nz,OrdPolyX+1,OrdPolyZ)
  Rho .= 1.0
  Average!(Rho)
  K=zeros(Nx,Nz,OrdPolyX+1,OrdPolyZ)
# with Interpolation for higher order
  @views @. K[:,:,:,:] = 0.5 * (u[:,:,:,:]*u[:,:,:] +
    0.5 * (wF[:,:,:,1] * wF[:,:,:,1] + wF[:,:,:,2] * wF[:,:,:,2]))
  S=zeros(Nx,Nz,OrdPolyX+1,OrdPolyZ+1)
  stop

#%%%%%%%%%%%%%%%%%
# Part 1
wDotH1 = udwdx(u,wF,Rho,Dx,dXdxIF,JC)
uDotH1 = -wdwdx(wF,Dx,dXdxIF,JC)
uICH1=IntCell(uDotH1.*Rho.*u,JC,wX)
wIFH1=IntFace(wDotH1.*RhoF.*wF,JC,wX)
IH1=uICH1+wIFH1
@show uICH1,wIFH1,IH1

#%%%%%%%%%%%%%%%%%
# Part 2
# \rho u \nabla_S K + K \nabla_S \rho u
uDotH2 = dcdx(K,Dx,dXdxIC,JC)
RhoDotH2 = divdx(Rho.*u,Dx,dXdxIC,JC)
uICH2=IntCell(uDotH2.*Rho.*u,JC,wX)
RhoIH2=IntCell(RhoDotH2.*K,JC,wX)
IH2=uICH2+RhoIH2
@show uICH2,RhoIH2,IH2

#%%%%%%%%%%%%%%%%%%%
# Part 3
wDotV = Sdwdz(wF,RhoF,S,dXdxIF,JC)
uDotV = Sdudz(u,Rho,S,dXdxIF,JC)
RhoDotV = dRhoSdz(S,dXdxIF,JC)
uICV=IntCell(uDotV.*Rho.*u,JC,wX)
wIFV=IntFace(wDotV.*RhoF.*wF,JC,wX)
KICV=IntCell(RhoDotV.*K,JC,wX)
IV=uICV+wIFV+KICV
@show uICV,wIFV,KICV,IV

#%%%%%%%%%%%%%%%%%%%
# Part 1 + Part 2 + Part 3
uDot=dcdx(K,Dx,dXdxIC,JC)-wdwdx(wF,Dx,dXdxIF,JC)+Sdudz(u,Rho,S,dXdxIF,JC)
wDot=udwdx(u,wF,Rho,Dx,dXdxIF,JC)+Sdwdz(wF,RhoF,S,dXdxIF,JC)
@show wDotV[1:5,1,1]
@show size(wDotV)
RhoDot=divdx(Rho.*u,Dx,dXdxIC,JC)+dRhoSdz(S,dXdxIF,JC)
# @views @. wDot[:,1,:] = dXdxIF[:,1,:,2,1] * uDot[:,1,:] / dXdxIF[:,1,:,2,2]
# @views @. wDot[:,1,:] = 0.0
uIC=IntCell(uDot.*Rho.*u,JC,wX)
wIF=IntFace(wDot.*RhoF.*wF,JC,wX)
KIC=IntCell(RhoDot.*K,JC,wX)
I=uIC+wIF+KIC
@show uIC,wIF,KIC,I
end
