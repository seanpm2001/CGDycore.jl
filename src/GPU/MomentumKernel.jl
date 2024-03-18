@kernel inbounds = true function MomentumVectorInvariantCoriolisKernel!(F,@Const(U),@Const(D),@Const(dXdxI),
  @Const(JJ),@Const(X),@Const(MRho),@Const(M),@Const(Glob),CoriolisFun)

  I, J, iz   = @index(Local, NTuple)
  _,_,Iz,IF = @index(Global, NTuple)

  ColumnTilesDim = @uniform @groupsize()[3]
  N = @uniform @groupsize()[1]
  Nz = @uniform @ndrange()[3]
  NF = @uniform @ndrange()[4]

  ID = I + (J - 1) * N  
  ind = Glob[ID,IF]

  uCol = @localmem eltype(F) (N,N,ColumnTilesDim)
  vCol = @localmem eltype(F) (N,N,ColumnTilesDim)
  wCol = @localmem eltype(F) (N,N,ColumnTilesDim+1)
  tempuZ = @localmem eltype(F) (N,N,2,ColumnTilesDim+2)
  tempvZ = @localmem eltype(F) (N,N,2,ColumnTilesDim+2)
  tempwZ = @localmem eltype(F) (N,N,2,ColumnTilesDim+2)
  tempuZ1 = @localmem eltype(F) (N,N,2,ColumnTilesDim)
  tempuZ2 = @localmem eltype(F) (N,N,2,ColumnTilesDim)
  tempvZ1 = @localmem eltype(F) (N,N,2,ColumnTilesDim)
  tempvZ2 = @localmem eltype(F) (N,N,2,ColumnTilesDim)
  tempwZ1 = @localmem eltype(F) (N,N,2,ColumnTilesDim)
  tempwZ2 = @localmem eltype(F) (N,N,2,ColumnTilesDim)

  if Iz <= Nz
    uCol[I,J,iz] = U[Iz,ind,2]
    vCol[I,J,iz] = U[Iz,ind,3]
    wCol[I,J,iz+1] = U[Iz,ind,4]
    if iz == 1 && Iz == 1
      wCol[I,J,1] = -(dXdxI[3,1,1,ID,1,IF] * U[Iz,ind,2] +
        dXdxI[3,2,1,ID,1,IF] * U[Iz,ind,3]) / dXdxI[3,3,1,ID,1,IF]
    elseif iz == 1
      wCol[I,J,1] = U[Iz-1,ind,4]
    end   
  end 
  @synchronize 

  ID = I + (J - 1) * N  
  ind = Glob[ID,IF]
  if Iz <= Nz
    # Dz*(dx33*v - dx32*w)
    tempuZ[I,J,1,iz+1] = dXdxI[3,3,1,ID,Iz,IF] * vCol[I,J,iz] - dXdxI[3,2,1,ID,Iz,IF] * wCol[I,J,iz]
    tempuZ[I,J,2,iz+1] = dXdxI[3,3,2,ID,Iz,IF] * vCol[I,J,iz] - dXdxI[3,2,2,ID,Iz,IF] * wCol[I,J,iz+1]
    # Dz*(dx33*u - dx31*w)
    tempvZ[I,J,1,iz+1] = dXdxI[3,3,1,ID,Iz,IF] * uCol[I,J,iz] - dXdxI[3,1,1,ID,Iz,IF] * wCol[I,J,iz]
    tempvZ[I,J,2,iz+1] = dXdxI[3,3,2,ID,Iz,IF] * uCol[I,J,iz] - dXdxI[3,1,2,ID,Iz,IF] * wCol[I,J,iz+1]
    # Dz*(dx32*u - dx31*v)
    tempwZ[I,J,1,iz+1] = dXdxI[3,2,1,ID,Iz,IF] * uCol[I,J,iz] - dXdxI[3,1,1,ID,Iz,IF] * vCol[I,J,iz]
    tempwZ[I,J,2,iz+1] = dXdxI[3,2,2,ID,Iz,IF] * uCol[I,J,iz] - dXdxI[3,1,2,ID,Iz,IF] * vCol[I,J,iz] 
    if iz == 1 && Iz > 1
      um1 = U[Iz-1,ind,2]  
      vm1 = U[Iz-1,ind,3]  
      tempuZ[I,J,2,1] = dXdxI[3,3,2,ID,Iz-1,IF] * vm1 - dXdxI[3,2,2,ID,Iz-1,IF] * wCol[I,J,1]
      tempvZ[I,J,2,1] = dXdxI[3,3,2,ID,Iz-1,IF] * um1 - dXdxI[3,1,2,ID,Iz-1,IF] * wCol[I,J,1]
      tempwZ[I,J,2,1] = dXdxI[3,2,2,ID,Iz-1,IF] * um1 - dXdxI[3,1,2,ID,Iz-1,IF] * vm1 
    end  
    if iz == ColumnTilesDim && Iz < Nz
      up1 = U[Iz+1,ind,2]  
      vp1 = U[Iz+1,ind,3]  
      tempuZ[I,J,1,iz+2] = dXdxI[3,3,1,ID,Iz+1,IF] * vp1 - dXdxI[3,2,1,ID,Iz+1,IF] * wCol[I,J,iz+1]
      tempvZ[I,J,1,iz+2] = dXdxI[3,3,1,ID,Iz+1,IF] * up1 - dXdxI[3,1,1,ID,Iz+1,IF] * wCol[I,J,iz+1]
      tempwZ[I,J,1,iz+2] = dXdxI[3,2,1,ID,Iz+1,IF] * up1 - dXdxI[3,1,1,ID,Iz+1,IF] * vp1 
    end  
  end  
  @synchronize 

  ID = I + (J - 1) * N  
  ind = Glob[ID,IF]
  if Iz <= Nz

# uDot = - v*(Dx*(dx12*u - dx11*v) + Dy*(dx22*u - dx21*v) + Dz*(dx32*u - dx31*v))  
#        - w*(Dx*(dx13*u - dx11*w) + Dy*(dx23*u - dx21*w) + Dz*(dx33*u - dx31*w))
# vDot =   u*(Dx*(dx12*u - dx11*v) + Dy*(dx22*u - dx21*v) + Dz*(dx32*u - dx31*v))
#        - w*(Dx*(dx13*v - dx12*w) + Dy*(dx23*v - dx22*w) + Dz*(dx33*v - dx32*w))
# wDot =   u*(Dx*(dx13*u - dx11*w) + Dy*(dx23*u - dx21*w) + Dz*(dx33*u - dx31*w)) 
#          v*(Dx*(dx13*v - dx12*w) + Dy*(dx23*v - dx22*w) + Dz*(dx33*v - dx32*w))
#   U = Dx*(dx13*v - dx12*w) + Dy*(dx23*v - dx22*w) + Dz*(dx33*v - dx32*w)    
#   V = Dx*(dx13*u - dx11*w) + Dy*(dx23*u - dx21*w) + Dz*(dx33*u - dx31*w)
#   W = Dx*(dx12*u - dx11*v) + Dy*(dx22*u - dx21*v) + Dz*(dx32*u - dx31*v)
    tempuZ1[I,J,1,iz] = - dXdxI[1,2,1,ID,Iz,IF] * wCol[I,J,iz]
    tempuZ1[I,J,2,iz] = - dXdxI[1,2,2,ID,Iz,IF] * wCol[I,J,iz+1]
#   DerivativeX!(U,temp,D)
    tempuZ2[I,J,1,iz] = - dXdxI[2,2,1,ID,Iz,IF] * wCol[I,J,iz]
    tempuZ2[I,J,2,iz] = - dXdxI[2,2,2,ID,Iz,IF] * wCol[I,J,iz+1]
#   DerivativeY!(U,temp,D)
    tempvZ1[I,J,1,iz] = - dXdxI[1,1,1,ID,Iz,IF] * wCol[I,J,iz]
    tempvZ1[I,J,2,iz] = - dXdxI[1,1,2,ID,Iz,IF] * wCol[I,J,iz+1]
#   DerivativeX!(V,temp,D)
    tempvZ2[I,J,1,iz] = - dXdxI[2,1,1,ID,Iz,IF] * wCol[I,J,iz]
    tempvZ2[I,J,2,iz] = - dXdxI[2,1,2,ID,Iz,IF] * wCol[I,J,iz+1]
#   DerivativeY!(V,temp,D)
    tempwZ1[I,J,1,iz] = dXdxI[1,2,1,ID,Iz,IF] * uCol[I,J,iz] - dXdxI[1,1,1,ID,Iz,IF] * vCol[I,J,iz]
    tempwZ1[I,J,2,iz] = dXdxI[1,2,2,ID,Iz,IF] * uCol[I,J,iz] - dXdxI[1,1,2,ID,Iz,IF] * vCol[I,J,iz]
#   DerivativeX!(W,temp,D)
    tempwZ2[I,J,1,iz] = dXdxI[2,2,1,ID,Iz,IF] * uCol[I,J,iz] - dXdxI[2,1,1,ID,Iz,IF] * vCol[I,J,iz]
    tempwZ2[I,J,2,iz] = dXdxI[2,2,2,ID,Iz,IF] * uCol[I,J,iz] - dXdxI[2,1,2,ID,Iz,IF] * vCol[I,J,iz]
#   DerivativeY!(W,temp,D)
    
  end
  @synchronize 

  ID = I + (J - 1) * N  
  ind = Glob[ID,IF]
  if Iz <= Nz
    FU = eltype(F)(0)  
    FV = eltype(F)(0)  
    FW1 = eltype(F)(0)  
    FW2 = eltype(F)(0)  
    if Iz > 1
      FluxUZ = eltype(F)(0.5) * (tempuZ[I,J,1,iz+1] - tempuZ[I,J,2,iz])
      FluxVZ = eltype(F)(0.5) * (tempvZ[I,J,1,iz+1] - tempvZ[I,J,2,iz])
      FluxWZ = eltype(F)(0.5) * (tempwZ[I,J,1,iz+1] - tempwZ[I,J,2,iz])
      FU += (-vCol[I,J,iz] * FluxWZ - wCol[I,J,iz] * FluxVZ)
      FV += (uCol[I,J,iz] * FluxWZ - wCol[I,J,iz] * FluxUZ)
      FW1 += ( uCol[I,J,iz] * FluxVZ + vCol[I,J,iz] * FluxUZ)
    end
    if Iz < Nz
      FluxUZ = eltype(F)(0.5) * (tempuZ[I,J,1,iz+2] - tempuZ[I,J,2,iz+1])
      FluxVZ = eltype(F)(0.5) * (tempvZ[I,J,1,iz+2] - tempvZ[I,J,2,iz+1])
      FluxWZ = eltype(F)(0.5) * (tempwZ[I,J,1,iz+2] - tempwZ[I,J,2,iz+1])
      FU += (-vCol[I,J,iz] * FluxWZ - wCol[I,J,iz+1] * FluxVZ)
      FV += ( uCol[I,J,iz] * FluxWZ - wCol[I,J,iz+1] * FluxUZ)
      FW2 += ( uCol[I,J,iz] * FluxVZ + vCol[I,J,iz] * FluxUZ)
    end
    U1 = eltype(F)(0.5) * (tempuZ[I,J,2,iz+1] - tempuZ[I,J,1,iz+1])
    U2 = eltype(F)(0.5) * (tempuZ[I,J,2,iz+1] - tempuZ[I,J,1,iz+1])
    V1 = eltype(F)(0.5) * (tempvZ[I,J,2,iz+1] - tempvZ[I,J,1,iz+1])
    V2 = eltype(F)(0.5) * (tempvZ[I,J,2,iz+1] - tempvZ[I,J,1,iz+1])
    W1 = eltype(F)(0.5) * (tempwZ[I,J,2,iz+1] - tempwZ[I,J,1,iz+1])
    W2 = eltype(F)(0.5) * (tempwZ[I,J,2,iz+1] - tempwZ[I,J,1,iz+1])
    U1 += D[I,1] * tempuZ1[1,J,1,iz] + D[J,1] * tempuZ2[I,1,1,iz]
    U2 += D[I,1] * tempuZ1[1,J,2,iz] + D[J,1] * tempuZ2[I,1,2,iz]
    V1 += D[I,1] * tempvZ1[1,J,1,iz] + D[J,1] * tempvZ2[I,1,1,iz]
    V2 += D[I,1] * tempvZ1[1,J,2,iz] + D[J,1] * tempvZ2[I,1,2,iz]
    W1 += D[I,1] * tempwZ1[1,J,1,iz] + D[J,1] * tempwZ2[I,1,1,iz]
    W2 += D[I,1] * tempwZ1[1,J,2,iz] + D[J,1] * tempwZ2[I,1,2,iz]
    for k = 2 : N
      U1 += D[I,k] * tempuZ1[k,J,1,iz] + D[J,k] * tempuZ2[I,k,1,iz]
      U2 += D[I,k] * tempuZ1[k,J,2,iz] + D[J,k] * tempuZ2[I,k,2,iz]
      V1 += D[I,k] * tempvZ1[k,J,1,iz] + D[J,k] * tempvZ2[I,k,1,iz]
      V2 += D[I,k] * tempvZ1[k,J,2,iz] + D[J,k] * tempvZ2[I,k,2,iz]
      W1 += D[I,k] * tempwZ1[k,J,1,iz] + D[J,k] * tempwZ2[I,k,1,iz]
      W2 += D[I,k] * tempwZ1[k,J,2,iz] + D[J,k] * tempwZ2[I,k,2,iz]
    end  

#   Coriolis
    x = eltype(F)(0.5) * (X[ID,1,1,Iz,IF] + X[ID,2,1,Iz,IF])
    y = eltype(F)(0.5) * (X[ID,1,2,Iz,IF] + X[ID,2,2,Iz,IF])
    z = eltype(F)(0.5) * (X[ID,1,3,Iz,IF] + X[ID,2,3,Iz,IF])
    FuCor, FvCor, FwCor = CoriolisFun(x,y,z,uCol[I,J,iz],vCol[I,J,iz],wCol[I,J,iz],wCol[I,J,iz+1])
    FU += FuCor * (JJ[ID,1,Iz,IF] + JJ[ID,2,Iz,IF])
    FV += FvCor * (JJ[ID,1,Iz,IF] + JJ[ID,2,Iz,IF])
    FW1 += FwCor * JJ[ID,1,Iz,IF]
    FW2 += FwCor * JJ[ID,2,Iz,IF]

    @atomic :monotonic F[Iz,ind,2] += (-vCol[I,J,iz] * W1 - wCol[I,J,iz] * V1 -
      vCol[I,J,iz] * W2 - wCol[I,J,iz+1] * V2 + FU) / M[Iz,ind]
    @atomic :monotonic F[Iz,ind,3] += (uCol[I,J,iz] * W1 - wCol[I,J,iz] * U1 +
      uCol[I,J,iz] * W2 - wCol[I,J,iz+1] * U2 + FV) / M[Iz,ind]
    RhoCol = U[Iz,ind,1]  
    if Iz > 1  
      @atomic :monotonic F[Iz-1,ind,4] += RhoCol * (uCol[I,J,iz] * V1 + vCol[I,J,iz] * U1 + FW1) / MRho[Iz-1,ind]
    end
    if Iz < Nz
      @atomic :monotonic F[Iz,ind,4] += RhoCol * (uCol[I,J,iz] * V2 + vCol[I,J,iz] * U2 + FW2) / MRho[Iz,ind]
    end  
  end
end

@kernel inbounds = true function VerticalDiffusionMomentumKernel!(F,@Const(U),@Const(K),
  @Const(dXdxI),@Const(JJ),@Const(M),@Const(Glob))
  I, J, iz   = @index(Local, NTuple)
  _,_,Iz,IF = @index(Global, NTuple)

  ColumnTilesDim = @uniform @groupsize()[3]
  N = @uniform @groupsize()[1]
  Nz = @uniform @ndrange()[3]
  NF = @uniform @ndrange()[4]

  ID = I + (J - 1) * N
  ind = Glob[ID,IF]

  uCol = @localmem eltype(F) (N,N,ColumnTilesDim+1)
  vCol = @localmem eltype(F) (N,N,ColumnTilesDim+1)
  RhoCol = @localmem eltype(F) (N,N,ColumnTilesDim+1)

  if Iz <= Nz
    uCol[I,J,iz] = U[Iz,ind,2]
    vCol[I,J,iz] = U[Iz,ind,3]
    RhoCol[I,J,iz] = U[Iz,ind,1]
  end
  if iz == ColumnTilesDim || Iz == Nz
    Izp1 = min(Iz + 1,Nz)
    uCol[I,J,iz+1] = U[Izp1,ind,2]
    vCol[I,J,iz+1] = U[Izp1,ind,3]
    RhoCol[I,J,iz+1] = U[Izp1,ind,1]
  end
  @synchronize

  ID = I + (J - 1) * N  
  ind = Glob[ID,IF]

  if Iz < Nz
    fac = (RhoCol[I,J,iz] * K[ID,Iz,IF] + RhoCol[I,J,iz+1] * K[ID,Iz+1,IF]) / 
      (dXdxI[3,3,2,ID,Iz,IF] + dXdxI[3,3,1,ID,Iz+1,IF]) / ( JJ[ID,2,Iz,IF] + JJ[ID,1,Iz+1,IF])  
    facDiv1 = dXdxI[3,3,2,ID,Iz,IF] / M[Iz,ind] / RhoCol[I,J,iz]  
    facDiv2 = -dXdxI[3,3,2,ID,Iz+1,IF] / M[Iz+1,ind] / RhoCol[I,J,iz+1]  
    grad = fac * (uCol[I,J,iz+1] - uCol[I,J,iz]) *
    @atomic :monotonic F[Iz,ind,2] +=  facDiv1 * grad
    @atomic :monotonic F[Iz+1,ind,2] += facDiv2 * grad 
    grad = fac * (vCol[I,J,iz+1] - vCol[I,J,iz])
    @atomic :monotonic F[Iz,ind,3] +=  facDiv1 * grad
    @atomic :monotonic F[Iz+1,ind,3] += facDiv2 * grad 
  end  
end  


@kernel inbounds = true function SurfaceFluxMomentumKernel!(F,@Const(U),
  @Const(dXdxI),@Const(nS),@Const(CM),@Const(M),@Const(Glob))
  ID,IF = @index(Global, NTuple)

  NF = @uniform @ndrange()[2]

  if IF <= NF
    ind = Glob[ID,IF]  
    uCol = U[1,ind,2]
    vCol = U[1,ind,3]
    WS = -(dXdxI[3,1,1,ID,1,IF]* uCol +
        dXdxI[3,2,1,ID,1,IF] * vCol) /
        dXdxI[3,3,1,ID,1,IF]
    ww = 0.5 * (WS + U[1,ind,4])
    nU = nS[ID,1,IF] * uCol + nS[ID,2,IF] * vCol + nS[ID,3,IF] * ww
    uStar = sqrt((uCol - nS[ID,1,IF] * nU)^2 + (vCol - nS[ID,2,IF] * nU)^2 + (ww - nS[ID,3,IF] * nU)^2)
    @atomic :monotonic F[1,ind,2] += -CM[ID,IF] * uStar * (uCol - nU * nS[ID,1,IF]) / M[1,ind]
    @atomic :monotonic F[1,ind,3] += -CM[ID,IF] * uStar * (vCol - nU * nS[ID,2,IF]) / M[1,ind]
  end
end  
