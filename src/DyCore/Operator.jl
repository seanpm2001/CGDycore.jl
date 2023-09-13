function MomentumColumn!(FRhouC,FRhovC,FRhow,RhouC,RhovC,Rhow,RhoC,
  Fe,dXdxI,ThreadCache,::Val{:Conservative})
  @unpack TCacheC1, TCacheCol1, TCacheCol2, TCacheCol3 = ThreadCache
  Nz = size(RhouC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  uCon = TCacheCol1[Threads.threadid()]
  vCon = TCacheCol2[Threads.threadid()]
  wCon = TCacheCol3[Threads.threadid()]
  Temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC1[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @views @. uCon[:,:,1,iz] = -(dXdxI[1,1,1,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[1,2,1,:,:,iz] * RhovC[:,:,iz] + dXdxI[1,3,1,:,:,iz] * Rhow[:,:,iz])
    @views @. uCon[:,:,2,iz] = -(dXdxI[1,1,2,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[1,2,2,:,:,iz] * RhovC[:,:,iz] + dXdxI[1,3,2,:,:,iz] * Rhow[:,:,iz+1])
    @views @. Temp = RhouC[:,:,iz] * (uCon[:,:,1,iz] + uCon[:,:,2,iz]) / RhoC[:,:,iz]
    @views DerivativeX!(FRhouC[:,:,iz],Temp,D)
    @views @. Temp = RhovC[:,:,iz] * (uCon[:,:,1,iz] + uCon[:,:,2,iz]) / RhoC[:,:,iz]
    @views DerivativeX!(FRhovC[:,:,iz],Temp,D)

    @views @. vCon[:,:,1,iz] = -(dXdxI[2,1,1,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[2,2,1,:,:,iz] * RhovC[:,:,iz] + dXdxI[2,3,1,:,:,iz] * Rhow[:,:,iz])
    @views @. vCon[:,:,2,iz] = -(dXdxI[2,1,2,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[2,2,2,:,:,iz] * RhovC[:,:,iz] + dXdxI[2,3,2,:,:,iz] * Rhow[:,:,iz])
    @views @. Temp = RhouC[:,:,iz] * (vCon[:,:,1,iz] + vCon[:,:,2,iz]) / RhoC[:,:,iz]
    @views DerivativeY!(FRhouC[:,:,iz],Temp,D)
    @views @. Temp = RhovC[:,:,iz] * (vCon[:,:,1,iz] + vCon[:,:,2,iz]) / RhoC[:,:,iz]
    @views DerivativeY!(FRhovC[:,:,iz],Temp,D)

    @views @. wCon[:,:,1,iz] = -(dXdxI[3,1,1,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[3,2,1,:,:,iz] * RhovC[:,:,iz] + dXdxI[3,3,1,:,:,iz] * Rhow[:,:,iz])
    @views @. wCon[:,:,2,iz] = - (dXdxI[3,1,2,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[3,2,2,:,:,iz] * RhovC[:,:,iz] + dXdxI[3,3,2,:,:,iz] * Rhow[:,:,iz+1])

    @views @. FRhouC[:,:,iz] += RhouC[:,:,iz] / RhoC[:,:,iz] * (wCon[:,:,2,iz] - wCon[:,:,1,iz])
    @views @. FRhovC[:,:,iz] += RhovC[:,:,iz] / RhoC[:,:,iz] * (wCon[:,:,2,iz] - wCon[:,:,1,iz])
  end  

  @inbounds for iz = 2 : Nz
    @views @. FluxZ = 1/2 * (wCon[:,:,1,iz] * RhouC[:,:,iz] / RhoC[:,:,iz] - 
      wCon[:,:,2,iz-1] * RhouC[:,:,iz-1] / RhoC[:,:,iz-1])
    @views @. FRhouC[:,:,iz] += FluxZ
    @views @. FluxZ = 1/2 * (wCon[:,:,1,iz] * RhovC[:,:,iz] / RhoC[:,:,iz] - 
      wCon[:,:,2,iz-1] * RhovC[:,:,iz-1] / RhoC[:,:,iz-1])
    @views @. FRhovC[:,:,iz] += FluxZ
  end
  @inbounds for iz = 1 : Nz - 1
    @views @. FluxZ = 1/2 * (wCon[:,:,1,iz+1] * RhouC[:,:,iz+1] / RhoC[:,:,iz+1] - 
      wCon[:,:,2,iz] * RhouC[:,:,iz] / RhoC[:,:,iz])
    @views @. FRhouC[:,:,iz] += FluxZ
    @views @. FluxZ = 1/2 * (wCon[:,:,1,iz+1] * RhovC[:,:,iz+1] / RhoC[:,:,iz+1] - 
      wCon[:,:,2,iz] * RhovC[:,:,iz] / RhoC[:,:,iz])
    @views @. FRhovC[:,:,iz] += FluxZ
  end

  for iz = 2 : Nz
    @views @. Temp = 2 * Rhow[:,:,iz] * (uCon[:,:,2,iz-1] + uCon[:,:,1,iz]) / 
      (RhoC[:,:,iz-1] + RhoC[:,:,iz])
    @views DerivativeX!(FRhow[:,:,iz],Temp,D)
    @views @. Temp = 2 * Rhow[:,:,iz] * (vCon[:,:,2,iz-1] + vCon[:,:,1,iz]) / 
      (RhoC[:,:,iz-1] + RhoC[:,:,iz])
    @views DerivativeY!(FRhow[:,:,iz],Temp,D)
  end

  for iz = 2 : Nz
    @views @. FRhow[:,:,iz] += 1/2 * ((wCon[:,:,1,iz] * Rhow[:,:,iz] + wCon[:,:,2,iz] * Rhow[:,:,iz+1]) / RhoC[:,:,iz] -
      (wCon[:,:,1,iz-1] * Rhow[:,:,iz-1] + wCon[:,:,2,iz-1] * Rhow[:,:,iz]) / RhoC[:,:,iz-1])
  end    

end  

function MomentumWColumn!(FRhow,RhouC,RhovC,Rhow,RhoC,
  Fe,dXdxI,ThreadCache,::Val{:Conservative})
  @unpack TCacheC1, TCacheCol1, TCacheCol2, TCacheCol3 = ThreadCache
  Nz = size(RhouC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  uCon = TCacheCol1[Threads.threadid()]
  vCon = TCacheCol2[Threads.threadid()]
  wCon = TCacheCol3[Threads.threadid()]
  Temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC1[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @views @. uCon[:,:,1,iz] = -(dXdxI[1,1,1,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[1,2,1,:,:,iz] * RhovC[:,:,iz] + dXdxI[1,3,1,:,:,iz] * Rhow[:,:,iz])
    @views @. uCon[:,:,2,iz] = -(dXdxI[1,1,2,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[1,2,2,:,:,iz] * RhovC[:,:,iz] + dXdxI[1,3,2,:,:,iz] * Rhow[:,:,iz+1])

    @views @. vCon[:,:,1,iz] = -(dXdxI[2,1,1,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[2,2,1,:,:,iz] * RhovC[:,:,iz] + dXdxI[2,3,1,:,:,iz] * Rhow[:,:,iz])
    @views @. vCon[:,:,2,iz] = -(dXdxI[2,1,2,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[2,2,2,:,:,iz] * RhovC[:,:,iz] + dXdxI[2,3,2,:,:,iz] * Rhow[:,:,iz])

    @views @. wCon[:,:,1,iz] = -(dXdxI[3,1,1,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[3,2,1,:,:,iz] * RhovC[:,:,iz] + dXdxI[3,3,1,:,:,iz] * Rhow[:,:,iz])
    @views @. wCon[:,:,2,iz] = - (dXdxI[3,1,2,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[3,2,2,:,:,iz] * RhovC[:,:,iz] + dXdxI[3,3,2,:,:,iz] * Rhow[:,:,iz+1])

  end  

  for iz = 2 : Nz
    @views @. Temp = 2 * Rhow[:,:,iz] * (uCon[:,:,2,iz-1] + uCon[:,:,1,iz]) / 
      (RhoC[:,:,iz-1] + RhoC[:,:,iz])
    @views DerivativeX!(FRhow[:,:,iz],Temp,D)
    @views @. Temp = 2 * Rhow[:,:,iz] * (vCon[:,:,2,iz-1] + vCon[:,:,1,iz]) / 
      (RhoC[:,:,iz-1] + RhoC[:,:,iz])
    @views DerivativeY!(FRhow[:,:,iz],Temp,D)
  end

  for iz = 2 : Nz
    @views @. FRhow[:,:,iz] += 1/2 * ((wCon[:,:,1,iz] * Rhow[:,:,iz] + wCon[:,:,2,iz] * Rhow[:,:,iz+1]) / RhoC[:,:,iz] -
      (wCon[:,:,1,iz-1] * Rhow[:,:,iz-1] + wCon[:,:,2,iz-1] * Rhow[:,:,iz]) / RhoC[:,:,iz-1])
  end    

end  

function MomentumColumn!(FuC,FvC,Fw,uC,vC,w,RhoC,
  Fe,dXdxI,ThreadCache,::Val{:Advection})
  @unpack TCacheC1, TCacheCol1, TCacheCol2, TCacheCol3 = ThreadCache
  Nz = size(uC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  uCon = TCacheCol1[Threads.threadid()]
  vCon = TCacheCol2[Threads.threadid()]
  wCon = TCacheCol3[Threads.threadid()]
  Der = TCacheC1[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @views @. uCon[:,:,1,iz] = -RhoC[:,:,iz] * (dXdxI[1,1,1,:,:,iz] * uC[:,:,iz] +
      dXdxI[1,2,1,:,:,iz] * vC[:,:,iz] + dXdxI[1,3,1,:,:,iz] * w[:,:,iz])
    @views @. uCon[:,:,2,iz] = -RhoC[:,:,iz] * (dXdxI[1,1,2,:,:,iz] * uC[:,:,iz] +
      dXdxI[1,2,2,:,:,iz] * vC[:,:,iz] + dXdxI[1,3,2,:,:,iz] * w[:,:,iz+1])
    @. Der = 0
    @views DerivativeX!(Der,uC[:,:,iz],D)
    @views @. FuC[:,:,iz] += (uCon[:,:,1,iz] + uCon[:,:,2,iz]) * Der 
    @. Der = 0
    @views DerivativeX!(Der,vC[:,:,iz],D)
    @views @. FvC[:,:,iz] += (uCon[:,:,1,iz] + uCon[:,:,2,iz]) * Der 

    @views @. vCon[:,:,1,iz] = -RhoC[:,:,iz] * (dXdxI[2,1,1,:,:,iz] * uC[:,:,iz] +
      dXdxI[2,2,1,:,:,iz] * vC[:,:,iz] + dXdxI[2,3,1,:,:,iz] * w[:,:,iz])
    @views @. vCon[:,:,2,iz] = -RhoC[:,:,iz] * (dXdxI[2,1,2,:,:,iz] * uC[:,:,iz] +
      dXdxI[2,2,2,:,:,iz] * vC[:,:,iz] + dXdxI[2,3,2,:,:,iz] * w[:,:,iz+1])

    @. Der = 0
    @views DerivativeY!(Der,uC[:,:,iz],D)
    @views @. FuC[:,:,iz] += (vCon[:,:,1,iz] + vCon[:,:,2,iz]) * Der 
    @. Der = 0
    @views DerivativeY!(Der,vC[:,:,iz],D)
    @views @. FvC[:,:,iz] += (vCon[:,:,1,iz] + vCon[:,:,2,iz]) * Der 

    @views @. wCon[:,:,1,iz] = -RhoC[:,:,iz] * (dXdxI[3,1,1,:,:,iz] * uC[:,:,iz] +
      dXdxI[3,2,1,:,:,iz] * vC[:,:,iz] + dXdxI[3,3,1,:,:,iz] * w[:,:,iz])
    @views @. wCon[:,:,2,iz] = -RhoC[:,:,iz] * (dXdxI[3,1,2,:,:,iz] * uC[:,:,iz] +
      dXdxI[3,2,2,:,:,iz] * vC[:,:,iz] + dXdxI[3,3,2,:,:,iz] * w[:,:,iz+1])
  end

  for iz = 2 : Nz
    @. Der = 0
    @views DerivativeX!(Der,w[:,:,iz],D)
    @views @. Fw[:,:,iz] += (uCon[:,:,2,iz-1] + uCon[:,:,1,iz]) * Der 
    @. Der = 0
    @views DerivativeY!(Der,w[:,:,iz],D)
    @views @. Fw[:,:,iz] += (vCon[:,:,2,iz-1] + vCon[:,:,1,iz]) * Der 

    @views @. Der = 1/2 * (uC[:,:,iz] - uC[:,:,iz-1])  
    @views @. FuC[:,:,iz-1] += (wCon[:,:,2,iz-1] + wCon[:,:,1,iz]) * Der
    @views @. FuC[:,:,iz] += (wCon[:,:,2,iz-1] + wCon[:,:,1,iz]) * Der
    @views @. Der = 1/2 * (vC[:,:,iz] - vC[:,:,iz-1])  
    @views @. FvC[:,:,iz-1] += (wCon[:,:,2,iz-1] + wCon[:,:,1,iz]) * Der
    @views @. FvC[:,:,iz] += (wCon[:,:,2,iz-1] + wCon[:,:,1,iz]) * Der
  end  

  for iz = 1 : Nz
    @views @. Der = 1/2 * (w[:,:,iz+1] - w[:,:,iz])  
    @views @. Fw[:,:,iz+1] += wCon[:,:,2,iz] *  Der
    @views @. Fw[:,:,iz] += wCon[:,:,1,iz] * Der
  end  
end

function CoriolisColumn!(FuC,FvC,uC,vC,RhoC,Fe,X,J,Phys)
  Nz = size(FuC,3)
  N = size(FuC,1)

  @inbounds for iz = 1 : Nz 
    @inbounds for i = 1 : N
      @inbounds for j = 1 : N
        x = 1/2 * (X[i,j,1,1,iz] + X[i,j,2,1,iz])  
        y = 1/2 * (X[i,j,1,2,iz] + X[i,j,2,2,iz])  
        z = 1/2 * (X[i,j,1,3,iz] + X[i,j,2,3,iz])  
        r = sqrt(x^2 + y^2 + z^2);
        sinlat = z/r
        W = -2 * Phys.Omega * sinlat * (J[i,j,1,iz] + J[i,j,2,iz])
        FuC[i,j,iz] -= RhoC[i,j,iz] * vC[i,j,iz] * W
        FvC[i,j,iz] += RhoC[i,j,iz] * uC[i,j,iz] * W
      end 
    end 
  end 
end

function CoriolisColumn!(FuC,FvC,RhouC,RhovC,Fe,X,J,Omega)
  Nz = size(FuC,3)
  OrdPoly = Fe.OrdPoly

  @inbounds for iz = 1 : Nz 
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        x = 1/2 * (X[i,j,1,1,iz] + X[i,j,2,1,iz])  
        y = 1/2 * (X[i,j,1,2,iz] + X[i,j,2,2,iz])  
        z = 1/2 * (X[i,j,1,3,iz] + X[i,j,2,3,iz])  
#       lon,lat,r = cart2sphere(x,y,z)
        r = sqrt(x^2 + y^2 + z^2);
        sinlat = z/r
        W = -2 * Omega * sinlat * (J[i,j,1,iz] + J[i,j,2,iz])
        FuC[i,j,iz] -= RhovC[i,j,iz] * W
        FvC[i,j,iz] += RhouC[i,j,iz] * W
      end 
    end 
  end 
end

function MomentumColumn!(FuC,FvC,Fw,uC,vC,w,RhoC,Fe,dXdxI,ThreadCache,::Val{:VectorInvariantDeep})
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4, TCacheCol1, TCacheCol2, 
    TCacheCol3, TCacheCCC1, TCacheCCC2, TCacheCCC3, TCacheCCC4 = ThreadCache
  Nz = size(FuC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  @views tempuZ = TCacheCol1[Threads.threadid()]
  @views tempvZ = TCacheCol2[Threads.threadid()]
  @views tempwZ = TCacheCol3[Threads.threadid()]
  @views U = TCacheCCC1[Threads.threadid()]
  @views V = TCacheCCC2[Threads.threadid()]
  @views W = TCacheCCC3[Threads.threadid()]
  @views temp = TCacheCCC4[Threads.threadid()]

  @views FluxUZ = TCacheC2[Threads.threadid()]
  @views FluxVZ = TCacheC3[Threads.threadid()]
  @views FluxWZ = TCacheC4[Threads.threadid()]

  
  @inbounds for iz = 1 : Nz 
    # Dz*(dx33*v - dx32*w)
    @views @. tempuZ[:,:,1,iz] = dXdxI[3,3,1,:,:,iz] * vC[:,:,iz] - dXdxI[3,2,1,:,:,iz] * w[:,:,iz]
    @views @. tempuZ[:,:,2,iz] = dXdxI[3,3,2,:,:,iz] * vC[:,:,iz] - dXdxI[3,2,2,:,:,iz] * w[:,:,iz+1]
    # Dz*(dx33*u - dx31*w)
    @views @. tempvZ[:,:,1,iz] = dXdxI[3,3,1,:,:,iz] * uC[:,:,iz] - dXdxI[3,1,1,:,:,iz] * w[:,:,iz]
    @views @. tempvZ[:,:,2,iz] = dXdxI[3,3,2,:,:,iz] * uC[:,:,iz] - dXdxI[3,1,2,:,:,iz] * w[:,:,iz+1]
    # Dz*(dx32*u - dx31*v)
    @views @. tempwZ[:,:,1,iz] = dXdxI[3,2,1,:,:,iz] * uC[:,:,iz] - dXdxI[3,1,1,:,:,iz] * vC[:,:,iz]
    @views @. tempwZ[:,:,2,iz] = dXdxI[3,2,2,:,:,iz] * uC[:,:,iz] - dXdxI[3,1,2,:,:,iz] * vC[:,:,iz] 
  end  

  @inbounds for iz = 2 : Nz 
    @views @. FluxUZ = 1/2 * (tempuZ[:,:,1,iz] - tempuZ[:,:,2,iz-1])
    @views @. FluxVZ = 1/2 * (tempvZ[:,:,1,iz] - tempvZ[:,:,2,iz-1])
    @views @. FluxWZ = 1/2 * (tempwZ[:,:,1,iz] - tempwZ[:,:,2,iz-1])
    @views @. FuC[:,:,iz] += RhoC[:,:,iz] * (-vC[:,:,iz] * FluxWZ - w[:,:,iz] * FluxVZ)
    @views @. FvC[:,:,iz] += RhoC[:,:,iz] * (uC[:,:,iz] * FluxWZ - w[:,:,iz] * FluxUZ)
    @views @. Fw[:,:,iz] += RhoC[:,:,iz] * ( uC[:,:,iz] * FluxVZ + vC[:,:,iz] * FluxUZ)
  end
  @inbounds for iz = 1 : Nz - 1 
    @views @. FluxUZ = 1/2 * (tempuZ[:,:,1,iz+1] - tempuZ[:,:,2,iz])
    @views @. FluxVZ = 1/2 * (tempvZ[:,:,1,iz+1] - tempvZ[:,:,2,iz])
    @views @. FluxWZ = 1/2 * (tempwZ[:,:,1,iz+1] - tempwZ[:,:,2,iz])
    @views @. FuC[:,:,iz] += RhoC[:,:,iz] * (-vC[:,:,iz] * FluxWZ - w[:,:,iz+1] * FluxVZ)
    @views @. FvC[:,:,iz] += RhoC[:,:,iz] * ( uC[:,:,iz] * FluxWZ - w[:,:,iz+1] * FluxUZ)
    @views @. Fw[:,:,iz+1] += RhoC[:,:,iz] * (uC[:,:,iz] * FluxVZ + vC[:,:,iz] * FluxUZ)
  end    
  @inbounds for iz = 1 : Nz 
    @. U = 0
    @. V = 0
    @. W = 0

# uDot = - v*(Dx*(dx12*u - dx11*v) + Dy*(dx22*u - dx21*v) + Dz*(dx32*u - dx31*v))  
#        - w*(Dx*(dx13*u - dx11*w) + Dy*(dx23*u - dx21*w) + Dz*(dx33*u - dx31*w))
# vDot =   u*(Dx*(dx12*u - dx11*v) + Dy*(dx22*u - dx21*v) + Dz*(dx32*u - dx31*v))
#        - w*(Dx*(dx13*v - dx12*w) + Dy*(dx23*v - dx22*w) + Dz*(dx33*v - dx32*w))
# wDot =   u*(Dx*(dx13*u - dx11*w) + Dy*(dx23*u - dx21*w) + Dz*(dx33*u - dx31*w)) 
#          v*(Dx*(dx13*v - dx12*w) + Dy*(dx23*v - dx22*w) + Dz*(dx33*v - dx32*w))
#   U = Dx*(dx13*v - dx12*w) + Dy*(dx23*v - dx22*w) + Dz*(dx33*v - dx32*w)    
#   V = Dx*(dx13*u - dx11*w) + Dy*(dx23*u - dx21*w) + Dz*(dx33*u - dx31*w)
#   W = Dx*(dx12*u - dx11*v) + Dy*(dx22*u - dx21*v) + Dz*(dx32*u - dx31*v)
    @views @. temp[:,:,1] = dXdxI[1,3,1,:,:,iz] * vC[:,:,iz] - dXdxI[1,2,1,:,:,iz] * w[:,:,iz]
    @views @. temp[:,:,2] = dXdxI[1,3,2,:,:,iz] * vC[:,:,iz] - dXdxI[1,2,2,:,:,iz] * w[:,:,iz+1]
    DerivativeX!(U,temp,D)
    @views @. temp[:,:,1] = dXdxI[2,3,1,:,:,iz] * vC[:,:,iz] - dXdxI[2,2,1,:,:,iz] * w[:,:,iz]
    @views @. temp[:,:,2] = dXdxI[2,3,2,:,:,iz] * vC[:,:,iz] - dXdxI[2,2,2,:,:,iz] * w[:,:,iz+1]
    DerivativeY!(U,temp,D)
    @views @. temp[:,:,1] = dXdxI[1,3,1,:,:,iz] * uC[:,:,iz] - dXdxI[1,1,1,:,:,iz] * w[:,:,iz]
    @views @. temp[:,:,2] = dXdxI[1,3,2,:,:,iz] * uC[:,:,iz] - dXdxI[1,1,2,:,:,iz] * w[:,:,iz+1]
    DerivativeX!(V,temp,D)
    @views @. temp[:,:,1] = dXdxI[2,3,1,:,:,iz] * uC[:,:,iz] - dXdxI[2,1,1,:,:,iz] * w[:,:,iz]
    @views @. temp[:,:,2] = dXdxI[2,3,2,:,:,iz] * uC[:,:,iz] - dXdxI[2,1,2,:,:,iz] * w[:,:,iz+1]
    DerivativeY!(V,temp,D)
    @views @. temp[:,:,1] = dXdxI[1,2,1,:,:,iz] * uC[:,:,iz] - dXdxI[1,1,1,:,:,iz] * vC[:,:,iz]
    @views @. temp[:,:,2] = dXdxI[1,2,2,:,:,iz] * uC[:,:,iz] - dXdxI[1,1,2,:,:,iz] * vC[:,:,iz]
    DerivativeX!(W,temp,D)
    @views @. temp[:,:,1] = dXdxI[2,2,1,:,:,iz] * uC[:,:,iz] - dXdxI[2,1,1,:,:,iz] * vC[:,:,iz]
    @views @. temp[:,:,2] = dXdxI[2,2,2,:,:,iz] * uC[:,:,iz] - dXdxI[2,1,2,:,:,iz] * vC[:,:,iz]
    DerivativeY!(W,temp,D)

    @views @. U[:,:,1] += 1/2 * (tempuZ[:,:,2,iz] - tempuZ[:,:,1,iz])
    @views @. U[:,:,2] += 1/2 * (tempuZ[:,:,2,iz] - tempuZ[:,:,1,iz])
    @views @. V[:,:,1] += 1/2 * (tempvZ[:,:,2,iz] - tempvZ[:,:,1,iz])
    @views @. V[:,:,2] += 1/2 * (tempvZ[:,:,2,iz] - tempvZ[:,:,1,iz])
    @views @. W[:,:,1] += 1/2 * (tempwZ[:,:,2,iz] - tempwZ[:,:,1,iz])
    @views @. W[:,:,2] += 1/2 * (tempwZ[:,:,2,iz] - tempwZ[:,:,1,iz])

    @views @. FuC[:,:,iz] += RhoC[:,:,iz] * (-vC[:,:,iz] * W[:,:,1] - w[:,:,iz] * V[:,:,1] -
      vC[:,:,iz] * W[:,:,2] - w[:,:,iz+1] * V[:,:,2]) 
    @views @. FvC[:,:,iz] += RhoC[:,:,iz] * (uC[:,:,iz] * W[:,:,1] - w[:,:,iz] * U[:,:,1] +
      uC[:,:,iz] * W[:,:,2] - w[:,:,iz+1] * U[:,:,2]) 
    @views @. Fw[:,:,iz] += RhoC[:,:,iz] * (uC[:,:,iz] * V[:,:,1] + vC[:,:,iz] * U[:,:,1])
    @views @. Fw[:,:,iz+1] += RhoC[:,:,iz] * (uC[:,:,iz] * V[:,:,2] + vC[:,:,iz] * U[:,:,2])
  end 
end

function MomentumColumn!(FuC,FvC,Fw,uC,vC,w,RhoC,Fe,dXdxI,ThreadCache,::Val{:VectorInvariant})
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4, TCacheCol1, TCacheCol2, 
    TCacheCol3, TCacheCCC1, TCacheCCC2, TCacheCCC3, TCacheCCC4 = ThreadCache
  Nz = size(FuC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  @views tempuZ = TCacheCol1[Threads.threadid()]
  @views tempvZ = TCacheCol2[Threads.threadid()]
  @views tempwZ = TCacheCol3[Threads.threadid()]
  @views U = TCacheCCC1[Threads.threadid()]
  @views V = TCacheCCC2[Threads.threadid()]
  @views W = TCacheCCC3[Threads.threadid()]
  @views temp = TCacheCCC4[Threads.threadid()]

  @views FluxUZ = TCacheC2[Threads.threadid()]
  @views FluxVZ = TCacheC3[Threads.threadid()]
  @views FluxWZ = TCacheC4[Threads.threadid()]

  
# @views ax!(dXdxI[:,:,1,:,3,3],vC[:,:,:],tempuZ[:,:,1,:])
# @views axpy!(-dXdxI[:,:,1,:,3,2],w[:,:,1:Nz],tempuZ[:,:,1,:])
# @views ax!(dXdxI[:,:,2,:,3,3],vC[:,:,:],tempuZ[:,:,2,:])
# @views axpy!(-dXdxI[:,:,2,:,3,2],w[:,:,2:Nz-1],tempuZ[:,:,2,:])
  @inbounds for iz = 1 : Nz 
    # Dz*(dx33*v - dx32*w)
    @views @. tempuZ[:,:,1,iz] = dXdxI[3,3,1,:,:,iz] * vC[:,:,iz] - dXdxI[3,2,1,:,:,iz] * w[:,:,iz]
    @views @. tempuZ[:,:,2,iz] = dXdxI[3,3,2,:,:,iz] * vC[:,:,iz] - dXdxI[3,2,2,:,:,iz] * w[:,:,iz+1]
    # Dz*(dx33*u - dx31*w)
    @views @. tempvZ[:,:,1,iz] = dXdxI[3,3,1,:,:,iz] * uC[:,:,iz] - dXdxI[3,1,1,:,:,iz] * w[:,:,iz]
    @views @. tempvZ[:,:,2,iz] = dXdxI[3,3,2,:,:,iz] * uC[:,:,iz] - dXdxI[3,1,2,:,:,iz] * w[:,:,iz+1]
    # Dz*(dx32*u - dx31*v)
    @views @. tempwZ[:,:,1,iz] = dXdxI[3,2,1,:,:,iz] * uC[:,:,iz] - dXdxI[3,1,1,:,:,iz] * vC[:,:,iz]
    @views @. tempwZ[:,:,2,iz] = dXdxI[3,2,2,:,:,iz] * uC[:,:,iz] - dXdxI[3,1,2,:,:,iz] * vC[:,:,iz] 
  end  

  @inbounds for iz = 2 : Nz 
    @views @. FluxUZ = 1/2 * (tempuZ[:,:,1,iz] - tempuZ[:,:,2,iz-1])
    @views @. FluxVZ = 1/2 * (tempvZ[:,:,1,iz] - tempvZ[:,:,2,iz-1])
    @views @. FluxWZ = 1/2 * (tempwZ[:,:,1,iz] - tempwZ[:,:,2,iz-1])
    @views @. FuC[:,:,iz] += RhoC[:,:,iz] * (-vC[:,:,iz] * FluxWZ - w[:,:,iz] * FluxVZ)
    @views @. FvC[:,:,iz] += RhoC[:,:,iz] * (uC[:,:,iz] * FluxWZ - w[:,:,iz] * FluxUZ)
    @views @. Fw[:,:,iz] += RhoC[:,:,iz] * ( uC[:,:,iz] * FluxVZ + vC[:,:,iz] * FluxUZ)
  end
  @inbounds for iz = 1 : Nz - 1 
    @views @. FluxUZ = 1/2 * (tempuZ[:,:,1,iz+1] - tempuZ[:,:,2,iz])
    @views @. FluxVZ = 1/2 * (tempvZ[:,:,1,iz+1] - tempvZ[:,:,2,iz])
    @views @. FluxWZ = 1/2 * (tempwZ[:,:,1,iz+1] - tempwZ[:,:,2,iz])
    @views @. FuC[:,:,iz] += RhoC[:,:,iz] * (-vC[:,:,iz] * FluxWZ - w[:,:,iz+1] * FluxVZ)
    @views @. FvC[:,:,iz] += RhoC[:,:,iz] * ( uC[:,:,iz] * FluxWZ - w[:,:,iz+1] * FluxUZ)
    @views @. Fw[:,:,iz+1] += RhoC[:,:,iz] * (uC[:,:,iz] * FluxVZ + vC[:,:,iz] * FluxUZ)
  end    
  @inbounds for iz = 1 : Nz 
    @. U = 0
    @. V = 0
    @. W = 0

# uDot = - v*(Dx*(dx12*u - dx11*v) + Dy*(dx22*u - dx21*v) + Dz*(dx32*u - dx31*v))  
#        - w*(Dx*(dx13*u - dx11*w) + Dy*(dx23*u - dx21*w) + Dz*(dx33*u - dx31*w))
# vDot =   u*(Dx*(dx12*u - dx11*v) + Dy*(dx22*u - dx21*v) + Dz*(dx32*u - dx31*v))
#        - w*(Dx*(dx13*v - dx12*w) + Dy*(dx23*v - dx22*w) + Dz*(dx33*v - dx32*w))
# wDot =   u*(Dx*(dx13*u - dx11*w) + Dy*(dx23*u - dx21*w) + Dz*(dx33*u - dx31*w)) 
#          v*(Dx*(dx13*v - dx12*w) + Dy*(dx23*v - dx22*w) + Dz*(dx33*v - dx32*w))
#   U = Dx*(dx13*v - dx12*w) + Dy*(dx23*v - dx22*w) + Dz*(dx33*v - dx32*w)    
#   V = Dx*(dx13*u - dx11*w) + Dy*(dx23*u - dx21*w) + Dz*(dx33*u - dx31*w)
#   W = Dx*(dx12*u - dx11*v) + Dy*(dx22*u - dx21*v) + Dz*(dx32*u - dx31*v)
    @views @. temp[:,:,1] = - dXdxI[1,2,1,:,:,iz] * w[:,:,iz]
    @views @. temp[:,:,2] = - dXdxI[1,2,2,:,:,iz] * w[:,:,iz+1]
    DerivativeX!(U,temp,D)
    @views @. temp[:,:,1] = - dXdxI[2,2,1,:,:,iz] * w[:,:,iz]
    @views @. temp[:,:,2] = - dXdxI[2,2,2,:,:,iz] * w[:,:,iz+1]
    DerivativeY!(U,temp,D)
    @views @. temp[:,:,1] = - dXdxI[1,1,1,:,:,iz] * w[:,:,iz]
    @views @. temp[:,:,2] = - dXdxI[1,1,2,:,:,iz] * w[:,:,iz+1]
    DerivativeX!(V,temp,D)
    @views @. temp[:,:,1] = - dXdxI[2,1,1,:,:,iz] * w[:,:,iz]
    @views @. temp[:,:,2] = - dXdxI[2,1,2,:,:,iz] * w[:,:,iz+1]
    DerivativeY!(V,temp,D)
    @views @. temp[:,:,1] = dXdxI[1,2,1,:,:,iz] * uC[:,:,iz] - dXdxI[1,1,1,:,:,iz] * vC[:,:,iz]
    @views @. temp[:,:,2] = dXdxI[1,2,2,:,:,iz] * uC[:,:,iz] - dXdxI[1,1,2,:,:,iz] * vC[:,:,iz]
    DerivativeX!(W,temp,D)
    @views @. temp[:,:,1] = dXdxI[2,2,1,:,:,iz] * uC[:,:,iz] - dXdxI[2,1,1,:,:,iz] * vC[:,:,iz]
    @views @. temp[:,:,2] = dXdxI[2,2,2,:,:,iz] * uC[:,:,iz] - dXdxI[2,1,2,:,:,iz] * vC[:,:,iz]
    DerivativeY!(W,temp,D)

    @views @. U[:,:,1] += 1/2 * (tempuZ[:,:,2,iz] - tempuZ[:,:,1,iz])
    @views @. U[:,:,2] += 1/2 * (tempuZ[:,:,2,iz] - tempuZ[:,:,1,iz])
    @views @. V[:,:,1] += 1/2 * (tempvZ[:,:,2,iz] - tempvZ[:,:,1,iz])
    @views @. V[:,:,2] += 1/2 * (tempvZ[:,:,2,iz] - tempvZ[:,:,1,iz])
    @views @. W[:,:,1] += 1/2 * (tempwZ[:,:,2,iz] - tempwZ[:,:,1,iz])
    @views @. W[:,:,2] += 1/2 * (tempwZ[:,:,2,iz] - tempwZ[:,:,1,iz])

    @views @. FuC[:,:,iz] += RhoC[:,:,iz] * (-vC[:,:,iz] * W[:,:,1] - w[:,:,iz] * V[:,:,1] -
      vC[:,:,iz] * W[:,:,2] - w[:,:,iz+1] * V[:,:,2]) 
    @views @. FvC[:,:,iz] += RhoC[:,:,iz] * (uC[:,:,iz] * W[:,:,1] - w[:,:,iz] * U[:,:,1] +
      uC[:,:,iz] * W[:,:,2] - w[:,:,iz+1] * U[:,:,2]) 
    @views @. Fw[:,:,iz] += RhoC[:,:,iz] * (uC[:,:,iz] * V[:,:,1] + vC[:,:,iz] * U[:,:,1])
    @views @. Fw[:,:,iz+1] += RhoC[:,:,iz] * (uC[:,:,iz] * V[:,:,2] + vC[:,:,iz] * U[:,:,2])
  end 
end

function RhoGradColumn!(FuC,FvC,Fw,pC,RhoC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2 = ThreadCache
  Nz = size(FuC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  @views DXpC = TCacheC1[Threads.threadid()]
  @views DYpC = TCacheC2[Threads.threadid()]
  @views GradZ = TCacheC1[Threads.threadid()]
  @views FluxZ = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz 
    @. DXpC = 0
    @views DerivativeX!(DXpC,pC[:,:,iz],D)
    @. DYpC = 0
    @views DerivativeY!(DYpC,pC[:,:,iz],D)
    @views @. FuC[:,:,iz] -= RhoC[:,:,iz] * 
      ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DXpC + 
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DYpC)
    @views @. FvC[:,:,iz] -=  RhoC[:,:,iz] *
      ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DXpC + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DYpC)
    @views @. Fw[:,:,iz] -= RhoC[:,:,iz] * (dXdxI[1,3,1,:,:,iz] * DXpC + dXdxI[2,3,1,:,:,iz] * DYpC)
    @views @. Fw[:,:,iz+1] -= RhoC[:,:,iz] * (dXdxI[1,3,2,:,:,iz] * DXpC + dXdxI[2,3,2,:,:,iz] * DYpC)
  end  
  @inbounds for iz = 2 : Nz 
    @views @. GradZ = 1/2 * (pC[:,:,iz] - pC[:,:,iz-1]) * RhoC[:,:,iz] 
    @views @. FluxZ = GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. FuC[:,:,iz] -= FluxZ 
    @views @. FluxZ = GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. FvC[:,:,iz] -= FluxZ 
    @views @. FluxZ = GradZ * dXdxI[3,3,1,:,:,iz]
    @views @. Fw[:,:,iz] -= FluxZ 
  end    
  @inbounds for iz = 1 : Nz - 1 
    @views @. GradZ = 1/2 * (pC[:,:,iz+1] - pC[:,:,iz]) * RhoC[:,:,iz] 
    @views @. FluxZ = GradZ * dXdxI[3,1,2,:,:,iz]
    @views @. FuC[:,:,iz] -= FluxZ 
    @views @. FluxZ = GradZ * dXdxI[3,2,2,:,:,iz]
    @views @. FvC[:,:,iz] -= FluxZ 
    @views @. FluxZ = GradZ * dXdxI[3,3,2,:,:,iz]
    @views @. Fw[:,:,iz+1] -= FluxZ 
  end    
#  if Nz == 2
#    @views @. GradZ = 1/2 * (pC[:,:,1+1] - pC[:,:,1]) * RhoC[:,:,1]
#    @views @. FluxZ = GradZ * dXdxI[:,:,1,1,3,1]
#    @views @. FuC[:,:,1] -= FluxZ
#    @views @. FluxZ = GradZ * dXdxI[:,:,1,1,3,2]
#    @views @. FvC[:,:,1] -= FluxZ
#    @views @. FluxZ =  GradZ * dXdxI[:,:,1,1,3,3]
#    @views @. Fw[:,:,1] -= FluxZ
#  elseif Nz > 2
#    @inbounds for i = 1 : OrdPoly + 1
#      @inbounds for j = 1 : OrdPoly + 1
#       @views GradZ[i,j] = (BoundaryDP(pC[i,j,1],pC[i,j,2],pC[i,j,3],
#        J[i,j,:,1],J[i,j,:,2],J[i,j,:,3]) - 1/2 * (pC[i,j,1+1] - pC[i,j,1])) * RhoC[i,j,1]
#       p0 = BoundaryP(pC[i,j,1]*RhoC[i,j,1],pC[i,j,2]*RhoC[i,j,2],pC[i,j,3]*RhoC[i,j,3],
#        p0 = BoundaryP(pC[i,j,1],pC[i,j,2],pC[i,j,3],
#         J[i,j,:,1],J[i,j,:,2],J[i,j,:,3])
#        GradZ[i,j] = 1/2 * (pC[i,j,1] - p0) * RhoC[i,j,1]
#      end
#    end
#   @views @. GradZ = ((pC[:,:,2] - pC[:,:,1]) - 1/2 * (pC[:,:,3] - pC[:,:,2])) * RhoC[:,:,1] 
#    @views @. FluxZ = GradZ * dXdxI[:,:,1,1,3,1]
#    @views @. FuC[:,:,1] -= FluxZ
##    @views @. FluxZ = GradZ * dXdxI[:,:,1,1,3,2]
#    @views @. FvC[:,:,1] -= FluxZ
#    @views @. FluxZ =  GradZ * dXdxI[:,:,1,1,3,3]
#    @views @. Fw[:,:,1] -= FluxZ
#  end
end 

function GradColumn1!(FuC,FvC,Fw,pC,RhoC,Fe,dXdxI,J,ThreadCache,Phys)
  @unpack TCacheC1, TCacheC2 = ThreadCache
  Nz = size(FuC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  @views DXpC = TCacheC1[Threads.threadid()]
  @views DYpC = TCacheC2[Threads.threadid()]
  @views GradZ = TCacheC1[Threads.threadid()]
  @views FluxZ = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz 
    @. DXpC = 0
    @views DerivativeX!(DXpC,pC[:,:,iz],D)
    @. DYpC = 0
    @views DerivativeY!(DYpC,pC[:,:,iz],D)
    @views @. FuC[:,:,iz] -=  
      ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DXpC + 
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DYpC)
    @views @. FvC[:,:,iz] -=   
      ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DXpC + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DYpC)
    @views @. Fw[:,:,iz] -= (dXdxI[1,3,1,:,:,iz] * DXpC + dXdxI[2,3,1,:,:,iz] * DYpC)
    @views @. Fw[:,:,iz+1] -= (dXdxI[1,3,2,:,:,iz] * DXpC + dXdxI[2,3,2,:,:,iz] * DYpC)
  end  
  @inbounds for iz = 2 : Nz 
# @views @. FwF[:,:,iz] -= Phys.Grav *
#   (RhoC[:,:,iz-1] * J[:,:,2,iz-1] +
#   RhoC[:,:,iz] * J[:,:,iz])
    @views @. GradZ = -Phys.Grav*RhoC[:,:,iz] * J[:,:,1,iz] / dXdxI[3,3,1,:,:,iz] 
    @views @. FluxZ = GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. FuC[:,:,iz] -= FluxZ 
    @views @. FluxZ = GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. FvC[:,:,iz] -= FluxZ 
    @views @. GradZ = 1/2 * (pC[:,:,iz] - pC[:,:,iz-1])
    @views @. FluxZ = GradZ * dXdxI[3,3,1,:,:,iz]
    @views @. Fw[:,:,iz] -= FluxZ # -Phys.Grav*RhoC[:,:,iz]*J[:,:,1,iz] 
  end    
  @inbounds for iz = 1 : Nz - 1 
    @views @. GradZ = -Phys.Grav*RhoC[:,:,iz] * J[:,:,2,iz] / dXdxI[3,3,2,:,:,iz] 
    @views @. FluxZ = GradZ * dXdxI[3,1,2,:,:,iz]
    @views @. FuC[:,:,iz] -= FluxZ 
    @views @. FluxZ = GradZ * dXdxI[3,2,2,:,:,iz]
    @views @. FvC[:,:,iz] -= FluxZ 
    @views @. GradZ = 1/2 * (pC[:,:,iz+1] - pC[:,:,iz])
    @views @. FluxZ =  GradZ * dXdxI[3,3,2,:,:,iz]
    @views @. Fw[:,:,iz+1] -= FluxZ # -Phys.Grav*RhoC[:,:,iz] * J[:,:,2,iz]
  end    
  if Nz  == 2
    @views @. GradZ = 1/2 * (pC[:,:,1+1] - pC[:,:,1])
    @views @. FluxZ = GradZ * dXdxI[:,:,1,1,3,1]
    @views @. FuC[:,:,1] -= FluxZ
    @views @. FluxZ = GradZ * dXdxI[:,:,1,1,3,2]
    @views @. FvC[:,:,1] -= FluxZ 
    @views @. FluxZ =  GradZ * dXdxI[:,:,1,1,3,3]
    @views @. Fw[:,:,1] -= FluxZ 
  elseif Nz > 2
    @views @. GradZ = -Phys.Grav * RhoC[:,:,1] * J[:,:,1,1] / dXdxI[:,:,1,1,3,3]
    @views @. FluxZ = GradZ * dXdxI[:,:,1,1,3,1]
    @views @. FuC[:,:,1] -= FluxZ
    @views @. FluxZ = GradZ * dXdxI[:,:,1,1,3,2]
    @views @. FvC[:,:,1] -= FluxZ
    @inbounds for i = 1 : OrdPoly + 1 
      @inbounds for j = 1 : OrdPoly + 1 
#       @views GradZ[i,j] = BoundaryDP(pC[i,j,1],pC[i,j,2],pC[i,j,3],  
#         J[i,j,:,1],J[i,j,:,2],J[i,j,:,3]) - 1/2 * (pC[i,j,1+1] - pC[i,j,1])  d  
        p0 = BoundaryP(pC[i,j,1],pC[i,j,2],pC[i,j,3],  
         J[i,j,:,1],J[i,j,:,2],J[i,j,:,3]) 
        GradZ[i,j] = 1/2 * (pC[i,j,1] - p0)
      end
    end  
#   @views @. GradZ = (pC[:,:,2] - pC[:,:,1]) - 1/2 * (pC[:,:,3] - pC[:,:,2])  
    @views @. FluxZ =  GradZ * dXdxI[:,:,1,1,3,3]
    @views @. Fw[:,:,1] -= FluxZ 
  end 
end 

function DivRhoColumn!(FRhoC,uC,vC,w,RhoC,Fe,dXdxI,ThreadCache,::Val{:VectorInvariant})
    @unpack TCacheC1, TCacheC2, TCacheCol1 = ThreadCache
  Nz = size(uC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  tempZ = TCacheCol1[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz  
    @views @. tempZ[:,:,1,iz] = -RhoC[:,:,iz] * (dXdxI[3,1,1,:,:,iz] * uC[:,:,iz] +
      dXdxI[3,2,1,:,:,iz] * vC[:,:,iz] + dXdxI[3,3,1,:,:,iz] * w[:,:,iz])
    @views @. tempZ[:,:,2,iz] = -RhoC[:,:,iz] * (dXdxI[3,1,2,:,:,iz] * uC[:,:,iz] +
      dXdxI[3,2,2,:,:,iz] * vC[:,:,iz] + dXdxI[3,3,2,:,:,iz] * w[:,:,iz+1])
  end    
  @inbounds for iz = 1 :Nz  
    @views @. temp = -RhoC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * vC[:,:,iz]) 
    @views DerivativeX!(FRhoC[:,:,iz],temp,D)
    @views @. temp = -RhoC[:,:,iz] * ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * vC[:,:,iz]) 
    @views DerivativeY!(FRhoC[:,:,iz],temp,D)

    @views @. FRhoC[:,:,iz] += (tempZ[:,:,2,iz] - tempZ[:,:,1,iz])
  end  
  @inbounds for iz = 1 :Nz - 1  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz+1] - tempZ[:,:,2,iz]) 
    @views @. FRhoC[:,:,iz] += FluxZ
    @views @. FRhoC[:,:,iz+1] += FluxZ
  end 
end 

function DivRhoColumn!(FRhoC,uC,vC,w,RhoC,Fe,dXdxI,ThreadCache,::Val{:VectorInvariantDeep})
    @unpack TCacheC1, TCacheC2, TCacheCol1 = ThreadCache
  Nz = size(uC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  tempZ = TCacheCol1[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz  
    @views @. tempZ[:,:,1,iz] = -RhoC[:,:,iz] * (dXdxI[3,1,1,:,:,iz] * uC[:,:,iz] +
      dXdxI[3,2,1,:,:,iz] * vC[:,:,iz] + dXdxI[3,3,1,:,:,iz] * w[:,:,iz])
    @views @. tempZ[:,:,2,iz] = -RhoC[:,:,iz] * (dXdxI[3,1,2,:,:,iz] * uC[:,:,iz] +
      dXdxI[3,2,2,:,:,iz] * vC[:,:,iz] + dXdxI[3,3,2,:,:,iz] * w[:,:,iz+1])
  end    
  @inbounds for iz = 1 :Nz  
    @views @. temp = -RhoC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * vC[:,:,iz] + 
      dXdxI[1,3,1,:,:,iz] * w[:,:,iz] + dXdxI[1,3,2,:,:,iz] * w[:,:,iz+1])
    @views DerivativeX!(FRhoC[:,:,iz],temp,D)
    @views @. temp = -RhoC[:,:,iz] * ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * vC[:,:,iz] + 
      dXdxI[2,3,1,:,:,iz] * w[:,:,iz] + dXdxI[2,3,2,:,:,iz] * w[:,:,iz+1])
    @views DerivativeY!(FRhoC[:,:,iz],temp,D)

    @views @. FRhoC[:,:,iz] += (tempZ[:,:,2,iz] - tempZ[:,:,1,iz])
  end  
  @inbounds for iz = 2 :Nz  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz] - tempZ[:,:,2,iz-1]) 
    @views @. FRhoC[:,:,iz] += FluxZ
  end  
  @inbounds for iz = 1 :Nz - 1  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz+1] - tempZ[:,:,2,iz]) 
    @views @. FRhoC[:,:,iz] += FluxZ
  end 
end 

function DivRhoColumn!(FRhoC,RhouC,RhovC,Rhow,Fe,dXdxI,ThreadCache,::Val{:VectorInvariant})
    @unpack TCacheC1, TCacheC2, TCacheCol1 = ThreadCache
  Nz = size(RhouC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  tempZ = TCacheCol1[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz  
    @views @. tempZ[:,:,1,iz] = -(dXdxI[3,1,1,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[3,2,1,:,:,iz] * RhovC[:,:,iz] + dXdxI[3,3,1,:,:,iz] * Rhow[:,:,iz])
    @views @. tempZ[:,:,2,iz] = -(dXdxI[3,1,2,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[3,2,2,:,:,iz] * RhovC[:,:,iz] + dXdxI[3,3,2,:,:,iz] * Rhow[:,:,iz+1])
  end    
  @inbounds for iz = 1 :Nz  
    @views @. temp = -((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * RhouC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * RhovC[:,:,iz] )
    @views DerivativeX!(FRhoC[:,:,iz],temp,D)
    @views @. temp = -((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * RhouC[:,:,iz] +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * RhovC[:,:,iz])  
    @views DerivativeY!(FRhoC[:,:,iz],temp,D)

    @views @. FRhoC[:,:,iz] += (tempZ[:,:,2,iz] - tempZ[:,:,1,iz])
  end  
  @inbounds for iz = 1 :Nz - 1  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz+1] - tempZ[:,:,2,iz]) 
    @views @. FRhoC[:,:,iz] += FluxZ
    @views @. FRhoC[:,:,iz+1] += FluxZ
  end 
end 

function DivRhoColumn!(FRhoC,RhouC,RhovC,Rhow,Fe,dXdxI,ThreadCache,::Val{:VectorInvariantDeep})
    @unpack TCacheC1, TCacheC2, TCacheCol1 = ThreadCache
  Nz = size(RhouC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  tempZ = TCacheCol1[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz  
    @views @. tempZ[:,:,1,iz] = -(dXdxI[3,1,1,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[3,2,1,:,:,iz] * RhovC[:,:,iz] + dXdxI[3,3,1,:,:,iz] * Rhow[:,:,iz])
    @views @. tempZ[:,:,2,iz] = -(dXdxI[3,1,2,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[3,2,2,:,:,iz] * RhovC[:,:,iz] + dXdxI[3,3,2,:,:,iz] * Rhow[:,:,iz+1])
  end    
  @inbounds for iz = 1 :Nz  
    @views @. temp = -((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * RhouC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * RhovC[:,:,iz] + 
      dXdxI[1,3,1,:,:,iz] * Rhow[:,:,iz] + dXdxI[1,3,2,:,:,iz] * Rhow[:,:,iz+1])
    @views DerivativeX!(FRhoC[:,:,iz],temp,D)
    @views @. temp = -((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * RhouC[:,:,iz] +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * RhovC[:,:,iz] + 
      dXdxI[2,3,1,:,:,iz] * Rhow[:,:,iz] + dXdxI[2,3,2,:,:,iz] * Rhow[:,:,iz+1])
    @views DerivativeY!(FRhoC[:,:,iz],temp,D)

    @views @. FRhoC[:,:,iz] += (tempZ[:,:,2,iz] - tempZ[:,:,1,iz])
  end  
  @inbounds for iz = 2 :Nz  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz] - tempZ[:,:,2,iz-1]) 
    @views @. FRhoC[:,:,iz] += FluxZ
  end  
  @inbounds for iz = 1 :Nz - 1  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz+1] - tempZ[:,:,2,iz]) 
    @views @. FRhoC[:,:,iz] += FluxZ
  end 
end 

function DivRhoColumnE!(FRhoC,uC,vC,w,RhoC,D,dXdxI)

  N = size(uC,1)
  Nz = size(uC,3)

  @inbounds for iz = 1 : Nz
    @inbounds for j = 1 : N
      @inbounds for i = 1 : N
        temp1 = -RhoC[i,j,iz] * (dXdxI[i,j,1,iz,3,1] * uC[i,j,iz] +
          dXdxI[i,j,1,iz,3,2] * vC[i,j,iz] + dXdxI[i,j,1,iz,3,3] * w[i,j,iz])
        temp2 = -RhoC[i,j,iz] * (dXdxI[i,j,2,iz,3,1] * uC[i,j,iz] +
          dXdxI[i,j,2,iz,3,2] * vC[i,j,iz] + dXdxI[i,j,2,iz,3,3] * w[i,j,iz+1])
        FRhoC[i,j,iz] += (temp2 - temp1)
        if iz > 1
          FRhoC[i,j,iz-1] -= 1/2 * temp1
          FRhoC[i,j,iz] += 1/2 * temp2
        end
        if iz < Nz
          FRhoC[i,j,iz] -= 1/2 * temp2
          FRhoC[i,j,iz+1] += 1/2 * temp1
        end
      end
    end
  end
  @inbounds for iz = 1 : Nz
    @inbounds for j = 1 : N
      @inbounds for i = 1 : N
        tempx = -RhoC[i,j,iz] * ((dXdxI[i,j,1,iz,1,1] + dXdxI[i,j,2,iz,1,1]) * uC[i,j,iz] +
          (dXdxI[i,j,1,iz,1,2] + dXdxI[i,j,2,iz,1,2]) * vC[i,j,iz] +
          dXdxI[i,j,1,iz,1,3] * w[i,j,iz] + dXdxI[i,j,2,iz,1,3] * w[i,j,iz+1])
        tempy = -RhoC[i,j,iz] * ((dXdxI[i,j,1,iz,2,1] + dXdxI[i,j,2,iz,2,1]) * uC[i,j,iz] +
          (dXdxI[i,j,1,iz,2,2] + dXdxI[i,j,2,iz,2,2]) * vC[i,j,iz] +
          dXdxI[i,j,1,iz,2,3] * w[i,j,iz] + dXdxI[i,j,2,iz,2,3] * w[i,j,iz+1])
        for k = 1 : N
          FRhoC[k,j,iz] += D[k,i] * tempx
          FRhoC[i,k,iz] += D[k,j] * tempy
        end
      end
    end
  end
end

function DivRhoTrColumnE!(FRhoTrC,uC,vC,w,RhoTrC,D,dXdxI)

  N = size(uC,1)
  Nz = size(uC,3)

  @inbounds for iz = 1 : Nz
    @inbounds for j = 1 : N
      @inbounds for i = 1 : N
        temp1 = -RhoTrC[i,j,iz] * (dXdxI[i,j,1,iz,3,1] * uC[i,j,iz] +
          dXdxI[i,j,1,iz,3,2] * vC[i,j,iz] + dXdxI[i,j,1,iz,3,3] * w[i,j,iz])
        temp2 = -RhoTrC[i,j,iz] * (dXdxI[i,j,2,iz,3,1] * uC[i,j,iz] +
          dXdxI[i,j,2,iz,3,2] * vC[i,j,iz] + dXdxI[i,j,2,iz,3,3] * w[i,j,iz+1])
        FRhoTrC[i,j,iz] += (temp2 - temp1)
        if iz > 1
          FRhoTrC[i,j,iz-1] -= 1/2 * temp1
          FRhoTrC[i,j,iz] += 1/2 * temp2
        end
        if iz < Nz
          FRhoTrC[i,j,iz] -= 1/2 * temp2
          FRhoTrC[i,j,iz+1] += 1/2 * temp1
        end
      end
    end
  end
  @inbounds for iz = 1 : Nz
    @inbounds for j = 1 : N
      @inbounds for i = 1 : N
        tempx = -RhoTrC[i,j,iz] * ((dXdxI[i,j,1,iz,1,1] + dXdxI[i,j,2,iz,1,1]) * uC[i,j,iz] +
          (dXdxI[i,j,1,iz,1,2] + dXdxI[i,j,2,iz,1,2]) * vC[i,j,iz] +
          dXdxI[i,j,1,iz,1,3] * w[i,j,iz] + dXdxI[i,j,2,iz,1,3] * w[i,j,iz+1])
        tempy = -RhoTrC[i,j,iz] * ((dXdxI[i,j,1,iz,2,1] + dXdxI[i,j,2,iz,2,1]) * uC[i,j,iz] +
          (dXdxI[i,j,1,iz,2,2] + dXdxI[i,j,2,iz,2,2]) * vC[i,j,iz] +
          dXdxI[i,j,1,iz,2,3] * w[i,j,iz] + dXdxI[i,j,2,iz,2,3] * w[i,j,iz+1])
        for k = 1 : N
          FRhoTrC[k,j,iz] += D[k,i] * tempx
          FRhoTrC[i,k,iz] += D[k,j] * tempy
        end
      end
    end
  end
end

function DivRhoTrColumn!(FRhoTrC,uC,vC,w,RhoTrC,Fe,dXdxI,ThreadCache,::Val{:VectorInvariant})
  @unpack TCacheC1, TCacheC2, TCacheCol1 = ThreadCache
  Nz = size(uC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  tempZ = TCacheCol1[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz  
    @views @. tempZ[:,:,1,iz] = -RhoTrC[:,:,iz] * (dXdxI[3,1,1,:,:,iz] * uC[:,:,iz] +
      dXdxI[3,2,1,:,:,iz] * vC[:,:,iz] + dXdxI[3,3,1,:,:,iz] * w[:,:,iz])
    @views @. tempZ[:,:,2,iz] = -RhoTrC[:,:,iz] * (dXdxI[3,1,2,:,:,iz] * uC[:,:,iz] +
      dXdxI[3,2,2,:,:,iz] * vC[:,:,iz] + dXdxI[3,3,2,:,:,iz] * w[:,:,iz+1])
  end    
  @inbounds for iz = 1 : Nz  
    @views @. temp = -RhoTrC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * vC[:,:,iz])
    @views DerivativeX!(FRhoTrC[:,:,iz],temp,D)
    @views @. temp = -RhoTrC[:,:,iz] * ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * vC[:,:,iz])  
    @views DerivativeY!(FRhoTrC[:,:,iz],temp,D)

    @views @. FRhoTrC[:,:,iz] += (tempZ[:,:,2,iz] - tempZ[:,:,1,iz])
  end    
  @inbounds for iz = 1 : Nz - 1  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz+1] - tempZ[:,:,2,iz]) 
    @views @. FRhoTrC[:,:,iz] += FluxZ
    @views @. FRhoTrC[:,:,iz+1] += FluxZ
  end 
end 

function DivRhoTrColumn!(FRhoTrC,uC,vC,w,RhoTrC,Fe,dXdxI,ThreadCache,::Val{:VectorInvariantDeep})
  @unpack TCacheC1, TCacheC2, TCacheCol1 = ThreadCache
  Nz = size(uC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  tempZ = TCacheCol1[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz  
    @views @. tempZ[:,:,1,iz] = -RhoTrC[:,:,iz] * (dXdxI[3,1,1,:,:,iz] * uC[:,:,iz] +
      dXdxI[3,2,1,:,:,iz] * vC[:,:,iz] + dXdxI[3,3,1,:,:,iz] * w[:,:,iz])
    @views @. tempZ[:,:,2,iz] = -RhoTrC[:,:,iz] * (dXdxI[3,1,2,:,:,iz] * uC[:,:,iz] +
      dXdxI[3,2,2,:,:,iz] * vC[:,:,iz] + dXdxI[3,3,2,:,:,iz] * w[:,:,iz+1])
  end    
  @inbounds for iz = 1 : Nz  
    @views @. temp = -RhoTrC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * vC[:,:,iz] + 
      dXdxI[1,3,1,:,:,iz] * w[:,:,iz] + dXdxI[1,3,2,:,:,iz] * w[:,:,iz+1])
    @views DerivativeX!(FRhoTrC[:,:,iz],temp,D)
    @views @. temp = -RhoTrC[:,:,iz] * ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * vC[:,:,iz] + 
      dXdxI[2,3,1,:,:,iz] * w[:,:,iz] + dXdxI[2,3,2,:,:,iz] * w[:,:,iz+1])
    @views DerivativeY!(FRhoTrC[:,:,iz],temp,D)
  end    
  @inbounds for iz = 2 : Nz  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz] - tempZ[:,:,2,iz-1]) 
    @views @. FRhoTrC[:,:,iz] += FluxZ
  end  
  @inbounds for iz = 1 : Nz - 1  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz+1] - tempZ[:,:,2,iz]) 
    @views @. FRhoTrC[:,:,iz] += FluxZ
  end 
end 

function DivRhoTrColumn!(FRhoTrC,RhouC,RhovC,Rhow,RhoTrC,RhoC,Fe,dXdxI,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheCol1 = ThreadCache
  Nz = size(RhouC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  tempZ = TCacheCol1[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz  
    @views @. tempZ[:,:,1,iz] = -RhoTrC[:,:,iz] * (dXdxI[3,1,1,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[3,2,1,:,:,iz] * RhovC[:,:,iz] + dXdxI[3,3,1,:,:,iz] * Rhow[:,:,iz]) / RhoC[:,:,iz]
    @views @. tempZ[:,:,2,iz] = -RhoTrC[:,:,iz] * (dXdxI[3,1,2,:,:,iz] * RhouC[:,:,iz] +
      dXdxI[3,2,2,:,:,iz] * RhovC[:,:,iz] + dXdxI[3,3,2,:,:,iz] * Rhow[:,:,iz+1]) / RhoC[:,:,iz]
  end    
  @inbounds for iz = 1 : Nz  
    @views @. temp = -RhoTrC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * RhouC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * RhovC[:,:,iz] + 
      dXdxI[1,3,1,:,:,iz] * Rhow[:,:,iz] + dXdxI[1,3,2,:,:,iz] * Rhow[:,:,iz+1]) / RhoC[:,:,iz]
    @views DerivativeX!(FRhoTrC[:,:,iz],temp,D)
    @views @. temp = -RhoTrC[:,:,iz] * ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * RhouC[:,:,iz] +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * RhovC[:,:,iz] + 
      dXdxI[2,3,1,:,:,iz] * Rhow[:,:,iz] + dXdxI[2,3,2,:,:,iz] * Rhow[:,:,iz+1]) / RhoC[:,:,iz]
    @views DerivativeY!(FRhoTrC[:,:,iz],temp,D)

    @views @. FRhoTrC[:,:,iz] += (tempZ[:,:,2,iz] - tempZ[:,:,1,iz])
  end    
  @inbounds for iz = 2 : Nz  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz] - tempZ[:,:,2,iz-1]) 
    @views @. FRhoTrC[:,:,iz] += FluxZ
  end  
  @inbounds for iz = 1 : Nz - 1  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz+1] - tempZ[:,:,2,iz]) 
    @views @. FRhoTrC[:,:,iz] += FluxZ
  end 
end 

function DivUpwindRhoTrColumn!(FRhoTrC,RhouC,RhovC,Rhow,RhoTrC,RhoC,Fe,dXdxI,J,
  ThreadCache,HorLimit,::Val{:Conservative})
  @unpack TCacheC1, TCacheC2, TCacheCol1, TCacheCol2, TCacheCol3  = ThreadCache
  Nz = size(RhouC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  tempZ = TCacheCol1[Threads.threadid()]
  TrRe = TCacheCol2[Threads.threadid()]
  @views TrC = TCacheCol3[Threads.threadid()][:,:,1,:]
  temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @views @. TrC[:,:,iz] = RhoTrC[:,:,iz] / RhoC[:,:,iz]  
    if HorLimit
      @views DivConvRhoTrCell!(FRhoTrC[:,:,iz],RhouC[:,:,iz],RhovC[:,:,iz],
        Rhow[:,:,iz],w[:,:,iz+1],TrC[:,:,iz],Fe,
        dXdxI[:,:,:,iz,:,:],J[:,:,:,iz],ThreadCache)
    else
      @views @. temp = -TrC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * RhouC[:,:,iz] +
        (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * RhovC[:,:,iz] +
        dXdxI[1,3,1,:,:,iz] * Rhow[:,:,iz] + dXdxI[1,3,2,:,:,iz] * Rhow[:,:,iz+1])
      @views DerivativeX!(FRhoTrC[:,:,iz],temp,D)
      @views @. temp = -TrC[:,:,iz] * ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * RhouC[:,:,iz] +
        (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * RhovC[:,:,iz] +
        dXdxI[2,3,1,:,:,iz] * Rhow[:,:,iz] + dXdxI[2,3,2,:,:,iz] * Rhow[:,:,iz+1])
      @views DerivativeY!(FRhoTrC[:,:,iz],temp,D)
    end
  end  

  if Nz > 1
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        JC = (J[i,j,1,1] + J[i,j,2,1])  
        JCp1 = (J[i,j,1,2] + J[i,j,2,2])  
        Tr = TrC[i,j,1] 
        Trp1 = TrC[i,j,2] 
#       Tr0 = ((3 * Tr - 2 * Trp1) * JC + Tr * JCp1) / (JC + JCp1)
        Tr0 = Tr
        TrRe[i,j,1,1],TrRe[i,j,2,1] = RecU3(Tr0,Tr,Trp1,JC,JC,JCp1)
      end  
    end    
    @inbounds for iz = 2 : Nz - 1  
      @inbounds for i = 1 : OrdPoly + 1
        @inbounds for j = 1 : OrdPoly + 1
          JCm1 = (J[i,j,1,iz-1] + J[i,j,2,iz-1])  
          JC = (J[i,j,1,iz] + J[i,j,2,iz])  
          JCp1 = (J[i,j,1,iz+1] + J[i,j,2,iz+1])  
          Trm1 = TrC[i,j,iz-1] 
          Tr = TrC[i,j,iz] 
          Trp1 = TrC[i,j,iz+1] 
          TrRe[i,j,1,iz],TrRe[i,j,2,iz] = RecU3(Trm1,Tr,Trp1,JCm1,JC,JCp1)
        end
      end  
    end    
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        JCm1 = (J[i,j,1,Nz-1] + J[i,j,2,Nz-1])  
        JC = (J[i,j,1,Nz] + J[i,j,2,Nz])  
        Trm1 = TrC[i,j,Nz-1]
        Tr = TrC[i,j,Nz] 
#       Tr1 = ((3 * Tr - 2 * Trm1) * JC + Tr * JCm1) / (JCm1 + JC)
        Tr1 = Tr
        TrRe[i,j,1,Nz],TrRe[i,j,2,Nz] = RecU3(Trm1,Tr,Tr1,JCm1,JC,JC)
      end  
    end    
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        tempZ[i,j,1,1] =0
        wC = (dXdxI[i,j,2,1,3,1] * RhouC[i,j,1] +
          dXdxI[i,j,2,1,3,2] * RhovC[i,j,1] + dXdxI[i,j,2,1,3,3] * Rhow[i,j,1+1])
        tempZ[i,j,2,1] = -1/2 * ((wC + abs(wC)) * TrRe[i,j,2,1] +
          (wC - abs(wC)) * TrRe[i,j,1,1+1])
      end
    end  
    @inbounds for iz = 2 : Nz - 1
      @inbounds for i = 1 : OrdPoly + 1
        @inbounds for j = 1 : OrdPoly + 1
          wC = (dXdxI[i,j,1,iz,3,1] * RhouC[i,j,iz] +
            dXdxI[i,j,1,iz,3,2] * RhovC[i,j,iz] + dXdxI[i,j,1,iz,3,3] * Rhow[i,j,iz])
          tempZ[i,j,1,iz] = -1/2 * ((wC + abs(wC)) * TrRe[i,j,2,iz-1] + 
            (wC - abs(wC)) * TrRe[i,j,1,iz])
          wC = (dXdxI[i,j,2,iz,3,1] * RhouC[i,j,iz] +
            dXdxI[i,j,2,iz,3,2] * RhovC[i,j,iz] + dXdxI[i,j,2,iz,3,3] * Rhow[i,j,iz+1])
          tempZ[i,j,2,iz] = -1/2 * ((wC + abs(wC)) * TrRe[i,j,2,iz] +
            (wC - abs(wC)) * TrRe[i,j,1,iz+1])
        end
      end  
    end    
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        wC = (dXdxI[i,j,1,Nz,3,1] * RhouC[i,j,Nz] +
          dXdxI[i,j,1,Nz,3,2] * RhovC[i,j,Nz] + dXdxI[i,j,1,Nz,3,3] * Rhow[i,j,Nz]) 
        tempZ[i,j,1,Nz] = -1/2 * ((wC + abs(wC)) * TrRe[i,j,2,Nz-1] +
          (wC - abs(wC)) * TrRe[i,j,1,Nz])
        tempZ[i,j,2,Nz] = 0
      end
    end  
  else
   @. tempZ = 0   
  end    

  @inbounds for iz = 1 : Nz  
    @views @. FRhoTrC[:,:,iz] += (tempZ[:,:,2,iz] - tempZ[:,:,1,iz])
  end    
  @inbounds for iz = 2 : Nz  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz] - tempZ[:,:,2,iz-1]) 
    @views @. FRhoTrC[:,:,iz] += FluxZ
  end  
  @inbounds for iz = 1 : Nz - 1  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz+1] - tempZ[:,:,2,iz]) 
    @views @. FRhoTrC[:,:,iz] += FluxZ
  end 
end 

function DivUpwindRhoTrColumn!(FRhoTrC,uC,vC,w,RhoTrC,RhoC,Fe,dXdxI,J,
  ThreadCache,HorLimit,::Val{:VectorInvariant})
  @unpack TCacheC1, TCacheC2, TCacheCol1, TCacheCol2 = ThreadCache
  Nz = size(uC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  tempZ = TCacheCol1[Threads.threadid()]
  TrRe = TCacheCol2[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC2[Threads.threadid()]

  if HorLimit
    DivConvRhoTrColumn!(FRhoTrC,uC,vC,w,RhoTrC,RhoC,Fe,dXdxI,J,ThreadCache)
  else  
    @inbounds for iz = 1 : Nz
      @views @. temp = -RhoTrC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * uC[:,:,iz] +
        (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * vC[:,:,iz]) 
      @views DerivativeX!(FRhoTrC[:,:,iz],temp,D)
      @views @. temp = -RhoTrC[:,:,iz] * ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * uC[:,:,iz] +
        (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * vC[:,:,iz])
      @views DerivativeY!(FRhoTrC[:,:,iz],temp,D)
    end
  end  

  if Nz > 1
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        JC = (J[i,j,1,1] + J[i,j,2,1])  
        JCp1 = (J[i,j,1,2] + J[i,j,2,2])  
        Tr = RhoTrC[i,j,1] / RhoC[i,j,1]
        Trp1 = RhoTrC[i,j,2] / RhoC[i,j,2]
        Tr0 = ((3 * Tr - 2 * Trp1) * JC + Tr * JCp1) / (JC + JCp1)
        TrRe[i,j,1,1],TrRe[i,j,2,1] = RecU3(Tr0,Tr,Trp1,JC,JC,JCp1)
        TrRe[i,j,1,1] = Tr
        TrRe[i,j,2,1] = Tr
      end  
    end    
    @inbounds for iz = 2 : Nz - 1  
      @inbounds for i = 1 : OrdPoly + 1
        @inbounds for j = 1 : OrdPoly + 1
          JCm1 = (J[i,j,1,iz-1] + J[i,j,2,iz-1])  
          JC = (J[i,j,1,iz] + J[i,j,2,iz])  
          JCp1 = (J[i,j,1,iz+1] + J[i,j,2,iz+1])  
          Trm1 = RhoTrC[i,j,iz-1] / RhoC[i,j,iz-1]
          Tr = RhoTrC[i,j,iz] / RhoC[i,j,iz]
          Trp1 = RhoTrC[i,j,iz+1] / RhoC[i,j,iz+1]
          TrRe[i,j,1,iz],TrRe[i,j,2,iz] = RecU3(Trm1,Tr,Trp1,JCm1,JC,JCp1)
        end
      end  
    end    
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        JCm1 = (J[i,j,1,Nz-1] + J[i,j,2,Nz-1])  
        JC = (J[i,j,1,Nz] + J[i,j,2,Nz])  
        Trm1 = RhoTrC[i,j,Nz-1] / RhoC[i,j,Nz-1]
        Tr = RhoTrC[i,j,Nz] / RhoC[i,j,Nz]
        Tr1 = ((3 * Tr - 2 * Trm1) * JC + Tr * JCm1) / (JCm1 + JC)
        TrRe[i,j,1,Nz],TrRe[i,j,2,Nz] = RecU3(Trm1,Tr,Tr1,JCm1,JC,JC)
      end  
    end    
  end    
  @inbounds for iz = 1 : Nz - 1
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        wC = ((dXdxI[3,1,2,i,j,iz] * uC[i,j,iz] + dXdxI[3,2,2,i,j,iz] * vC[i,j,iz] +
          dXdxI[3,3,2,i,j,iz] * w[i,j,iz+1]) * RhoC[i,j,iz]  +
          (dXdxI[3,1,1,i,j,iz+1] * uC[i,j,iz+1] + dXdxI[3,2,1,i,j,iz+1] * vC[i,j,iz+1] + 
           dXdxI[3,3,1,i,j,iz+1] * w[i,j,iz+1]) * RhoC[i,j,iz+1])
        Flux = 1 / 4 * ((wC + abs(wC)) * TrRe[i,j,2,iz] +
          (wC - abs(wC)) * TrRe[i,j,1,iz+1])
        FRhoTrC[i,j,iz] -= Flux
        FRhoTrC[i,j,iz+1] += Flux
      end
    end  
  end    
end 

function DivUpwindRhoTrColumn!(FRhoTrC,uC,vC,w,RhoTrC,RhoC,Fe,dXdxI,J,
  ThreadCache,HorLimit,::Val{:VectorInvariantDeep})
  @unpack TCacheC1, TCacheC2, TCacheCol1, TCacheCol2 = ThreadCache
  Nz = size(uC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  tempZ = TCacheCol1[Threads.threadid()]
  TrRe = TCacheCol2[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  FluxZ = TCacheC2[Threads.threadid()]


  @inbounds for iz = 1 : Nz
    if HorLimit
      @views DivConvRhoTrCell!(FRhoTrC[:,:,iz],uC[:,:,iz],vC[:,:,iz],
        w[:,:,iz],w[:,:,iz+1],RhoTrC[:,:,iz],Fe,
        dXdxI[:,:,:,iz,:,:],J[:,:,:,iz],ThreadCache)
    else
      @views @. temp = -RhoTrC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * uC[:,:,iz] +
        (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * vC[:,:,iz] +
        dXdxI[1,3,1,:,:,iz] * w[:,:,iz] + dXdxI[1,3,2,:,:,iz] * w[:,:,iz+1])
      @views DerivativeX!(FRhoTrC[:,:,iz],temp,D)
      @views @. temp = -RhoTrC[:,:,iz] * ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * uC[:,:,iz] +
        (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * vC[:,:,iz] +
        dXdxI[2,3,1,:,:,iz] * w[:,:,iz] + dXdxI[2,3,2,:,:,iz] * w[:,:,iz+1])
      @views DerivativeY!(FRhoTrC[:,:,iz],temp,D)
    end
  end  

  if Nz > 1
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        JC = (J[i,j,1,1] + J[i,j,2,1])  
        JCp1 = (J[i,j,1,2] + J[i,j,2,2])  
        Tr = RhoTrC[i,j,1] / RhoC[i,j,1]
        Trp1 = RhoTrC[i,j,2] / RhoC[i,j,2]
        Tr0 = ((3 * Tr - 2 * Trp1) * JC + Tr * JCp1) / (JC + JCp1)
        TrRe[i,j,1,1],TrRe[i,j,2,1] = RecU3(Tr0,Tr,Trp1,JC,JC,JCp1)
      end  
    end    
    @inbounds for iz = 2 : Nz - 1  
      @inbounds for i = 1 : OrdPoly + 1
        @inbounds for j = 1 : OrdPoly + 1
          JCm1 = (J[i,j,1,iz-1] + J[i,j,2,iz-1])  
          JC = (J[i,j,1,iz] + J[i,j,2,iz])  
          JCp1 = (J[i,j,1,iz+1] + J[i,j,2,iz+1])  
          Trm1 = RhoTrC[i,j,iz-1] / RhoC[i,j,iz-1]
          Tr = RhoTrC[i,j,iz] / RhoC[i,j,iz]
          Trp1 = RhoTrC[i,j,iz+1] / RhoC[i,j,iz+1]
          TrRe[i,j,1,iz],TrRe[i,j,2,iz] = RecU3(Trm1,Tr,Trp1,JCm1,JC,JCp1)
        end
      end  
    end    
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        JCm1 = (J[i,j,1,Nz-1] + J[i,j,2,Nz-1])  
        JC = (J[i,j,1,Nz] + J[i,j,2,Nz])  
        Trm1 = RhoTrC[i,j,Nz-1] / RhoC[i,j,Nz-1]
        Tr = RhoTrC[i,j,Nz] / RhoC[i,j,Nz]
        Tr1 = ((3 * Tr - 2 * Trm1) * JC + Tr * JCm1) / (JCm1 + JC)
        TrRe[i,j,1,Nz],TrRe[i,j,2,Nz] = RecU3(Trm1,Tr,Tr1,JCm1,JC,JC)
      end  
    end    
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        tempZ[i,j,1,1] =0
        wC = (dXdxI[i,j,2,1,3,1] * uC[i,j,1] +
          dXdxI[i,j,2,1,3,2] * vC[i,j,1] + dXdxI[i,j,2,1,3,3] * w[i,j,1+1])
        tempZ[i,j,2,1] = -1/2 * RhoC[i,j,1] * ((wC + abs(wC)) * TrRe[i,j,2,1] +
          (wC - abs(wC)) * TrRe[i,j,1,1+1])
      end
    end  
    @inbounds for iz = 2 : Nz - 1
      @inbounds for i = 1 : OrdPoly + 1
        @inbounds for j = 1 : OrdPoly + 1
          wC = (dXdxI[i,j,1,iz,3,1] * uC[i,j,iz] +
            dXdxI[i,j,1,iz,3,2] * vC[i,j,iz] + dXdxI[i,j,1,iz,3,3] * w[i,j,iz])
          tempZ[i,j,1,iz] = -1/2 * RhoC[i,j,iz] * ((wC + abs(wC)) * TrRe[i,j,2,iz-1] + 
            (wC - abs(wC)) * TrRe[i,j,1,iz])
          wC = (dXdxI[i,j,2,iz,3,1] * uC[i,j,iz] +
            dXdxI[i,j,2,iz,3,2] * vC[i,j,iz] + dXdxI[i,j,2,iz,3,3] * w[i,j,iz+1])
          tempZ[i,j,2,iz] = -1/2 * RhoC[i,j,iz] * ((wC + abs(wC)) * TrRe[i,j,2,iz] +
            (wC - abs(wC)) * TrRe[i,j,1,iz+1])
        end
      end  
    end    
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        wC = (dXdxI[i,j,1,Nz,3,1] * uC[i,j,Nz] +
          dXdxI[i,j,1,Nz,3,2] * vC[i,j,Nz] + dXdxI[i,j,1,Nz,3,3] * w[i,j,Nz]) 
        tempZ[i,j,1,Nz] = -1/2 * RhoC[i,j,Nz] * ((wC + abs(wC)) * TrRe[i,j,2,Nz-1] +
          (wC - abs(wC)) * TrRe[i,j,1,Nz])
        tempZ[i,j,2,Nz] = 0
      end
    end  
  else
   @. tempZ = 0   
  end    

  @inbounds for iz = 1 : Nz  
    @views @. FRhoTrC[:,:,iz] += (tempZ[:,:,2,iz] - tempZ[:,:,1,iz])
  end    
  @inbounds for iz = 2 : Nz  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz] - tempZ[:,:,2,iz-1]) 
    @views @. FRhoTrC[:,:,iz] += FluxZ
  end  
  @inbounds for iz = 1 : Nz - 1  
    @views @. FluxZ = 1/2 * (tempZ[:,:,1,iz+1] - tempZ[:,:,2,iz]) 
    @views @. FRhoTrC[:,:,iz] += FluxZ
  end 
end 

function DivRhoGrad!(F,cC,RhoC,Fe,dXdxI,J,ThreadCache,Koeff)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4 = ThreadCache
  Nz = size(F,3)
  D = Fe.DS
  DW = Fe.DW

  DxcC = TCacheC1[Threads.threadid()]
  DycC = TCacheC2[Threads.threadid()]
  GradDx = TCacheC3[Threads.threadid()]
  GradDy = TCacheC4[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  Div = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. DxcC = 0
    @. DycC = 0
    @views DerivativeX!(DxcC,cC[:,:,iz],D)
    @views DerivativeY!(DycC,cC[:,:,iz],D)

    @views @. GradDx = RhoC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxcC + 
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])
    @views @. GradDy = RhoC[:,:,iz] * ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxcC + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])

    @. Div = 0
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * GradDx + 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * GradDy 
    DerivativeX!(Div,temp,DW)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * GradDx + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * GradDy
    DerivativeY!(Div,temp,DW)

    @views @. F[:,:,iz] -= Koeff * Div 
  end    
end    

function DivRhoGradHor!(F,cC,RhoC,Fe,dXdxI,J,ThreadCache,Koeff)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4 = ThreadCache
  Nz = size(F,3)
  D = Fe.DS
  DW = Fe.DW

  DxcC = TCacheC1[Threads.threadid()]
  DycC = TCacheC2[Threads.threadid()]
  GradDx = TCacheC3[Threads.threadid()]
  GradDy = TCacheC4[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  Div = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. DxcC = 0
    @. DycC = 0
    @views DerivativeX!(DxcC,cC[:,:,iz],D)
    @views DerivativeY!(DycC,cC[:,:,iz],D)

    @views @. GradDx = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxcC + 
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])
    @views @. GradDy = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxcC + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])

    if iz > 1
      @views @. GradDx += 0.25 * (dXdxI[3,1,2,:,:,iz-1] + dXdxI[3,1,1,:,:,iz]) * (cC[:,:,iz] - cC[:,:,iz-1]) /
      (J[:,:,2,iz-1] + J[:,:,1,iz])
      @views @. GradDy += 0.25 * (dXdxI[3,2,2,:,:,iz-1] + dXdxI[3,2,1,:,:,iz]) * (cC[:,:,iz] - cC[:,:,iz-1]) / 
      (J[:,:,2,iz-1] + J[:,:,1,iz])
    elseif iz < Nz
      @views @. GradDx += 0.25 * (dXdxI[3,1,2,:,:,iz] + dXdxI[:,:,1,iz+1,3,1]) * (cC[:,:,iz+1] - cC[:,:,iz]) /
      (J[:,:,2,iz] + J[:,:,1,iz+1])
      @views @. GradDy += 0.25 * (dXdxI[3,2,2,:,:,iz] + dXdxI[:,:,1,iz+1,3,2]) * (cC[:,:,iz+1] - cC[:,:,iz]) /
      (J[:,:,2,iz] + J[:,:,1,iz+1])
    end

    @. Div = 0
    @views @. temp = RhoC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * GradDx + 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * GradDy) 
    DerivativeX!(Div,temp,DW)
    @views @. temp = RhoC[:,:,iz] * ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * GradDx + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * GradDy)
    DerivativeY!(Div,temp,DW)

    @views @. F[:,:,iz] -= Koeff * Div 
  end    
end    

function DivGrad!(F,cC,Fe,dXdxI,J,ThreadCache,Koeff)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4 = ThreadCache
  Nz = size(F,3)
  D = Fe.DS
  DW = Fe.DW

  DxcC = TCacheC1[Threads.threadid()]
  DycC = TCacheC2[Threads.threadid()]
  GradDx = TCacheC3[Threads.threadid()]
  GradDy = TCacheC4[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  Div = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. DxcC = 0
    @. DycC = 0
    @views DerivativeX!(DxcC,cC[:,:,iz],D)
    @views DerivativeY!(DycC,cC[:,:,iz],D)

    @views @. GradDx = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxcC + 
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])
    @views @. GradDy = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxcC + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])

    @. Div = 0
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * GradDx + 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * GradDy 
    DerivativeX!(Div,temp,DW)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * GradDx + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * GradDy
    DerivativeY!(Div,temp,DW)

    @views @. F[:,:,iz] -= Koeff * Div 
  end    
end    

function DivGradHor!(F,cC,Fe,dXdxI,J,ThreadCache,Koeff)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4 = ThreadCache
  Nz = size(F,3)
  D = Fe.DS
  DW = Fe.DW

  DxcC = TCacheC1[Threads.threadid()]
  DycC = TCacheC2[Threads.threadid()]
  GradDx = TCacheC3[Threads.threadid()]
  GradDy = TCacheC4[Threads.threadid()]
  tempC = TCacheC3[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  Div = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. DxcC = 0
    @. DycC = 0
    @views @. tempC = cC[:,:,iz] 
    DerivativeX!(DxcC,tempC,D)
    DerivativeY!(DycC,tempC,D)

    @views @. GradDx = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxcC + 
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DycC) / 
      (J[:,:,1,iz] + J[:,:,2,iz])
    @views @. GradDy = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxcC + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DycC) /
      (J[:,:,1,iz] + J[:,:,2,iz])

    if iz > 1
      @views @. GradDx += 0.25 * (dXdxI[3,1,2,:,:,iz-1] + dXdxI[3,1,1,:,:,iz]) * (cC[:,:,iz] - cC[:,:,iz-1]) /
      (J[:,:,2,iz-1] + J[:,:,1,iz])
      @views @. GradDy += 0.25 * (dXdxI[3,2,2,:,:,iz-1] + dXdxI[3,2,1,:,:,iz]) * (cC[:,:,iz] - cC[:,:,iz-1]) / 
      (J[:,:,2,iz-1] + J[:,:,1,iz])
    elseif iz < Nz
      @views @. GradDx += 0.25 * (dXdxI[3,1,2,:,:,iz] + dXdxI[:,:,1,iz+1,3,1]) * (cC[:,:,iz+1] - cC[:,:,iz]) /
      (J[:,:,2,iz] + J[:,:,1,iz+1])
      @views @. GradDy += 0.25 * (dXdxI[3,2,2,:,:,iz] + dXdxI[:,:,1,iz+1,3,2]) * (cC[:,:,iz+1] - cC[:,:,iz]) /
      (J[:,:,2,iz] + J[:,:,1,iz+1])
    end
        
    
    @. Div = 0
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * GradDx + 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * GradDy
    DerivativeX!(Div,temp,DW)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * GradDx + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * GradDy
    DerivativeY!(Div,temp,DW)

    @views @. F[:,:,iz] -= Koeff * Div
  end    
end    

function DivRhoGrad!(F,cC,RhoC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4 = ThreadCache
  Nz = size(F,3)
  D = Fe.DS
  DW = Fe.DW

  DxcC = TCacheC1[Threads.threadid()]
  DycC = TCacheC2[Threads.threadid()]
  GradDx = TCacheC3[Threads.threadid()]
  GradDy = TCacheC4[Threads.threadid()]
  tempC = TCacheC3[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  Div = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. DxcC = 0
    @. DycC = 0
    @views @. tempC = cC[:,:,iz] / RhoC[:,:,iz]
    DerivativeX!(DxcC,tempC,D)
    DerivativeY!(DycC,tempC,D)

    @views @. GradDx = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxcC + 
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])
    @views @. GradDy = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxcC + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])

    @. Div = 0
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * GradDx + 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * GradDy
    DerivativeX!(Div,temp,DW)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * GradDx + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * GradDy
    DerivativeY!(Div,temp,DW)

    @views @. F[:,:,iz] = Div 
  end    
end    

function DivRhoGradE!(F,cC,RhoC,D,DW,dXdxI,J)
  Nz = size(F,3)
  N = size(F,1)
  FT = eltype(F)

  @. F = FT(0)
  @inbounds for iz = 1 : Nz
    @inbounds for j = 1 : N
      @inbounds for i = 1 : N  
        Dxc = FT(0)
        Dyc = FT(0)
        @inbounds for k = 1 : N  
          Dxc += D[i,k] * (cC[k,j,iz] / RhoC[k,j,iz])
          Dyc += D[j,k] * (cC[i,k,iz] / RhoC[i,k,iz])
        end
        GradDx = ((dXdxI[i,j,1,iz,1,1] + dXdxI[i,j,2,iz,1,1]) * Dxc + 
          (dXdxI[i,j,1,iz,2,1] + dXdxI[i,j,2,iz,2,1]) * Dyc) / (J[i,j,1,iz] + J[i,j,2,iz])
        GradDy = ((dXdxI[i,j,1,iz,1,2] + dXdxI[i,j,2,iz,1,2]) * Dxc + 
          (dXdxI[i,j,1,iz,2,2] + dXdxI[i,j,2,iz,2,2]) * Dyc) / (J[i,j,1,iz] + J[i,j,2,iz])
        tempx = (dXdxI[i,j,1,iz,1,1] + dXdxI[i,j,2,iz,1,1]) * GradDx + 
          (dXdxI[i,j,1,iz,1,2] + dXdxI[i,j,2,iz,1,2]) * GradDy
        tempy = (dXdxI[i,j,1,iz,2,1] + dXdxI[i,j,2,iz,2,1]) * GradDx + 
          (dXdxI[i,j,1,iz,2,2] + dXdxI[i,j,2,iz,2,2]) * GradDy
        for k = 1 : N
          F[k,j,iz] += DW[k,i] * tempx
          F[i,k,iz] += DW[k,j] * tempy
        end  
      end
    end  
  end    
end    

function DivRhoGradE!(F,cC,RhoC,D,DW,dXdxI,J,Koeff)
  Nz = size(F,3)
  N = size(F,1)
  FT = eltype(F)

  @inbounds for iz = 1 : Nz
    @inbounds for j = 1 : N
      @inbounds for i = 1 : N  
        Dxc = FT(0)
        Dyc = FT(0)
        @inbounds for k = 1 : N  
          Dxc += D[i,k] * cC[k,j,iz] 
          Dyc += D[j,k] * cC[i,k,iz]
        end
        GradDx = RhoC[i,j,iz] * ((dXdxI[i,j,1,iz,1,1] + dXdxI[i,j,2,iz,1,1]) * Dxc + 
          (dXdxI[i,j,1,iz,2,1] + dXdxI[i,j,2,iz,2,1]) * Dyc) / (J[i,j,1,iz] + J[i,j,2,iz])
        GradDy = RhoC[i,j,iz] * ((dXdxI[i,j,1,iz,1,2] + dXdxI[i,j,2,iz,1,2]) * Dxc + 
          (dXdxI[i,j,1,iz,2,2] + dXdxI[i,j,2,iz,2,2]) * Dyc) / (J[i,j,1,iz] + J[i,j,2,iz])
        tempx = (dXdxI[i,j,1,iz,1,1] + dXdxI[i,j,2,iz,1,1]) * GradDx + 
          (dXdxI[i,j,1,iz,1,2] + dXdxI[i,j,2,iz,1,2]) * GradDy
        tempy = (dXdxI[i,j,1,iz,2,1] + dXdxI[i,j,2,iz,2,1]) * GradDx + 
          (dXdxI[i,j,1,iz,2,2] + dXdxI[i,j,2,iz,2,2]) * GradDy
        for k = 1 : N
          F[k,j,iz] -= Koeff * DW[k,i] * tempx
          F[i,k,iz] -= Koeff * DW[k,j] * tempy
        end  
      end
    end  
  end    
end    



function DivRhoGradHor!(F,cC,RhoC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4 = ThreadCache
  Nz = size(F,3)
  D = Fe.DS
  DW = Fe.DW

  DxcC = TCacheC1[Threads.threadid()]
  DycC = TCacheC2[Threads.threadid()]
  GradDx = TCacheC3[Threads.threadid()]
  GradDy = TCacheC4[Threads.threadid()]
  tempC = TCacheC3[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  Div = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. DxcC = 0
    @. DycC = 0
    @views @. tempC = cC[:,:,iz] / RhoC[:,:,iz]
    DerivativeX!(DxcC,tempC,D)
    DerivativeY!(DycC,tempC,D)

    @views @. GradDx = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxcC + 
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])
    @views @. GradDy = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxcC + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])

    if iz > 1
      @views @. GradDx += 0.25 * (dXdxI[3,1,2,:,:,iz-1] + dXdxI[3,1,1,:,:,iz]) * 
        (cC[:,:,iz] / RhoC[:,:,iz] - cC[:,:,iz-1] / RhoC[:,:,iz-1]) /
        (J[:,:,2,iz-1] + J[:,:,1,iz])
      @views @. GradDy += 0.25 * (dXdxI[3,2,2,:,:,iz-1] + dXdxI[3,2,1,:,:,iz]) * 
        (cC[:,:,iz] / RhoC[:,:,iz] - cC[:,:,iz-1] / RhoC[:,:,iz-1]) / 
        (J[:,:,2,iz-1] + J[:,:,1,iz])
    elseif iz < Nz
      @views @. GradDx += 0.25 * (dXdxI[3,1,2,:,:,iz] + dXdxI[:,:,1,iz+1,3,1]) * 
        (cC[:,:,iz+1] / RhoC[:,:,iz+1] - cC[:,:,iz] / RhoC[:,:,iz]) /
        (J[:,:,2,iz] + J[:,:,1,iz+1])
      @views @. GradDy += 0.25 * (dXdxI[3,2,2,:,:,iz] + dXdxI[:,:,1,iz+1,3,2]) * 
        (cC[:,:,iz+1] / RhoC[:,:,iz+1] - cC[:,:,iz] / RhoC[:,:,iz]) /
        (J[:,:,2,iz] + J[:,:,1,iz+1])
    end

    @. Div = 0
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * GradDx + 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * GradDy
    DerivativeX!(Div,temp,DW)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * GradDx + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * GradDy
    DerivativeY!(Div,temp,DW)

    @views @. F[:,:,iz] = Div 
  end    
end    

function DivGrad!(F,cC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4 = ThreadCache
  Nz = size(F,3)
  D = Fe.DS
  DW = Fe.DW

  DxcC = TCacheC1[Threads.threadid()]
  DycC = TCacheC2[Threads.threadid()]
  GradDx = TCacheC3[Threads.threadid()]
  GradDy = TCacheC4[Threads.threadid()]
  tempC = TCacheC3[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  Div = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. DxcC = 0
    @. DycC = 0
    @views @. tempC = cC[:,:,iz] 
    DerivativeX!(DxcC,tempC,D)
    DerivativeY!(DycC,tempC,D)

    @views @. GradDx = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxcC + 
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])
    @views @. GradDy = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxcC + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DycC) / (J[:,:,1,iz] + J[:,:,2,iz])

    @. Div = 0
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * GradDx + 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * GradDy
    DerivativeX!(Div,temp,DW)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * GradDx + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * GradDy
    DerivativeY!(Div,temp,DW)

    @views @. F[:,:,iz] = Div 
  end    
end    

function DivGradHor!(F,cC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4 = ThreadCache
  Nz = size(F,3)
  D = Fe.DS
  DW = Fe.DW

  DxcC = TCacheC1[Threads.threadid()]
  DycC = TCacheC2[Threads.threadid()]
  GradDx = TCacheC3[Threads.threadid()]
  GradDy = TCacheC4[Threads.threadid()]
  tempC = TCacheC3[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  Div = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. DxcC = 0
    @. DycC = 0
    @views @. tempC = cC[:,:,iz] 
    DerivativeX!(DxcC,tempC,D)
    DerivativeY!(DycC,tempC,D)

    @views @. GradDx = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxcC + 
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DycC) / 
      (J[:,:,1,iz] + J[:,:,2,iz])
    @views @. GradDy = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxcC + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DycC) /
      (J[:,:,1,iz] + J[:,:,2,iz])

    if iz > 1
      @views @. GradDx += 0.25 * (dXdxI[3,1,2,:,:,iz-1] + dXdxI[3,1,1,:,:,iz]) * (cC[:,:,iz] - cC[:,:,iz-1]) /
      (J[:,:,2,iz-1] + J[:,:,1,iz])
      @views @. GradDy += 0.25 * (dXdxI[3,2,2,:,:,iz-1] + dXdxI[3,2,1,:,:,iz]) * (cC[:,:,iz] - cC[:,:,iz-1]) / 
      (J[:,:,2,iz-1] + J[:,:,1,iz])
    elseif iz < Nz
      @views @. GradDx += 0.25 * (dXdxI[3,1,2,:,:,iz] + dXdxI[:,:,1,iz+1,3,1]) * (cC[:,:,iz+1] - cC[:,:,iz]) /
      (J[:,:,2,iz] + J[:,:,1,iz+1])
      @views @. GradDy += 0.25 * (dXdxI[3,2,2,:,:,iz] + dXdxI[:,:,1,iz+1,3,2]) * (cC[:,:,iz+1] - cC[:,:,iz]) /
      (J[:,:,2,iz] + J[:,:,1,iz+1])
    end
        
    
    @. Div = 0
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * GradDx + 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * GradDy
    DerivativeX!(Div,temp,DW)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * GradDx + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * GradDy
    DerivativeY!(Div,temp,DW)

    @views @. F[:,:,iz] = Div 
  end    
end    

function DivGradF!(F,cF,RhoC,Fe,dXdxI,J,ThreadCache,Koeff)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4 = ThreadCache
  Nz = size(F,3) - 1
  D = Fe.DS
  DW = Fe.DW

  DxcF = TCacheC1[Threads.threadid()]
  DycF = TCacheC2[Threads.threadid()]
  GradDx = TCacheC3[Threads.threadid()]
  GradDy = TCacheC4[Threads.threadid()]
  tempF = TCacheC3[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  Div = TCacheC2[Threads.threadid()]

  @inbounds for iz = 2 : Nz
    @. DxcF = 0
    @. DycF = 0
    @views DerivativeX!(DxcF,cF[:,:,iz],D)
    @views DerivativeY!(DycF,cF[:,:,iz],D)

    @views @. GradDx = ((dXdxI[1,1,2,:,:,iz-1] + dXdxI[1,1,1,:,:,iz]) * DxcF + 
      (dXdxI[2,1,2,:,:,iz-1] + dXdxI[2,1,1,:,:,iz]) * DycF) / (J[:,:,2,iz-1] + J[:,:,1,iz])
    @views @. GradDy = ((dXdxI[1,2,2,:,:,iz-1] + dXdxI[1,2,1,:,:,iz]) * DxcF + 
      (dXdxI[2,2,2,:,:,iz-1] + dXdxI[2,2,1,:,:,iz]) * DycF) / (J[:,:,2,iz-1] + J[:,:,1,iz])

    @. Div = 0
    @views @. temp = (dXdxI[1,1,2,:,:,iz-1] + dXdxI[1,1,1,:,:,iz]) * GradDx + 
      (dXdxI[1,2,2,:,:,iz-1] + dXdxI[1,2,1,:,:,iz]) * GradDy 
    DerivativeX!(Div,temp,DW)
    @views @. temp = (dXdxI[2,1,2,:,:,iz-1] + dXdxI[2,1,1,:,:,iz]) * GradDx + 
      (dXdxI[2,2,2,:,:,iz-1] + dXdxI[2,2,1,:,:,iz]) * GradDy
    DerivativeY!(Div,temp,DW)

    @views @. F[:,:,iz] -= 1/2 * (RhoC[:,:,iz-1] + RhoC[:,:,iz]) * Koeff * Div 
  end    
end    

function DivGradF!(F,cF,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4 = ThreadCache
  Nz = size(F,3) - 1
  D = Fe.DS
  DW = Fe.DW

  DxcF = TCacheC1[Threads.threadid()]
  DycF = TCacheC2[Threads.threadid()]
  GradDx = TCacheC3[Threads.threadid()]
  GradDy = TCacheC4[Threads.threadid()]
  tempF = TCacheC3[Threads.threadid()]
  temp = TCacheC1[Threads.threadid()]
  Div = TCacheC2[Threads.threadid()]

  @inbounds for iz = 2 : Nz
    @. DxcF = 0
    @. DycF = 0
    @views DerivativeX!(DxcF,cF[:,:,iz],D)
    @views DerivativeY!(DycF,cF[:,:,iz],D)

    @views @. GradDx = ((dXdxI[1,1,2,:,:,iz-1] + dXdxI[1,1,1,:,:,iz]) * DxcF + 
      (dXdxI[2,1,2,:,:,iz-1] + dXdxI[2,1,1,:,:,iz]) * DycF) / (J[:,:,2,iz-1] + J[:,:,1,iz])
    @views @. GradDy = ((dXdxI[1,2,2,:,:,iz-1] + dXdxI[1,2,1,:,:,iz]) * DxcF + 
      (dXdxI[2,2,2,:,:,iz-1] + dXdxI[2,2,1,:,:,iz]) * DycF) / (J[:,:,2,iz-1] + J[:,:,1,iz])

    @. Div = 0
    @views @. temp = (dXdxI[1,1,2,:,:,iz-1] + dXdxI[1,1,1,:,:,iz]) * GradDx + 
      (dXdxI[1,2,2,:,:,iz-1] + dXdxI[1,2,1,:,:,iz]) * GradDy 
    DerivativeX!(Div,temp,DW)
    @views @. temp = (dXdxI[2,1,2,:,:,iz-1] + dXdxI[2,1,1,:,:,iz]) * GradDx + 
      (dXdxI[2,2,2,:,:,iz-1] + dXdxI[2,2,1,:,:,iz]) * GradDy
    DerivativeY!(Div,temp,DW)

    @views @. F[:,:,iz] = Div 
  end    
end    

function GradDiv!(FuC,FvC,uC,vC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3 = ThreadCache
  Nz = size(FuC,3)
  D = Fe.DS
  DW = Fe.DW

  Div = TCacheC1[Threads.threadid()]
  temp = TCacheC2[Threads.threadid()]
  DxDiv  = TCacheC2[Threads.threadid()]
  DyDiv  = TCacheC3[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. Div = 0  
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * vC[:,:,iz]
    DerivativeX!(Div,temp,D)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * uC[:,:,iz] + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * vC[:,:,iz]
    DerivativeY!(Div,temp,D)

    @views @. Div /= (J[:,:,1,iz] + J[:,:,2,iz])

    @. DxDiv = 0
    @. DyDiv = 0
    DerivativeX!(DxDiv,Div,DW)
    DerivativeY!(DyDiv,Div,DW)

    @views @. FuC[:,:,iz] = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxDiv +
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DyDiv) 
    @views @. FvC[:,:,iz] = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxDiv +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DyDiv) 
  end  
end  

function GradDiv!(FuC,FvC,RhouC,RhovC,RhoC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3 = ThreadCache
  Nz = size(FuC,3)
  D = Fe.DS
  DW = Fe.DW

  Div = TCacheC1[Threads.threadid()]
  temp = TCacheC2[Threads.threadid()]
  DxDiv  = TCacheC2[Threads.threadid()]
  DyDiv  = TCacheC3[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. Div = 0  
    @views @. temp = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * RhouC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * RhovC[:,:,iz]) / RhoC[:,:,iz]
    DerivativeX!(Div,temp,D)
    @views @. temp = ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * RhouC[:,:,iz] + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * RhovC[:,:,iz]) / RhoC[:,:,iz]
    DerivativeY!(Div,temp,D)

    @views @. Div /= (J[:,:,1,iz] + J[:,:,2,iz]) 

    @. DxDiv = 0
    @. DyDiv = 0
    DerivativeX!(DxDiv,Div,DW)
    DerivativeY!(DyDiv,Div,DW)

    @views @. FuC[:,:,iz] = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxDiv +
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DyDiv)
    @views @. FvC[:,:,iz] = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxDiv +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DyDiv)
  end  
end  

function GradDiv!(FuC,FvC,uC,vC,RhoC,Fe,dXdxI,J,ThreadCache,Koeff)
  @unpack TCacheC1, TCacheC2, TCacheC3 = ThreadCache
  Nz = size(FuC,3)
  D = Fe.DS
  DW = Fe.DW

  Div = TCacheC1[Threads.threadid()]
  temp = TCacheC2[Threads.threadid()]
  DxDiv  = TCacheC2[Threads.threadid()]
  DyDiv  = TCacheC3[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. Div = 0  
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * vC[:,:,iz]
    DerivativeX!(Div,temp,D)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * uC[:,:,iz] + 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * vC[:,:,iz]
    DerivativeY!(Div,temp,D)

    @views @. Div /= (J[:,:,1,iz] + J[:,:,2,iz])

    @. DxDiv = 0
    @. DyDiv = 0
    DerivativeX!(DxDiv,Div,DW)
    DerivativeY!(DyDiv,Div,DW)

    @views @. FuC[:,:,iz] -= Koeff * RhoC[:,:,iz] * ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxDiv +
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DyDiv) 
    @views @. FvC[:,:,iz] -= Koeff * RhoC[:,:,iz] * ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxDiv +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DyDiv) 
  end  
end  

function RotCurl!(FuC,FvC,uC,vC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3 = ThreadCache
  Nz = size(FuC,3)
  D = Fe.DS
  DW = Fe.DW

  W = TCacheC1[Threads.threadid()]
  temp = TCacheC2[Threads.threadid()]
  DxW = TCacheC2[Threads.threadid()]
  DyW = TCacheC3[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. W = 0
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * vC[:,:,iz] - 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * uC[:,:,iz]
    DerivativeX!(W,temp,D)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * vC[:,:,iz] - 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * uC[:,:,iz]
    DerivativeY!(W,temp,D)
    
    @views @. W /= (J[:,:,1,iz] + J[:,:,2,iz])

    @. DxW = 0
    @. DyW = 0
    DerivativeX!(DxW,W,DW)
    DerivativeY!(DyW,W,DW)
    @views @. FvC[:,:,iz] = (-(dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxW -
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DyW)
    @views @. FuC[:,:,iz] = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxW +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DyW)
  end   
end   

function RotCurl!(FuC,FvC,RhouC,RhovC,RhoC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3 = ThreadCache
  Nz = size(FuC,3)
  D = Fe.DS
  DW = Fe.DW

  W = TCacheC1[Threads.threadid()]
  temp = TCacheC2[Threads.threadid()]
  DxW = TCacheC2[Threads.threadid()]
  DyW = TCacheC3[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. W = 0
    @views @. temp = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * RhovC[:,:,iz] - 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * RhouC[:,:,iz]) / RhoC[:,:,iz]
    DerivativeX!(W,temp,D)
    @views @. temp = ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * RhovC[:,:,iz] - 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * RhouC[:,:,iz]) / RhoC[:,:,iz]
    DerivativeY!(W,temp,D)

    @. @views W /= (J[:,:,1,iz] + J[:,:,2,iz])

    @. DxW = 0
    @. DyW = 0
    DerivativeX!(DxW,W,DW)
    DerivativeY!(DyW,W,DW)
    @views @. FvC[:,:,iz] = (-(dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxW -
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DyW)
    @views @. FuC[:,:,iz] = ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxW +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DyW)
  end   
end   

function RotCurl!(FuC,FvC,uC,vC,RhoC,Fe,dXdxI,J,ThreadCache,Koeff)
  @unpack TCacheC1, TCacheC2, TCacheC3 = ThreadCache
  Nz = size(FuC,3)
  D = Fe.DS
  DW = Fe.DW

  W = TCacheC1[Threads.threadid()]
  temp = TCacheC2[Threads.threadid()]
  DxW = TCacheC2[Threads.threadid()]
  DyW = TCacheC3[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. W = 0
    @views @. temp = (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * vC[:,:,iz] - 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * uC[:,:,iz]
    DerivativeX!(W,temp,D)
    @views @. temp = (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * vC[:,:,iz] - 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * uC[:,:,iz]
    DerivativeY!(W,temp,D)

    @. @views W /= (J[:,:,1,iz] + J[:,:,2,iz])

    @. DxW = 0
    @. DyW = 0
    DerivativeX!(DxW,W,DW)
    DerivativeY!(DyW,W,DW)
    @views @. FvC[:,:,iz] -= Koeff * RhoC[:,:,iz] * (-(dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxW -
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DyW)
    @views @. FuC[:,:,iz] -= Koeff * RhoC[:,:,iz] * ((dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxW +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DyW)
  end   
end   

function Buoyancy!(FwF,RhoC,J,Phys)

  @views @. FwF[:,:,2:end-1] -= Phys.Grav *
    (RhoC[:,:,1:end-1] * J[:,:,2,1:end-1] +
    RhoC[:,:,2:end] * J[:,:,1,2:end])

end

function DivConvRhoTrColumnOld!(FRhoTrC,uC,vC,wF,RhoTrC,RhoC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4, TCacheC5,  TCacheCol1 = ThreadCache
  Nz = size(uC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS
  S = Fe.S
  w = Fe.w
  uCLoc = TCacheC1[Threads.threadid()]
  @views FluxLowX = TCacheC1[Threads.threadid()][1:end-1,:]
  TempH = TCacheC2[Threads.threadid()]
  @views dxF = TCacheC2[Threads.threadid()][:,1]
  @views e = TCacheC2[Threads.threadid()][1:end-2,1]
  @views FluxX = TCacheC2[Threads.threadid()][1:end-1,:]
  @views FluxHighX = TCacheC3[Threads.threadid()][1:end-1,:]
  @views uCL = TCacheC4[Threads.threadid()][1:end-1,:]
  @views dxC = TCacheC4[Threads.threadid()][1:end-1,1]
  @views alphaX = TCacheC5[Threads.threadid()][1:end-1,:]

  vCLoc = TCacheC1[Threads.threadid()]
  @views FluxLowY = TCacheC1[Threads.threadid()][:,1:end-1]
  @views dyF = TCacheC2[Threads.threadid()][:,1]
  @views FluxY = TCacheC2[Threads.threadid()][:,1:end-1]
  @views FluxHighY = TCacheC3[Threads.threadid()][:,1:end-1]
  @views vCL = TCacheC4[Threads.threadid()][:,1:end-1]
  @views dyC = TCacheC4[Threads.threadid()][1:end-1,1]
  @views alphaY = TCacheC5[Threads.threadid()][:,1:end-1]

  @inbounds for iz = 1 : Nz  
    @views @. uCLoc =  ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * vC[:,:,iz] + 
      dXdxI[1,3,1,:,:,iz] * wF[:,:,iz] + dXdxI[1,3,2,:,:,iz] * wF[:,:,iz+1])
    @views @. TempH = uCLoc * RhoTrC[:,:,iz]   
    FluxX!(FluxHighX,TempH,S)
    @inbounds for j = 1 : OrdPoly + 1
      @views @. FluxHighX[:,j] *= w[j]
    end  

    @views @. uCL = 1/2 * (uCLoc[1:end-1,:] * RhoC[1:end-1,:,iz] + uCLoc[2:end,:] * RhoC[2:end,:,iz])
    @views @. FluxLowX = -1/2 *  ((abs(uCL) + uCL) * RhoTrC[1:end-1,:,iz] / RhoC[1:end-1,:,iz] +
            (uCL - abs(uCL)) * RhoTrC[2:end,:,iz] / RhoC[2:end,:,iz])
    @inbounds for j = 1 : OrdPoly + 1
      @views @. FluxLowX[:,j] *= w[j]
    end  
    @inbounds for j = 1 : OrdPoly + 1
      @views @. dxF = 1/2 * w * (J[:,j,1,iz] + J[:,j,2,iz])
      dxF[1] = 2 * dxF[1]
      dxF[end] = 2 * dxF[end]
      @views @.  dxC = 1/2*(dxF[1:end-1] + dxF[2:end])
      @views Error!(e,RhoTrC[:,j,iz],dxC)
      @. e = min(e,1)
      alphaX[1,j] = e[1]
      @views @. alphaX[2:end-1,j] = max(e[1:end-1],e[2:end])
      alphaX[end,j] = e[end]
    end
    @. alphaX = 0
    @. FluxX = alphaX * FluxLowX + (1 - alphaX) * FluxHighX
    @views @. FRhoTrC[1,:,iz] += FluxX[1,:] 
    @views @. FRhoTrC[2:end-1,:,iz] += FluxX[2:end,:] - FluxX[1:end-1,:] 
    @views @. FRhoTrC[end,:,iz] += -FluxX[end,:]

    @views @. vCLoc =  ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * vC[:,:,iz] + 
      dXdxI[2,3,1,:,:,iz] * wF[:,:,iz] + dXdxI[2,3,2,:,:,iz] * wF[:,:,iz+1])
    @views @. TempH = vCLoc * RhoTrC[:,:,iz]
    FluxY!(FluxHighY,TempH,S)
    @inbounds for i = 1 : OrdPoly + 1
      @views @. FluxHighY[i,:] *= w[i]
    end  

    @views @. vCL = 1/2 * (vCLoc[:,1:end-1] * RhoC[:,1:end-1,iz] + vCLoc[:,2:end] * RhoTrC[:,2:end,iz])
    @views @. FluxLowY = -1/2 *  ((abs(vCL) + vCL) * RhoTrC[:,1:end-1,iz] / RhoC[:,1:end-1,iz] +
      (vCL - abs(vCL)) * RhoTrC[:,2:end,iz] / RhoC[:,2:end,iz])
    @inbounds for i = 1 : OrdPoly + 1
      @views @. FluxLowY[i,:] *= w[i]
    end  
    @inbounds for i = 1 : OrdPoly + 1
      @views @. dyF = 1/2 * w * (J[i,:,1,iz] + J[i,:,2,iz])
      dyF[1] = 2 * dyF[1]
      dyF[end] = 2 * dyF[end]
      @views @. dyC = 1/2 * (dyF[1:end-1] + dyF[2:end])
      @views Error!(e,RhoTrC[i,:,iz],dyC)
      @. e = min(e,1)
      alphaY[i,1] = e[1]
      @views @. alphaY[i,2:end-1] = max(e[1:end-1],e[2:end])
      alphaY[i,end] = e[end]
    end

    @. alphaY = 0
    @. FluxY = alphaY * FluxLowY + (1 - alphaY) * FluxHighY
    @views @. FRhoTrC[:,1,iz] += FluxY[:,1]
    @views @. FRhoTrC[:,2:end-1,iz] += FluxY[:,2:end] - FluxY[:,1:end-1] 
    @views @. FRhoTrC[:,end,iz] += -FluxY[:,end]
  end    
end
function DivConvRhoTrColumn!(FRhoTrC,uC,vC,wF,RhoTrC,RhoC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4, TCacheC5,  TCacheCol1 = ThreadCache
  Nz = size(uC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS
  S = Fe.S
  w = Fe.w
  uCLoc = TCacheC1[Threads.threadid()]
  @views FluxLowX = TCacheC1[Threads.threadid()][1:end-1,:]
  TempH = TCacheC2[Threads.threadid()]
  @views dxF = TCacheC2[Threads.threadid()][:,1]
  @views e = TCacheC2[Threads.threadid()][1:end-2,1]
  @views FluxX = TCacheC2[Threads.threadid()][1:end-1,:]
  @views FluxHighX = TCacheC3[Threads.threadid()][1:end-1,:]
  @views uCL = TCacheC4[Threads.threadid()][1:end-1,:]
  @views dxC = TCacheC4[Threads.threadid()][1:end-1,1]
  @views alphaX = TCacheC5[Threads.threadid()][1:end-1,:]

  vCLoc = TCacheC1[Threads.threadid()]
  @views FluxLowY = TCacheC1[Threads.threadid()][:,1:end-1]
  @views dyF = TCacheC2[Threads.threadid()][:,1]
  @views FluxY = TCacheC2[Threads.threadid()][:,1:end-1]
  @views FluxHighY = TCacheC3[Threads.threadid()][:,1:end-1]
  @views vCL = TCacheC4[Threads.threadid()][:,1:end-1]
  @views dyC = TCacheC4[Threads.threadid()][1:end-1,1]
  @views alphaY = TCacheC5[Threads.threadid()][:,1:end-1]

  @inbounds for iz = 1 : Nz  
    @views @. uCLoc =  ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * vC[:,:,iz] + 
      dXdxI[1,3,1,:,:,iz] * wF[:,:,iz] + dXdxI[1,3,2,:,:,iz] * wF[:,:,iz+1])
    @views @. TempH = uCLoc * RhoTrC[:,:,iz]   
    FluxX!(FluxHighX,TempH,S)
    @inbounds for j = 1 : OrdPoly + 1
      @views @. FluxHighX[:,j] *= w[j]
    end  

    @views @. TempH = -uCLoc * RhoC[:,:,iz]   
    FluxX!(uCL,TempH,S)
    #@views @. uCL = 1/2 * (uCLoc[1:end-1,:] * RhoC[1:end-1,:,iz] + uCLoc[2:end,:] * RhoC[2:end,:,iz])
    @views @. FluxLowX = -1/2 *  ((abs(uCL) + uCL) * RhoTrC[1:end-1,:,iz] / RhoC[1:end-1,:,iz] +
            (uCL - abs(uCL)) * RhoTrC[2:end,:,iz] / RhoC[2:end,:,iz])
    @inbounds for j = 1 : OrdPoly + 1
      @views @. FluxLowX[:,j] *= w[j]
    end  
    @inbounds for j = 1 : OrdPoly + 1
      @views @. dxF = 1/2 * w * (J[:,j,1,iz] + J[:,j,2,iz])
      dxF[1] = 2 * dxF[1]
      dxF[end] = 2 * dxF[end]
      @views @.  dxC = 1/2*(dxF[1:end-1] + dxF[2:end])
      @views Error!(e,RhoTrC[:,j,iz],dxC)
      @. e = min(e,1)
      alphaX[1,j] = e[1]
      @views @. alphaX[2:end-1,j] = max(e[1:end-1],e[2:end])
      alphaX[end,j] = e[end]
    end

    @. FluxX = alphaX * FluxLowX + (1 - alphaX) * FluxHighX
    @inbounds for j = 1 : OrdPoly + 1
      FRhoTrC[1,j,iz] += FluxX[1,j] / (w[1] * w[j]) 
      @views @. FRhoTrC[2:end-1,j,iz] += (FluxX[2:end,j] - FluxX[1:end-1,j]) / (w[2:end-1] * w[j]) 
      FRhoTrC[end,j,iz] += -FluxX[end,j] / (w[end] * w[j])
    end
    @views @. vCLoc =  ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * uC[:,:,iz] +
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * vC[:,:,iz] + 
      dXdxI[2,3,1,:,:,iz] * wF[:,:,iz] + dXdxI[2,3,2,:,:,iz] * wF[:,:,iz+1])
    @views @. TempH = vCLoc * RhoTrC[:,:,iz]
    FluxY!(FluxHighY,TempH,S)
    @inbounds for i = 1 : OrdPoly + 1
      @views @. FluxHighY[i,:] *= w[i]
    end  

    @views @. TempH = -vCLoc * RhoC[:,:,iz]   
    FluxY!(vCL,TempH,S)
    #@views @. vCL = 1/2 * (vCLoc[:,1:end-1] * RhoC[:,1:end-1,iz] + vCLoc[:,2:end] * RhoC[:,2:end,iz])
    @views @. FluxLowY = -1/2 *  ((abs(vCL) + vCL) * RhoTrC[:,1:end-1,iz] / RhoC[:,1:end-1,iz] +
      (vCL - abs(vCL)) * RhoTrC[:,2:end,iz] / RhoC[:,2:end,iz])
    @inbounds for i = 1 : OrdPoly + 1
      @views @. FluxLowY[i,:] *= w[i]
    end  
    @inbounds for i = 1 : OrdPoly + 1
      @views @. dyF = 1/2 * w * (J[i,:,1,iz] + J[i,:,2,iz])
      dyF[1] = 2 * dyF[1]
      dyF[end] = 2 * dyF[end]
      @views @. dyC = 1/2 * (dyF[1:end-1] + dyF[2:end])
      @views Error!(e,RhoTrC[i,:,iz],dyC)
      @. e = min(e,1)
      alphaY[i,1] = e[1]
      @views @. alphaY[i,2:end-1] = max(e[1:end-1],e[2:end])
      alphaY[i,end] = e[end]
    end

    @. FluxY = alphaY * FluxLowY + (1 - alphaY) * FluxHighY
    @inbounds for i = 1 : OrdPoly +1
      FRhoTrC[i,1,iz] += FluxY[i,1] / (w[1] * w[i])
      @views @. FRhoTrC[i,2:end-1,iz] += (FluxY[i,2:end] - FluxY[i,1:end-1]) / (w[2:end-1] * w[i])
      FRhoTrC[i,end,iz] += -FluxY[i,end] / (w[end] * w[i])
    end
  end    
end

function DivConvRhoTrCell!(FRhoTrC,uC,vC,wFB,wFT,RhoTrC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3, TCacheC4, TCacheC5,  TCacheCol1 = ThreadCache
  OrdPoly = Fe.OrdPoly
  D = Fe.DS
  S = Fe.S
  w = Fe.w
  uCLoc = TCacheC1[Threads.threadid()]
  @views FluxLowX = TCacheC1[Threads.threadid()][1:end-1,:]
  TempH = TCacheC2[Threads.threadid()]
  @views dxF = TCacheC2[Threads.threadid()][:,1]
  @views e = TCacheC2[Threads.threadid()][1:end-2,1]
  @views FluxX = TCacheC2[Threads.threadid()][1:end-1,:]
  @views FluxHighX = TCacheC3[Threads.threadid()][1:end-1,:]
  @views uCL = TCacheC4[Threads.threadid()][1:end-1,:]
  @views dxC = TCacheC4[Threads.threadid()][1:end-1,1]
  @views alphaX = TCacheC5[Threads.threadid()][1:end-1,:]

  vCLoc = TCacheC1[Threads.threadid()]
  @views FluxLowY = TCacheC1[Threads.threadid()][:,1:end-1]
  @views dyF = TCacheC2[Threads.threadid()][:,1]
  @views FluxY = TCacheC2[Threads.threadid()][:,1:end-1]
  @views FluxHighY = TCacheC3[Threads.threadid()][:,1:end-1]
  @views vCL = TCacheC4[Threads.threadid()][:,1:end-1]
  @views dyC = TCacheC4[Threads.threadid()][1:end-1,1]
  @views alphaY = TCacheC5[Threads.threadid()][:,1:end-1]


  @views @. uCLoc =  ((dXdxI[:,:,1,1,1] + dXdxI[:,:,2,1,1]) * uC[:,:] +
    (dXdxI[:,:,1,1,2] + dXdxI[:,:,2,1,2]) * vC[:,:] + 
    dXdxI[:,:,1,1,3] * wFB[:,:] + dXdxI[:,:,2,1,3] * wFT[:,:])
  @views @. TempH = uCLoc * RhoTrC[:,:]   
  FluxX!(FluxHighX,TempH,S)

  @views @. uCL = 1/2 * (uCLoc[1:end-1,:] + uCLoc[2:end,:])
  @views @. FluxLowX = -1/2 *  ((abs(uCL) + uCL) * RhoTrC[1:end-1,:] +
          (uCL - abs(uCL)) * RhoTrC[2:end,:])
  @inbounds for j = 1 : OrdPoly + 1
    @views @. dxF = 1/2 * w * (J[:,j,1] + J[:,j,2])
    dxF[1] = 2 * dxF[1]
    dxF[end] = 2 * dxF[end]
    @views @.  dxC = 1/2*(dxF[1:end-1] + dxF[2:end])
    @views Error!(e,RhoTrC[:,j],dxC)
    @. e = min(e,1)
    alphaX[1,j] = e[1]
    @views @. alphaX[2:end-1,j] = max(e[1:end-1],e[2:end])
    alphaX[end,j] = e[end]
  end
  @. FluxX = alphaX * FluxLowX + (1 - alphaX) * FluxHighX
  @inbounds for j = 1 : OrdPoly + 1
    FRhoTrC[1,j] += FluxX[1,j] / (w[1]) 
    @inbounds for i = 2 : OrdPoly
      FRhoTrC[i,j] += (FluxX[i,j] - FluxX[i-1,j]) / (w[i]) 
    end  
    FRhoTrC[end,j] += -FluxX[end,j] / (w[end])
  end  

  @views @. vCLoc =  ((dXdxI[:,:,1,2,1] + dXdxI[:,:,2,2,1]) * uC[:,:] +
    (dXdxI[:,:,1,2,2] + dXdxI[:,:,2,2,2]) * vC[:,:] + 
    dXdxI[:,:,1,2,3] * wFB[:,:] + dXdxI[:,:,2,2,3] * wFT[:,:])
  @views @. TempH = vCLoc * RhoTrC[:,:]
  FluxY!(FluxHighY,TempH,S)

  @views @. vCL = 1/2 * (vCLoc[:,1:end-1] + vCLoc[:,2:end])
  @views @. FluxLowY = -1/2 *  ((abs(vCL) + vCL) * RhoTrC[:,1:end-1] +
    (vCL - abs(vCL)) * RhoTrC[:,2:end])
  @inbounds for i = 1 : OrdPoly + 1
    @views @. dyF = 1/2 * w * (J[i,:,1] + J[i,:,2])
    dyF[1] = 2 * dyF[1]
    dyF[end] = 2 * dyF[end]
    @views @. dyC = 1/2 * (dyF[1:end-1] + dyF[2:end])
    @views Error!(e,RhoTrC[i,:],dyC)
    @. e = min(e,1)
    alphaY[i,1] = e[1]
    @views @. alphaY[i,2:end-1] = max(e[1:end-1],e[2:end])
    alphaY[i,end] = e[end]
  end

  @. FluxY = alphaY * FluxLowY + (1 - alphaY) * FluxHighY
  @inbounds for i = 1 : OrdPoly + 1
    FRhoTrC[i,1] += FluxY[i,1] / w[1]
    @inbounds for j = 2 : OrdPoly
      FRhoTrC[i,j] += (FluxY[i,j] - FluxY[i,j-1]) / w[j] 
    end  
    FRhoTrC[i,end] += -FluxY[i,end] / w[end]
  end  
end

function SourceIntEnergy!(F,cCG,uC,vC,wF,Fe,dXdxI,ThreadCache)
  @unpack TCacheC1, TCacheC2 = ThreadCache
  Nz = size(uC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  vCon = TCacheC1[Threads.threadid()]
  DvCon = TCacheC2[Threads.threadid()]
  vConV = TCacheC1[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. DvCon = 0 
    @views @. vCon = uC[:,:,iz] * (dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) +
      vC[:,:,iz] * (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) +
      dXdxI[1,3,1,:,:,iz] * wF[:,:,iz] + dXdxI[1,3,2,:,:,iz] * wF[:,:,iz+1]
    DerivativeX!(DvCon,vCon,D)  
    @views @. vCon = uC[:,:,iz] * (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) + 
      vC[:,:,iz] * (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) +
      dXdxI[2,3,1,:,:,iz] * wF[:,:,iz] + dXdxI[2,3,2,:,:,iz] * wF[:,:,iz+1]
    DerivativeY!(DvCon,vCon,D)  
    @views @. F[:,:,iz]  -= DvCon * cCG[:,:,iz]
  end
  @inbounds for iz = 1 : Nz - 1
    @views @. vConV = uC[:,:,iz] * dXdxI[3,1,2,:,:,iz] + uC[:,:,iz+1] * dXdxI[:,:,1,iz+1,3,1] +
      vC[:,:,iz] * dXdxI[3,2,2,:,:,iz] + vC[:,:,iz+1] * dXdxI[:,:,1,iz+1,3,2] +
      wF[:,:,iz+1] * (dXdxI[3,3,2,:,:,iz] + dXdxI[:,:,1,iz+1,3,3])
    @views @. F[:,:,iz] -= 1/2 * vConV * cCG[:,:,iz]
    @views @. F[:,:,iz+1] += 1/2 * vConV * cCG[:,:,iz+1]
  end
#Note improve lower boundary condition, pressure extrapolation, but contravriant velocity is zero at the lower boundary 
end

function Rot!(Rot,uC,vC,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheC3 = ThreadCache

  Nz = size(Rot,3)
  D = Fe.DS

  W = TCacheC1[Threads.threadid()]
  temp = TCacheC2[Threads.threadid()]

  @inbounds for iz = 1 : Nz
    @. W = 0
    @views @. temp = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * vC[:,:,iz] - 
      (dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * uC[:,:,iz])
    DerivativeX!(W,temp,D)
    @views @. temp = ((dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * vC[:,:,iz] - 
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * uC[:,:,iz])
    DerivativeY!(W,temp,D)
    @views @. Rot[:,:,iz] = W / (J[:,:,1,iz] + J[:,:,2,iz])
  end  
end

function Curl!(uC,vC,Psi,Fe,dXdxI,J,ThreadCache)
  @unpack TCacheC1, TCacheC2 = ThreadCache

  Nz = size(Psi,3)
  D = Fe.DS

  DxPsi = TCacheC1[Threads.threadid()]
  DyPsi = TCacheC2[Threads.threadid()]


  @inbounds for iz = 1 : Nz
    @. DxPsi = 0
    @views DerivativeX!(DxPsi,Psi[:,:,iz],D)
    @. DyPsi = 0
    @views DerivativeY!(DyPsi,Psi[:,:,iz],D)
    @views @. vC[:,:,iz] = ((dXdxI[1,1,1,:,:,iz] + dXdxI[1,1,2,:,:,iz]) * DxPsi +
      (dXdxI[2,1,1,:,:,iz] + dXdxI[2,1,2,:,:,iz]) * DyPsi) / 
      (J[:,:,1,iz] + J[:,:,2,iz])
    @views @. uC[:,:,iz] = (-(dXdxI[1,2,1,:,:,iz] + dXdxI[1,2,2,:,:,iz]) * DxPsi -
      (dXdxI[2,2,1,:,:,iz] + dXdxI[2,2,2,:,:,iz]) * DyPsi) / 
      (J[:,:,1,iz] + J[:,:,2,iz])
  end  
end

function VerticalGradient(Gradu,Gradv,Gradw,cC,
  Fe,dXdxI,ThreadCache)
  @unpack TCacheC1, TCacheCol1, TCacheCol2, TCacheCol3 = ThreadCache
  Nz = size(cC,4)

  GraduF = TCacheCol1[Threads.threadid()]
  GraduF = TCacheCol2[Threads.threadid()]
  GradwF = TCacheCol3[Threads.threadid()]
  GradZ = TCacheC1[Threads.threadid()]
 
  @. GraduF = 0
  @. GradvF = 0
  @. GradwF = 0
  @inbounds for iz = 2 : Nz
    @views @. GradZ = 1/2 * (cC[:,:,1,iz] - cC[:,:,2,iz-1])
    @views @. GraduF[:,:,2,iz-1] -= GradZ * dXdxI[3,1,2,:,:,iz-1]
    @views @. GraduF[:,:,1,iz] -= GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. GradvF[:,:,2,iz-1] -= GradZ * dXdxI[3,2,2,:,:,iz-1]
    @views @. GradvF[:,:,1,iz] -= GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. GradwF[:,:,2,iz-1] -= GradZ * dXdxI[3,3,2,:,:,iz-1]
    @views @. GradwF[:,:,1,iz] -= GradZ * dXdxI[3,3,1,:,:,iz]
  end
  @inbounds for iz = 1 : Nz
    @views @. GradZ = 1/2 * (cC[:,:,2,iz] - cC[:,:,1,iz])
    @views @. GraduF[:,:,2,iz] -= GradZ * dXdxI[3,1,2,:,:,iz]
    @views @. GraduF[:,:,1,iz] -= GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. GradvF[:,:,2,iz] -= GradZ * dXdxI[3,2,2,:,:,iz]
    @views @. GradvF[:,:,1,iz] -= GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. GradwF[:,:,2,iz] -= GradZ * dXdxI[3,3,2,:,:,iz]
    @views @. GradwF[:,:,1,iz] -= GradZ * dXdxI[3,3,1,:,:,iz]
    @views @. Gradu[:,:,iz] = GraduF[:,:,1,iz] + GraduF[:,:,2,iz]
    @views @. Gradv[:,:,iz] = GradvF[:,:,1,iz] + GradvF[:,:,2,iz]
  end  
  @inbounds for iz = 2 : Nz
    @views @. Gradw[:,:,iz] = GradwF[:,:,2,iz-1] + GradwF[:,:,1,iz]
  end  
end

function Gradient!(Gradu,Gradv,Gradw,cC,
  Fe,dXdxI,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheCol1, TCacheCol2, TCacheCol3, TCacheCol4 = ThreadCache
  Nz = size(cC,3)
  D = Fe.DS

  GraduF = TCacheCol1[Threads.threadid()]
  GradvF = TCacheCol2[Threads.threadid()]
  GradwF = TCacheCol3[Threads.threadid()]
  cF = TCacheCol4[Threads.threadid()]
  GradZ = TCacheC1[Threads.threadid()]
  DXcF = TCacheC1[Threads.threadid()]
  DYcF = TCacheC2[Threads.threadid()]
 
  @. GraduF = 0
  @. GradvF = 0
  @. GradwF = 0
  if Nz > 1 
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        JC = (J[i,j,1,1] + J[i,j,2,1])
        JCp1 = (J[i,j,1,2] + J[i,j,2,2])
        c = cC[i,j,1]
        cp1 = cC[i,j,2]
        c0 = ((3 * c - 2 * cp1) * JC + c * JCp1) / (JC + JCp1)
        cF[i,j,1,1],cF[i,j,2,1] = RecU3(c0,c,cp1,JC,JC,JCp1)
      end
    end
    @inbounds for iz = 2 : Nz - 1
      @inbounds for i = 1 : OrdPoly + 1
        @inbounds for j = 1 : OrdPoly + 1
          JCm1 = (J[i,j,1,iz-1] + J[i,j,2,iz-1])
          JC = (J[i,j,1,iz] + J[i,j,2,iz])
          JCp1 = (J[i,j,1,iz+1] + J[i,j,2,iz+1])
          cm1 = cC[i,j,iz-1]
          c = cC[i,j,iz]
          cp1 = cC[i,j,iz+1]
          cF[i,j,1,iz],cF[i,j,2,iz] = RecU3(cm1,c,cp1,JCm1,JC,JCp1)
        end
      end
    end
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        JCm1 = (J[i,j,1,Nz-1] + J[i,j,2,Nz-1])
        JC = (J[i,j,1,Nz] + J[i,j,2,Nz])
        cm1 = cC[i,j,Nz-1]
        c = cC[i,j,Nz]
        cp1 = ((3 * c - 2 * cm1) * JC + c * JCm1) / (JCm1 + JC)
        cF[i,j,1,Nz],cF[i,j,2,Nz] = RecU3(cm1,c,cp1,JCm1,JC,JC)
      end
    end
  else
    @views @. cF[:,:,1,1] = cC[:,:,1]
    @views @. cF[:,:,2,1] = cC[:,:,1]
  end  

  @inbounds for iz = 1 : Nz
    @. DXcF = 0
    @views DerivativeX!(DXcF,cF[:,:,1,iz],D)
    @. DYcF = 0
    @views DerivativeY!(DYcF,cF[:,:,1,iz],D)
    @views @. GraduF[:,:,1,iz] -=
      dXdxI[1,1,1,:,:,iz]  * DXcF + dXdxI[2,1,1,:,:,iz]  * DYcF
    @views @. GradvF[:,:,1,iz] -=
      dXdxI[1,2,1,:,:,iz]  * DXcF + dXdxI[2,2,1,:,:,iz]  * DYcF
    @views @. GradwF[:,:,1,iz] -=
      dXdxI[1,3,1,:,:,iz]  * DXcF + dXdxI[2,3,1,:,:,iz]  * DYcF
    @. DXcF = 0
    @views DerivativeX!(DXcF,cF[:,:,2,iz],D)
    @. DYcF = 0
    @views DerivativeY!(DYcF,cF[:,:,2,iz],D)
    @views @. GraduF[:,:,2,iz] -=
      dXdxI[1,1,2,:,:,iz]  * DXcF + dXdxI[2,1,2,:,:,iz]  * DYcF
    @views @. GradvF[:,:,2,iz] -=
      dXdxI[1,2,2,:,:,iz]  * DXcF + dXdxI[2,2,2,:,:,iz]  * DYcF
    @views @. GradwF[:,:,2,iz] -=
      dXdxI[1,3,2,:,:,iz]  * DXcF + dXdxI[2,3,2,:,:,iz]  * DYcF
  end
  @inbounds for iz = 2 : Nz
    @views @. GradZ = 1/2 * (cF[:,:,1,iz] - cF[:,:,2,iz-1])
    @views @. GraduF[:,:,2,iz-1] -= GradZ * dXdxI[3,1,2,:,:,iz-1]
    @views @. GraduF[:,:,1,iz] -= GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. GradvF[:,:,2,iz-1] -= GradZ * dXdxI[3,2,2,:,:,iz-1]
    @views @. GradvF[:,:,1,iz] -= GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. GradwF[:,:,2,iz-1] -= GradZ * dXdxI[3,3,2,:,:,iz-1]
    @views @. GradwF[:,:,1,iz] -= GradZ * dXdxI[3,3,1,:,:,iz]
  end
  @inbounds for iz = 1 : Nz
    @views @. GradZ = 1/2 * (cF[:,:,2,iz] - cF[:,:,1,iz])
    @views @. GraduF[:,:,2,iz] -= GradZ * dXdxI[3,1,2,:,:,iz]
    @views @. GraduF[:,:,1,iz] -= GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. GradvF[:,:,2,iz] -= GradZ * dXdxI[3,2,2,:,:,iz]
    @views @. GradvF[:,:,1,iz] -= GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. GradwF[:,:,2,iz] -= GradZ * dXdxI[3,3,2,:,:,iz]
    @views @. GradwF[:,:,1,iz] -= GradZ * dXdxI[3,3,1,:,:,iz]
    @views @. Gradu[:,:,iz] = GraduF[:,:,1,iz] + GraduF[:,:,2,iz]
    @views @. Gradv[:,:,iz] = GradvF[:,:,1,iz] + GradvF[:,:,2,iz]
  end  
  @inbounds for iz = 2 : Nz
    @views @. Gradw[:,:,iz] = GradwF[:,:,2,iz-1] + GradwF[:,:,1,iz]
  end  
end

function GradColumn!(Gradu,Gradv,Gradw,cC,RhoC,Fe,dXdxI,J,ThreadCache,Phys)

  @unpack TCacheC1, TCacheC2, TCacheCol1, TCacheCol2, TCacheCol3, TCacheCol4 = ThreadCache
  Nz = size(cC,3)
  OrdPoly = Fe.OrdPoly
  D = Fe.DS

  GraduF = TCacheCol1[Threads.threadid()]
  GradvF = TCacheCol2[Threads.threadid()]
  GradwF = TCacheCol3[Threads.threadid()]
  cF = TCacheCol4[Threads.threadid()]
  GradZ = TCacheC1[Threads.threadid()]
  DXcF = TCacheC1[Threads.threadid()]
  DYcF = TCacheC2[Threads.threadid()]
 
  @. GraduF = 0
  @. GradvF = 0
  @. GradwF = 0
  if Nz > 1 
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        JC = (J[i,j,1,1] + J[i,j,2,1])
        JCp1 = (J[i,j,1,2] + J[i,j,2,2])
        c = cC[i,j,1]
        cp1 = cC[i,j,2]
        c0 = ((3 * c - 2 * cp1) * JC + c * JCp1) / (JC + JCp1)
        cF[i,j,1,1],cF[i,j,2,1] = RecU3(c0,c,cp1,JC,JC,JCp1)
      end
    end
    @inbounds for iz = 2 : Nz - 1
      @inbounds for i = 1 : OrdPoly + 1
        @inbounds for j = 1 : OrdPoly + 1
          JCm1 = (J[i,j,1,iz-1] + J[i,j,2,iz-1])
          JC = (J[i,j,1,iz] + J[i,j,2,iz])
          JCp1 = (J[i,j,1,iz+1] + J[i,j,2,iz+1])
          cm1 = cC[i,j,iz-1]
          c = cC[i,j,iz]
          cp1 = cC[i,j,iz+1]
          cF[i,j,1,iz],cF[i,j,2,iz] = RecU3(cm1,c,cp1,JCm1,JC,JCp1)
        end
      end
    end
    @inbounds for i = 1 : OrdPoly + 1
      @inbounds for j = 1 : OrdPoly + 1
        JCm1 = (J[i,j,1,Nz-1] + J[i,j,2,Nz-1])
        JC = (J[i,j,1,Nz] + J[i,j,2,Nz])
        cm1 = cC[i,j,Nz-1]
        c = cC[i,j,Nz]
        cp1 = ((3 * c - 2 * cm1) * JC + c * JCm1) / (JCm1 + JC)
        cF[i,j,1,Nz],cF[i,j,2,Nz] = RecU3(cm1,c,cp1,JCm1,JC,JC)
      end
    end
  else
    @views @. cF[:,:,1,1] = cC[:,:,1]
    @views @. cF[:,:,2,1] = cC[:,:,1]
  end  

  @inbounds for iz = 1 : Nz
    @. DXcF = 0
    @views DerivativeX!(DXcF,cF[:,:,1,iz],D)
    @. DYcF = 0
    @views DerivativeY!(DYcF,cF[:,:,1,iz],D)
    @views @. GraduF[:,:,1,iz] -=
      dXdxI[1,1,1,:,:,iz]  * DXcF + dXdxI[2,1,1,:,:,iz]  * DYcF
    @views @. GradvF[:,:,1,iz] -=
      dXdxI[1,2,1,:,:,iz]  * DXcF + dXdxI[2,2,1,:,:,iz]  * DYcF
    @views @. GradwF[:,:,1,iz] -=
      dXdxI[1,3,1,:,:,iz]  * DXcF + dXdxI[2,3,1,:,:,iz]  * DYcF
    @. DXcF = 0
    @views DerivativeX!(DXcF,cF[:,:,2,iz],D)
    @. DYcF = 0
    @views DerivativeY!(DYcF,cF[:,:,2,iz],D)
    @views @. GraduF[:,:,2,iz] -=
      dXdxI[1,1,2,:,:,iz]  * DXcF + dXdxI[2,1,2,:,:,iz]  * DYcF
    @views @. GradvF[:,:,2,iz] -=
      dXdxI[1,2,2,:,:,iz]  * DXcF + dXdxI[2,2,2,:,:,iz]  * DYcF
    @views @. GradwF[:,:,2,iz] -=
      dXdxI[1,3,2,:,:,iz]  * DXcF + dXdxI[2,3,2,:,:,iz]  * DYcF
  end
  @inbounds for iz = 2 : Nz
    @views @. GradZ = 1/2 * (cF[:,:,1,iz] - cF[:,:,2,iz-1])
    @views @. GradwF[:,:,2,iz-1] -= GradZ * dXdxI[3,3,2,:,:,iz-1]
    @views @. GradwF[:,:,1,iz] -= GradZ * dXdxI[3,3,1,:,:,iz]
  end
  @inbounds for iz = 1 : Nz
    @views @. GradZ = -Phys.Grav * RhoC[:,:,iz] * 
      J[:,:,1,iz] / dXdxI[3,3,1,:,:,iz]  
    @views @. GraduF[:,:,1,iz] -= GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. GradvF[:,:,1,iz] -= GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. GradZ = -Phys.Grav * RhoC[:,:,iz] * 
      J[:,:,2,iz] / dXdxI[3,3,2,:,:,iz]  
    @views @. GraduF[:,:,2,iz] -= GradZ * dXdxI[3,1,2,:,:,iz]
    @views @. GradvF[:,:,2,iz] -= GradZ * dXdxI[3,2,2,:,:,iz]
    @views @. GradZ = 1/2 * (cF[:,:,2,iz] - cF[:,:,1,iz])
    @views @. GradwF[:,:,2,iz] -= GradZ * dXdxI[3,3,2,:,:,iz]
    @views @. GradwF[:,:,1,iz] -= GradZ * dXdxI[3,3,1,:,:,iz]
    @views @. Gradu[:,:,iz] += GraduF[:,:,1,iz] + GraduF[:,:,2,iz]
    @views @. Gradv[:,:,iz] += GradvF[:,:,1,iz] + GradvF[:,:,2,iz]
  end  
  @inbounds for iz = 2 : Nz
    @views @. Gradw[:,:,iz] += GradwF[:,:,2,iz-1] + GradwF[:,:,1,iz]
  end  
end

function FunCGradient!(Gradu,Gradv,Gradw,cC,fC,
  Fe,dXdxI,ThreadCache)
  @unpack TCacheC1, TCacheC2, TCacheCol1, TCacheCol2, TCacheCol3, TCacheCol4 = ThreadCache
  Nz = size(cC,3)
  D = Fe.DS

  GraduF = TCacheCol1[Threads.threadid()]
  GradvF = TCacheCol2[Threads.threadid()]
  GradwF = TCacheCol3[Threads.threadid()]
  cF = TCacheCol4[Threads.threadid()]
  GradZ = TCacheC1[Threads.threadid()]
  DXcF = TCacheC1[Threads.threadid()]
  DYcF = TCacheC2[Threads.threadid()]
 
  @. GraduF = 0
  @. GradvF = 0
  @. GradwF = 0
  @inbounds for iz = 1 : Nz
    @views @. cF[:,:,1,iz] = cC[:,:,iz]
    @views @. cF[:,:,2,iz] = cC[:,:,iz]
    @. DXcF = 0
    @views DerivativeX!(DXcF,cF[:,:,1,iz],D)
    @. DYcF = 0
    @views DerivativeY!(DYcF,cF[:,:,1,iz],D)
    @views @. GraduF[:,:,1,iz] -=
      fC[:,:,iz] * (dXdxI[1,1,1,:,:,iz]  * DXcF + dXdxI[2,1,1,:,:,iz]  * DYcF)
    @views @. GradvF[:,:,1,iz] -=
      fC[:,:,iz] * (dXdxI[1,2,1,:,:,iz]  * DXcF + dXdxI[2,2,1,:,:,iz]  * DYcF)
    @views @. GradwF[:,:,1,iz] -=
      fC[:,:,iz] * (dXdxI[1,3,1,:,:,iz]  * DXcF + dXdxI[2,3,1,:,:,iz]  * DYcF)
    @. DXcF = 0
    @views DerivativeX!(DXcF,cF[:,:,2,iz],D)
    @. DYcF = 0
    @views DerivativeY!(DYcF,cF[:,:,2,iz],D)
    @views @. GraduF[:,:,2,iz] -=
      fC[:,:,iz] * (dXdxI[1,1,2,:,:,iz]  * DXcF + dXdxI[2,1,2,:,:,iz]  * DYcF)
    @views @. GradvF[:,:,2,iz] -=
      fC[:,:,iz] * (dXdxI[1,2,2,:,:,iz]  * DXcF + dXdxI[2,2,2,:,:,iz]  * DYcF)
    @views @. GradwF[:,:,2,iz] -=
      fC[:,:,iz] * (dXdxI[1,3,2,:,:,iz]  * DXcF + dXdxI[2,3,2,:,:,iz]  * DYcF)
  end
  @inbounds for iz = 2 : Nz
    @views @. GradZ = 1/2 * (cF[:,:,1,iz] - cF[:,:,2,iz-1] )
    @views @. GraduF[:,:,2,iz-1] -= fC[:,:,iz-1] * GradZ * dXdxI[3,1,2,:,:,iz-1]
    @views @. GraduF[:,:,1,iz] -= fC[:,:,iz] * GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. GradvF[:,:,2,iz-1] -= fC[:,:,iz-1] * GradZ * dXdxI[3,2,2,:,:,iz-1]
    @views @. GradvF[:,:,1,iz] -= fC[:,:,iz] * GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. GradwF[:,:,2,iz-1] -= fC[:,:,iz-1] * GradZ * dXdxI[3,3,2,:,:,iz-1]
    @views @. GradwF[:,:,1,iz] -= fC[:,:,iz] * GradZ * dXdxI[3,3,1,:,:,iz]
  end
  @inbounds for iz = 1 : Nz
    @views @. GradZ = 1/2 * fC[:,:,iz] * (cF[:,:,2,iz] - cF[:,:,1,iz])
    @views @. GraduF[:,:,2,iz] -= GradZ * dXdxI[3,1,2,:,:,iz]
    @views @. GraduF[:,:,1,iz] -= GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. GradvF[:,:,2,iz] -= GradZ * dXdxI[3,2,2,:,:,iz]
    @views @. GradvF[:,:,1,iz] -= GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. GradwF[:,:,2,iz] -= GradZ * dXdxI[3,3,2,:,:,iz]
    @views @. GradwF[:,:,1,iz] -= GradZ * dXdxI[3,3,1,:,:,iz]
    @views @. Gradu[:,:,iz] = GraduF[:,:,1,iz] + GraduF[:,:,2,iz]
    @views @. Gradv[:,:,iz] = GradvF[:,:,1,iz] + GradvF[:,:,2,iz]
  end  
  @inbounds for iz = 2 : Nz
    @views @. Gradw[:,:,iz] = GradwF[:,:,2,iz-1] + GradwF[:,:,1,iz]
  end  
end
function RhoGradKinColumn!(FuC,FvC,Fw,uC,vC,w,RhoC,Fe,dXdxI,ThreadCache,::Val{:VectorInvariant})
  @unpack TCacheC1, TCacheC2, TCacheCol1, TCacheCol2, TCacheCol3, TCacheCol4 = ThreadCache
  Nz = size(uC,3)
  D = Fe.DS

  GraduF = TCacheCol1[Threads.threadid()]
  GradvF = TCacheCol2[Threads.threadid()]
  GradwF = TCacheCol3[Threads.threadid()]
  KinF = TCacheCol4[Threads.threadid()]
  GradZ = TCacheC1[Threads.threadid()]
  DXKinF = TCacheC1[Threads.threadid()]
  DYKinF = TCacheC2[Threads.threadid()]
 
  @. GraduF = 0
  @. GradvF = 0
  @. GradwF = 0
  @inbounds for iz = 1 : Nz
    @views @. KinF[:,:,1,iz] = 1/2 * (uC[:,:,iz] * uC[:,:,iz] + vC[:,:,iz] * vC[:,:,iz])
    @views @. KinF[:,:,2,iz] = KinF[:,:,1,iz]
    @views @. KinF[:,:,1,iz] += 1/2 * w[:,:,iz] * w[:,:,iz]
    @views @. KinF[:,:,2,iz] += 1/2 * w[:,:,iz+1] * w[:,:,iz+1]
  end  
  @inbounds for iz = 1 : Nz
    @. DXKinF = 0
    @views DerivativeX!(DXKinF,KinF[:,:,1,iz],D)
    @. DYKinF = 0
    @views DerivativeY!(DYKinF,KinF[:,:,1,iz],D)
    @views @. GraduF[:,:,1,iz] -=
      RhoC[:,:,iz] * (dXdxI[1,1,1,:,:,iz]  * DXKinF + dXdxI[2,1,1,:,:,iz]  * DYKinF)
    @views @. GradvF[:,:,1,iz] -=
      RhoC[:,:,iz] * (dXdxI[1,2,1,:,:,iz]  * DXKinF + dXdxI[2,2,1,:,:,iz]  * DYKinF)
    @views @. GradwF[:,:,1,iz] -=
      RhoC[:,:,iz] * (dXdxI[1,3,1,:,:,iz]  * DXKinF + dXdxI[2,3,1,:,:,iz]  * DYKinF)
    @. DXKinF = 0
    @views DerivativeX!(DXKinF,KinF[:,:,2,iz],D)
    @. DYKinF = 0
    @views DerivativeY!(DYKinF,KinF[:,:,2,iz],D)
    @views @. GraduF[:,:,2,iz] -=
      RhoC[:,:,iz] * (dXdxI[1,1,2,:,:,iz]  * DXKinF + dXdxI[2,1,2,:,:,iz]  * DYKinF)
    @views @. GradvF[:,:,2,iz] -=
      RhoC[:,:,iz] * (dXdxI[1,2,2,:,:,iz]  * DXKinF + dXdxI[2,2,2,:,:,iz]  * DYKinF)
    @views @. GradwF[:,:,2,iz] -=
      RhoC[:,:,iz] * (dXdxI[1,3,2,:,:,iz]  * DXKinF + dXdxI[2,3,2,:,:,iz]  * DYKinF)
  end
  @inbounds for iz = 2 : Nz
    @views @. GradZ = 1/2 * (KinF[:,:,1,iz] - KinF[:,:,2,iz-1] )
    @views @. GraduF[:,:,2,iz-1] -= RhoC[:,:,iz-1] * GradZ * dXdxI[3,1,2,:,:,iz-1]
    @views @. GraduF[:,:,1,iz] -= RhoC[:,:,iz] * GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. GradvF[:,:,2,iz-1] -= RhoC[:,:,iz-1] * GradZ * dXdxI[3,2,2,:,:,iz-1]
    @views @. GradvF[:,:,1,iz] -= RhoC[:,:,iz] * GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. GradwF[:,:,2,iz-1] -= RhoC[:,:,iz-1] * GradZ * dXdxI[3,3,2,:,:,iz-1]
    @views @. GradwF[:,:,1,iz] -= RhoC[:,:,iz] * GradZ * dXdxI[3,3,1,:,:,iz]
  end
  @inbounds for iz = 1 : Nz
    @views @. GradZ = 1/2 * RhoC[:,:,iz] * (KinF[:,:,2,iz] - KinF[:,:,1,iz])
    @views @. GraduF[:,:,2,iz] -= GradZ * dXdxI[3,1,2,:,:,iz]
    @views @. GraduF[:,:,1,iz] -= GradZ * dXdxI[3,1,1,:,:,iz]
    @views @. GradvF[:,:,2,iz] -= GradZ * dXdxI[3,2,2,:,:,iz]
    @views @. GradvF[:,:,1,iz] -= GradZ * dXdxI[3,2,1,:,:,iz]
    @views @. GradwF[:,:,2,iz] -= GradZ * dXdxI[3,3,2,:,:,iz]
    @views @. GradwF[:,:,1,iz] -= GradZ * dXdxI[3,3,1,:,:,iz]
    @views @. FuC[:,:,iz] += GraduF[:,:,1,iz] + GraduF[:,:,2,iz]
    @views @. FvC[:,:,iz] += GradvF[:,:,1,iz] + GradvF[:,:,2,iz]
  end  
  @inbounds for iz = 2 : Nz
    @views @. Fw[:,:,iz] += GradwF[:,:,2,iz-1] + GradwF[:,:,1,iz]
  end  
end

function KineticEnergy!(KE,uC,vC,wF,J)
  Nz = size(uC,3)
  
  @views @.  KE[:,:,1] = wF[:,:,1] * wF[:,:,1] *  J[:,:,1,1] 
  @inbounds for iz = 2 : Nz 
    @views @. KE[:,:,iz] = 1/2 * wF[:,:,iz] * wF[:,:,iz] *  (J[:,:,2,iz-1] + J[:,:,1,iz])
    @views @. KE[:,:,iz-1] += KE[:,:,iz]
  end  
  @views KE[:,:,Nz] += wF[:,:,Nz+1] * wF[:,:,Nz+1] *  J[:,:,2,Nz] 
  @views @. KE = 1/2 * (KE / (J[:,:,1,:] + J[:,:,2,:]) + uC * uC + vC * vC)

# @views @. KE = 1/2 (uC * uC + vC * vC + 1/2 * (wF[:,:,1:Nz] * wF[:,:,1:Nz] + wF[:,:,2:Nz+1] * wF[:,:,2:Nz+1]))
       
end

function wContraFace!(wConF,uC,vC,wC,RhoC,dXdxI,J)
  Nz = size(uC,3)
  for iz = 1 : Nz - 1
    @views @. wConF[:,:,iz] = 
      (uC[:,:,iz] * dXdxI[1,2,:,:,iz] + uC[:,:,iz+1] * dXdxI[1,1,:,:,iz+1] + 
      vC[:,:,iz] * dXdxI[2,2,:,:,iz] + vC[:,:,iz+1] * dXdxI[2,1,:,:,iz+1] + 
      wC[:,:,iz+1] * (dXdxI[3,2,:,:,iz] + dXdxI[3,1,:,:,iz+1])) / 
      sqrt((dXdxI[1,2,:,:,iz] + dXdxI[1,1,:,:,iz+1]) * (dXdxI[1,2,:,:,iz] + dXdxI[1,1,:,:,iz+1]) +
      (dXdxI[2,2,:,:,iz] + dXdxI[2,1,:,:,iz+1]) * (dXdxI[2,2,:,:,iz] + dXdxI[2,1,:,:,iz+1]) +
      (dXdxI[3,2,:,:,iz] + dXdxI[3,1,:,:,iz+1]) * (dXdxI[3,2,:,:,iz] + dXdxI[3,1,:,:,iz+1])) *
      ((RhoC[:,:,iz] * J[:,:,2,iz] + RhoC[:,:,iz+1] * J[:,:,1,iz+1]) /
      (J[:,:,2,iz] + J[:,:,1,iz+1]))
  end     
end

function wContraCell!(wConC,uC,vC,wC,RhoC,dXdxI,J)
  Nz = size(uC,3)
  @views @. wConC[:,:,1] =
    (uC[:,:,1] * dXdxI[1,2,:,:,1] + vC[:,:,1] * dXdxI[2,2,:,:,1] + wC[:,:,2] * dXdxI[3,2,:,:,1]) /
    sqrt((dXdxI[1,1,:,:,1] + dXdxI[1,2,:,:,1]) * (dXdxI[1,1,:,:,1] + dXdxI[1,2,:,:,1]) +
    (dXdxI[2,1,:,:,1] + dXdxI[2,2,:,:,1]) * (dXdxI[2,1,:,:,1] + dXdxI[2,2,:,:,1]) +
    (dXdxI[3,1,:,:,1] + dXdxI[3,2,:,:,1]) * (dXdxI[3,1,:,:,1] + dXdxI[3,2,:,:,1]))
  for iz = 2 : Nz - 1
    @views @. wConC[:,:,iz] =
      (uC[:,:,iz] * (dXdxI[1,1,:,:,iz] + dXdxI[1,2,:,:,iz]) +
      vC[:,:,iz] * (dXdxI[2,1,:,:,iz] + dXdxI[2,2,:,:,iz]) +
      wC[:,:,iz] * dXdxI[3,1,:,:,iz] + wC[:,:,iz+1] * dXdxI[3,2,:,:,iz]) /
      sqrt((dXdxI[1,1,:,:,iz] + dXdxI[1,2,:,:,iz]) * (dXdxI[1,1,:,:,iz] + dXdxI[1,2,:,:,iz]) +
      (dXdxI[2,1,:,:,iz] + dXdxI[2,2,:,:,iz]) * (dXdxI[2,1,:,:,iz] + dXdxI[2,2,:,:,iz]) +
      (dXdxI[3,1,:,:,iz] + dXdxI[3,2,:,:,iz]) * (dXdxI[3,1,:,:,iz] + dXdxI[3,2,:,:,iz]))
  end
  @views @. wConC[:,:,Nz] =
    (uC[:,:,Nz] * dXdxI[1,1,:,:,Nz] + vC[:,:,Nz] * dXdxI[2,1,:,:,Nz] + wC[:,:,Nz] * dXdxI[3,1,:,:,Nz] ) /
    sqrt((dXdxI[1,1,:,:,Nz] + dXdxI[1,2,:,:,Nz]) * (dXdxI[1,1,:,:,Nz] + dXdxI[1,2,:,:,Nz]) +
    (dXdxI[2,1,:,:,Nz] + dXdxI[2,2,:,:,Nz]) * (dXdxI[2,1,:,:,Nz] + dXdxI[2,2,:,:,Nz]) +
    (dXdxI[3,1,:,:,Nz] + dXdxI[3,2,:,:,Nz]) * (dXdxI[3,1,:,:,Nz] + dXdxI[3,2,:,:,Nz]))
end

function BoundaryW!(wCG,uC,vC,Fe,J,dXdxI)
  OrdPoly = Fe.OrdPoly
  @inbounds for i = 1 : OrdPoly +1
    @inbounds for j = 1 : OrdPoly +1
      v1 = uC[i,j,1] 
      v2 = vC[i,j,1] 
      wCG[i,j,1] = -(dXdxI[3,1,1,i,j]* v1 +
        dXdxI[3,2,1,i,j] * v2) / 
        dXdxI[3,3,1,i,j]
    end
  end
end

@inline function BoundaryDP(p1,p2,p3,J1,J2,J3)

  h1 = 1/2 * (J1[1] + J1[2]);
  h2 = 1/2 * (J2[1] + J2[2]);
  h3 = 1/2 * (J3[1] + J3[2]);
  f1 = -h1 * (3*h1 + 4*h2 + 2*h3)/((h1 + h2)*(h1 + h2 + h3)) ;
  f2 = h1 * (h1^2 + 6*h1*h2 + 3*h1*h3 + 6*h2^2 + 6*h2*h3 + 2*h3^2)/ 
   ((h1 + h2)*(h2 + h3)*(h1 + h2 + h3)) 
  f3 = -h1 * (h1 + 2*h2)/((h2 + h3)*(h1 + h2 + h3)) 
  DpB = (f1 * p1 + f2 * p2 + f3 * p3);

end  


@inline function BoundaryP(p1,p2,p3,J1,J2,J3)

  h1 = 1/2 * (J1[1] + J1[2])
  h2 = 1/2 * (J2[1] + J2[2])
  h3 = 1/2 * (J3[1] + J3[2])
  f1 = (27*h1^2 + 24*h1*h2 + 12*h3*h1 + 4*h2^2 + 4*h3*h2)/(4*(h1 + h2)*(h1 + h2 + h3))
  f2 = -(h1*(15*h1^2 + 46*h1*h2 + 23*h1*h3 + 24*h2^2 + 24*h2*h3 + 8*h3^2))/(4*(h1 + h2)*(h2 + h3)*(h1 + h2 + h3))
  f3 = (h1*(15*h1 + 8*h2))/(4*(h2 + h3)*(h1 + h2 + h3))
  p0 = f1 * p1 + f2 * p2 + f3 * p3
end  

@inline function RecU3(cL,cC,cR,JL,JC,JR)
  kL = (JC / (JC + JL)) * ((JR + JC)/(JL + JC + JR))
  kR = -(JC /(JR + JC)) *(JL /(JL + JC + JR))
  cCL = kL * cL + (1 - kL - kR) * cC + kR * cR
  kR = (JC / (JC + JR)) * ((JL + JC) / (JL + JC + JR))
  kL = -(JC / (JL + JC)) * (JR / (JL + JC + JR))
  cCR = kL * cL + (1 - kL - kR)*cC + kR * cR
  return (cCL,cCR)
end

@inline function FluxX!(fc,c,S)
  n = size(c,1)
  @inbounds for i = 1 : n -1
    @views @. fc[i,:] = 0
    @inbounds for l = 1 : i
      @inbounds for k = 1 : n
        @views @. fc[i,:] = fc[i,:] - 1/2 * S[l,k] * (c[l,:] + c[k,:])
      end
    end
  end
end

@inline function FluxY!(fc,c,S)
  n = size(c,1)
  @inbounds for i = 1 : n -1
    @views @. fc[:,i] = 0
    @inbounds for l = 1 : i
      @inbounds for k = 1 : n
        @views @. fc[:,i] = fc[:,i] - 1/2 * S[l,k] * (c[:,l] + c[:,k])
      end
    end
  end
end

function Error!(e,c,dx)
#  c_0     c_1     c_2      c_n
#      dx_1    dx_2     dx_n

n = size(c,1)
@inbounds for i = 2 : n - 1
  e[i-1] = ErrorLoc(c[i-1],c[i],c[i+1],dx[i-1],dx[i],.2)
end
end

@inline function ErrorLoc(cm,c,cp,dxm,dxp,d)
  eLoc = abs(dxm*cp-(dxm+dxp)*c+dxp*cm) /
    (dxm*abs(cp-cm) + dxp*abs(c-cm) +
    d*(dxm*abs(cp)+(dxm+dxp)*abs(c)+dxp*abs(cm))+1.e-14);
end

function axpy!(a::T, x::AbstractArray{T,1}, y::AbstractArray{T,1}) where {T<:Number}
  @simd for i in eachindex(x, y)
    @inbounds y[i] = muladd(a, x[i], y[i])
  end
  return y
end

function axpy!(a::T, x::AbstractArray{T,3}, y::AbstractArray{T,3}) where {T<:Number}
  @simd for i in eachindex(x, y)
    @inbounds y[i] = muladd(a, x[i], y[i])
  end
  return y
end

function axpy!(a::AbstractArray{T,3}, x::AbstractArray{T,3}, y::AbstractArray{T,3}) where {T<:Number}
  @simd for i in eachindex(x, y)
    @inbounds y[i] = muladd(a[i], x[i], y[i])
  end
  return y
end

function ax!(a::AbstractArray{T,3}, x::AbstractArray{T,3}, y::AbstractArray{T,3}) where {T<:Number}
  @simd for i in eachindex(a, x, y)
    @inbounds y[i] = a[i] * x[i]
  end
  return y
end

