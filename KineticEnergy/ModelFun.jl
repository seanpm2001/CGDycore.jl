function fProjectC!(c,f,X,Fe,Phys,Param)
  OPx = size(c,1)
  OPz = size(c,2)
  z = 0.0
  for i = 1 : OPx
    for j = 1 :OPz
      @views z = sum(Fe.IntZF2C[j,:] .* X[i,:,2])
      c[i,j] = f(X[i,j,:],Phys,Param)
    end
  end
end

function fProjectF!(c,f,X,Phys,Param)
  OPx = size(c,1)
  OPz = size(c,2)
  z = 0.0
  for i = 1 : OPx
    for j = 1 :OPz
      c[i,j] = f(X[i,j,:],Phys,Param)
    end
  end
end

function fRho(x,Phys,Param)
  Example = Param.Example
  if Example == "WarmBubble2DXCart"
    Grav =Phys.Grav
    p0 = Phys.p0
    Rd = Phys.Rd
    kappa = Phys.kappa
    Th0 = Param.Th0
    DeltaTh = Param.DeltaTh
    xC0 = Param.xC0
    zC0 = Param.zC0
    rC0 = Param.rC0
    z = x[2]
    x = x[1]
    pLoc =p0*(1-Grav*z*kappa/(Rd*Th0))^(1/kappa)
    rr = sqrt((x-xC0)^2+(z-zC0)^2)
    ThLoc = Th0
    if rr <rC0
      ThLoc =ThLoc+DeltaTh*cos(0.5*pi*rr/rC0)^2
    end
    Rho = pLoc / ((pLoc / p0)^kappa * Rd * ThLoc)
  elseif Example == "HillAgnesiCart"  
    z = x[2]
    NBr = Param.NBr
    Grav = Phys.Grav
    p0 = Phys.p0
    Cpd = Phys.Cpd
    Rd = Phys.Rd
    kappa = Phys.kappa
    Th0 = Param.Th0
    S = NBr * NBr / Grav
    ThLoc = Th0 * exp(z * S)
    pLoc = p0 *(1.0 - Grav/(Cpd * Th0 * S) * (1.0 - exp(-S * z)))^(Cpd / Rd)
    Rho = pLoc / ((pLoc / p0).^kappa * Rd*ThLoc)
  end    
  return Rho
end

function fTheta(x,Phys,Param)
  Example = Param.Example
  if Example == "WarmBubble2DXCart"
    Grav =Phys.Grav
    p0 = Phys.p0
    Rd = Phys.Rd
    kappa = Phys.kappa
    Th0 = Param.Th0
    DeltaTh = Param.DeltaTh
    xC0 = Param.xC0
    zC0 = Param.zC0
    rC0 = Param.rC0
    z = x[2]
    x = x[1]
    pLoc =p0*(1-Grav*z*kappa/(Rd*Th0))^(1/kappa)
    rr = sqrt((x-xC0)^2+(z-zC0)^2)
    ThLoc = Th0
    if rr <rC0
      ThLoc =ThLoc+DeltaTh*cos(0.5*pi*rr/rC0)^2
    end
    Theta = ThLoc
  elseif Example == "HillAgnesiCart"  
    z = x[2]
    NBr = Param.NBr
    Grav = Phys.Grav
    p0 = Phys.p0
    Cpd = Phys.Cpd
    Rd = Phys.Rd
    kappa = Phys.kappa
    Th0 = Param.Th0
    S = NBr * NBr / Grav
    ThLoc = Th0 * exp(z * S)
    Theta = ThLoc
  end    
  return Theta
end

function fuVel(x,Phys,Param)
  Example = Param.Example
  if Example == "WarmBubble2DXCart"
    u = Param.uMax  
  elseif Example == "HillAgnesiCart"  
    u = Param.uMax  
  end
  return u
end

function fwVel(x,Phys,Param)
  Example = Param.Example
  if Example == "WarmBubble2DXCart"
    w = Param.wMax  
  elseif Example == "HillAgnesiCart"  
    w = Param.wMax  
  end
  return w
end


