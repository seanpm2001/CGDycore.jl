using NLsolve
function Source!(F,U,CG,Global,iG)
  Model = Global.Model
  Param = Global.Model.Param
  Phys = Global.Phys
  RhoPos = Model.RhoPos
  uPos = Model.uPos
  vPos = Model.vPos
  ThPos = Model.ThPos
  nz = Global.Grid.nz

  str = lowercase(Model.ProfRho)
  @views Rho = U[:,Model.RhoPos]
  @views Th = U[:,Model.ThPos]
  @views Tr = U[:,Model.NumV+1:end]
  @views Sigma = Global.Cache.Cache1[:,1]
  @views height_factor = Global.Cache.Cache2[:,1]
  @views ΔρT = Global.Cache.Cache3[:,1]
  if str == "heldsuarezsphere"
    Pressure!(Sigma,Th,Rho,Tr,Global)
    Sigma = Sigma / Phys.p0
    @. height_factor = max(0.0, (Sigma - Param.sigma_b) / (1.0 - Param.sigma_b))
    @. ΔρT =
      (Param.k_a + (Param.k_s - Param.k_a) * height_factor *
      cos(Global.latN[iG])^4) *
      Rho *
      (                  # ᶜT - ᶜT_equil
         Phys.p0 * Sigma / (Rho * Phys.Rd) - 
         max(Param.T_min,
         (Param.T_equator - Param.DeltaT_y * sin(Global.latN[iG])^2 - 
         Param.DeltaTh_z * log(Sigma) * cos(Global.latN[iG])^2) *
         Sigma^Phys.kappa)
      )
     @views @. F[:,uPos:vPos] -= (Param.k_f * height_factor) * U[:,uPos:vPos]
     @views @. F[:,ThPos]  -= ΔρT / Sigma^Phys.kappa
  end
end

function SourceMicroPhysicsv1(F,U,CG,Global,iG)
  (; Rd,
     Cpd,
     Rv,
     Cpv,
     Cpl,
     p0,
     L00,
     kappa) = Global.Phys
  ThPos=Global.Model.ThPos
  RhoPos=Global.Model.RhoPos
  RhoVPos=Global.Model.RhoVPos
  RhoCPos=Global.Model.RhoCPos
  RelCloud = Global.Model.RelCloud
  NumV=Global.Model.NumV
  @views  Rho = U[:,..,RhoPos]  
  @views  RhoV = U[:,..,RhoVPos+NumV]  
  @views  RhoC = U[:,..,RhoCPos+NumV]  
  @inbounds for i in eachindex(Rho)
    RhoD = Rho[i] - RhoV[i] - RhoC[i]
  end   
end   
function SourceMicroPhysics(F,U,CG,Global,iG)
  (; Rd,
     Cpd,
     Rv,
     Cpv,
     Cpl,
     p0,
     L00,
     kappa) = Global.Phys
   ThPos=Global.Model.ThPos
   RhoPos=Global.Model.RhoPos
   RhoVPos=Global.Model.RhoVPos
   RhoCPos=Global.Model.RhoCPos
   RelCloud = Global.Model.RelCloud
   NumV=Global.Model.NumV
   nz = Global.Grid.nz
   @inbounds for i = 1:nz
     Rho = U[i,RhoPos]  
     RhoTh = U[i,ThPos]  
     RhoV = U[i,NumV+RhoVPos]  
     RhoC = U[i,NumV+RhoCPos]  
     RhoD = Rho - RhoV - RhoC
     Cpml = Cpd * RhoD + Cpv * RhoV + Cpl * RhoC
     Rm = Rd * RhoD + Rv * RhoV
     kappaM = Rm / Cpml
     p = (Rd * RhoTh / p0^kappaM)^(1 / (1 - kappaM))
     T = p / Rm
     T_C = T - 273.15
     p_vs = 611.2 * exp(17.62 * T_C / (243.12 + T_C))
     a = p_vs / (Rv * T) - RhoV
     b = 0.0
     FRhoV = 0.5 * RelCloud * (a + b - sqrt(a * a + b * b))
     L = L00 - (Cpl - Cpv) * T
     FRhoTh = RhoTh*(-L/(Cpml*T) - log(p / p0) * (Rm / Cpml) *(Rv / Rm  - Cpv / Cpml) + Rv / Rm)*FRhoV
     FRho = FRhoV
     FRhoC = 0.0
     F[i,ThPos] += FRhoTh   
     F[i,RhoPos] += FRho
     F[i,RhoVPos+NumV] += FRhoV
     F[i,RhoCPos+NumV] += FRhoC
  end  
end

function Microphysics(RhoTh,Rho,RhoV,RhoC,Rd,
     Cpd,Rv,Cpv,Cpl,L00,p0,RelCloud)
  RhoD = Rho - RhoV - RhoC
  Cpml = Cpd * RhoD + Cpv * RhoV + Cpl * RhoC
  Rm = Rd * RhoD + Rv * RhoV
  kappaM = Rm / Cpml
  p = (Rd * RhoTh / p0^kappaM)^(1 / (1 - kappaM))
  T = p / Rm
  T_C = T - 273.15
  p_vs = 611.2 * exp(17.62 * T_C / (243.12 + T_C))
  a = p_vs / (Rv * T) - RhoV
  b = 0.0
  FRhoV = 0.5 * RelCloud * (a + b - sqrt(a * a + b * b))
  L = L00 - (Cpl - Cpv) * T
  #FRhoTh = RhoTh*(Rv/Rm-log(p/p0)*(Rv/Rm+(Cpl-Cpv)/Cpml)-L/(Cpml*T))*FRhoV
  FRhoTh = RhoTh*(-L/(Cpml*T) - log(p / p0) * (Rm / Cpml) *(Rv / Rm  - Cpv / Cpml) + Rv / Rm)*FRhoV
  #FRhoTh = RhoTh*(-L/(Cpml*T) )*FRhoV
  FRho = FRhoV
  FRhoC = 0.0
  return (FRhoTh,FRho,FRhoV,FRhoC)
end  


function MicrophysicsDCMIP(RhoTh,Rho,RhoV,RhoC,Rd,
     Cpd,Rv,Cpv,Cpl,L00,p0,RelCloud)
  RhoD = Rho - RhoV - RhoC
  Cpml = Cpd * RhoD + Cpv * RhoV + Cpl * RhoC
  Rm = Rd * RhoD + Rv * RhoV
  kappaM = Rm / Cpml
  p = (Rd * RhoTh / p0^kappaM)^(1 / (1 - kappaM))
  T = p / Rm
  T_C = T - 273.15
  p_vs = 611.2 * exp(17.62 * T_C / (243.12 + T_C))
  RhoVS = p_vs / (Rv * T) 
  if RhoV > RhoVS
    L = L00 - (Cpl - Cpv) * T
    Cond = (RhoV - RhoVS) / (1.0+(L/Cpd)*(L*(RhoVS/Rho)/(Rv*T^2)))
    FRhoV = -RelCloud * Cond
    FRhoTh = RhoTh*(-L/(Cpml*T) - log(p / p0) * (Rm / Cpml) *(Rv / Rm - Cpv / Cpml) + Rv / Rm)*FRhoV
    FRho = FRhoV
  else
    FRhoV = 0.0
    FRhoTh = 0.0
    FRho = 0.0
  end  
  FRhoC = 0.0
  return (FRhoTh,FRho,FRhoV,FRhoC)
end

function MicrophysicsSat(RhoTh,Rho,RhoV,RhoC,Rd,
     Cpd,Rv,Cpv,Cpl,L00,p0,RelCloud)
  RhoD = Rho - RhoV - RhoC
  Cpml = Cpd * RhoD + Cpv * RhoV + Cpl * RhoC
  Rm = Rd * RhoD + Rv * RhoV
  kappaM = Rm / Cpml
  p = (Rd * RhoTh / p0^kappaM)^(1 / (1 - kappaM))
  T = p / Rm
  T_C = T - 273.15
  p_vs = 611.2 * exp(17.62 * T_C / (243.12 + T_C))
  RhoVS = p_vs / (Rv * T) 
  if RhoV > RhoVS
    F=SetResT(T,Rho,RhoV,Rd,Cpd,Rv,Cpv,Cpl,L00,p0)
    res=nlsolve(F,[0.0,0.0])
    Cond = -res.zero[2]
    L = L00 - (Cpl - Cpv) * T
    FRhoV = -RelCloud * Cond
    FRhoTh = RhoTh*(-L/(Cpml*T) - log(p / p0) * (Rm / Cpml) *(Rv / Rm - Cpv / Cpml) + Rv / Rm)*FRhoV
    FRho = FRhoV
  else
    FRhoV = 0.0
    FRhoTh = 0.0
    FRho = 0.0
  end  
  FRhoC = 0.0
  return (FRhoTh,FRho,FRhoV,FRhoC)
end

function SetRes(RhoTh0, Rho0, RhoV0, Rd, Cpd, Rv, Cpv, Cpl, L00, p0) 
  function ResMoisture(y)
    dRhoTh = y[1]
    dRhoV = y[2]
    RhoTh = RhoTh0 + dRhoTh
    RhoV = RhoV0 + dRhoV
    Rho = Rho0 + dRhoV
    RhoC = -dRhoV
    RhoD = Rho - RhoV - RhoC
    Cpml = Cpd * RhoD + Cpv * RhoV + Cpl * RhoC
    Rm = Rd * RhoD + Rv * RhoV
    kappaM = Rm / Cpml
    p = (Rd * RhoTh / p0^kappaM)^(1 / (1 - kappaM))
    T = p / Rm
    T_C = T - 273.15
    p_vs = 611.2 * exp(17.62 * T_C / (243.12 + T_C))
    RhoVS = p_vs / (Rv * T)
    L = L00 - (Cpl - Cpv) * T
    @show T
    @show RhoVS
    @show RhoV
    @show dRhoTh 
    @show dRhoV
    @show RhoTh*(Rv/Rm-log(p/p0)*(Rv/Rm+(Cpl-Cpv)/Cpml)-L/(Cpml*T))*dRhoV
    FdRhoV = RhoVS - RhoV
    FdRhoTh = dRhoTh - RhoTh*(-L/(Cpml*T) - log(p / p0) * (Rm / Cpml) *(Rv / Rm - Cpv / Cpml) + Rv / Rm) * dRhoV
    return [FdRhoTh,FdRhoV]
  end
end

function SetResT(T0, Rho0, RhoV0, Rd, Cpd, Rv, Cpv, Cpl, L00, p0) 
  function ResMoisture(y)
    dT = y[1]
    dRhoV = y[2]
    T = T0 + dT
    RhoV = RhoV0 + dRhoV
    T_C = T - 273.15
    p_vs = 611.2 * exp(17.62 * T_C / (243.12 + T_C))
    RhoVS = p_vs / (Rv * T)
    L = L00 - (Cpl - Cpv) * T
    FdRhoV = RhoVS - RhoV
    FdT = dT + L/Cpd * dRhoV
    return [FdT,FdRhoV]
  end
end

