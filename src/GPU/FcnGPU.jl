function FcnAdvectionGPU!(F,U,time,FE,Metric,Phys,Cache,Exchange,Global,Param,Profile)

  backend = get_backend(F)
  FT = eltype(F)
  dtau = Global.TimeStepper.dtauStage
  Glob = FE.Glob
  DS = FE.DS
  DW = FE.DW
  M = FE.M
  DoF = FE.DoF
  Stencil = FE.Stencil
  dXdxI = Metric.dXdxI
  X = Metric.X
  J = Metric.J
  JC = Metric.JC
  JCW = Metric.JCW
  N = FE.OrdPoly+1
  ww = FE.w
  Nz = size(F,1)
  NF = size(Glob,2)
  NDoF = size(Glob,1)
  KoeffDiv = Global.Model.HyperDDiv
  NumV  = Global.Model.NumV
  NumTr  = Global.Model.NumTr
  Temp1 = Cache.Temp1
  @views qMin = Cache.qMin[:,:,1:NumTr]
  @views qMax = Cache.qMax[:,:,1:NumTr]


# State vector
  @views Rho = U[:,:,1]
  @views u = U[:,:,2]
  @views v = U[:,:,3]
  @views w = U[:,:,4]
# Cache
  @views CacheF = Temp1[:,:,1:5]
  @views CacheTr = Temp1[:,:,1]
# Ranges
  NzG = min(div(1024,N*N),Nz)
  group = (N, N, NzG, 1)
  ndrange = (N, N, Nz, NF)
  groupC = (N* N, NzG, 1)
  ndrangeC = (N* N, Nz, NF)
  groupLim = (10, 1)
  ndrangeLim = (Nz, NF)
  NFG = min(div(512,Nz),NF)
  groupL = (Nz, NFG, 1)
  ndrangeL = (Nz, NF, NumTr)

  KLimitKernel! = LimitKernel!(backend, groupL)
  KuvwFunCKernel! = uvwFunCKernel!(backend, groupC)
  KDivRhoKernel! = DivRhoKernel!(backend, group)
  KHyperViscTracerKernel! = HyperViscTracerKernel!(backend, group)
  KHyperViscTracerKoeffKernel! = HyperViscTracerKoeffKernel!(backend, group)
  KDivRhoTrUpwind3Kernel! = DivRhoTrUpwind3Kernel!(backend, group)
  KDivRhoTrUpwind3LimKernel! = DivRhoTrUpwind3LimKernel!(backend, group)
  KDivRhoTrViscUpwind3LimKernel! = DivRhoTrViscUpwind3LimKernel!(backend, group)

  if Global.Model.HorLimit
    @views KLimitKernel!(DoF,qMin,qMax,U[:,:,NumV+1:NumV+NumTr],Rho,Glob,ndrange=ndrangeL)
      KernelAbstractions.synchronize(backend)
  end


# Velocity 
  KuvwFunCKernel!(Profile,u,v,w,time,Glob,X,Param,Phys,ndrange=ndrangeC)
  KernelAbstractions.synchronize(backend)

# Hyperviscosity Part 1
  KHyperViscTracerKernel!(CacheTr,U[:,:,1+NumV],Rho,DS,DW,dXdxI,J,M,Glob,ndrange=ndrange)
  KernelAbstractions.synchronize(backend)

# Data exchange  
  Parallels.ExchangeData3DSendGPU(CacheTr,Exchange)
  Parallels.ExchangeData3DRecvGPU!(CacheTr,Exchange)

  @. F = 0
# @views KHyperViscTracerKoeffKernel!(F[:,:,1+NumV],CacheTr,Rho,DS,DW,dXdxI,J,M,Glob,
#   KoeffDiv,ndrange=ndrange)
# KernelAbstractions.synchronize(backend)


  KDivRhoKernel!(F,U,DS,dXdxI,J,M,Glob,ndrange=ndrange)
  KernelAbstractions.synchronize(backend)  

  if Global.Model.HorLimit
    @views KDivRhoTrUpwind3LimKernel!(F[:,:,1+NumV],U[:,:,1+NumV],U,DS,
      dXdxI,J,M,Glob,dtau,ww,qMin[:,:,1],qMax[:,:,1],Stencil,ndrange=ndrange)
    KernelAbstractions.synchronize(backend)  
#   @views KDivRhoTrViscUpwind3LimKernel!(F[:,:,1+NumV],U[:,:,1+NumV],U,CacheTr,DS,DW,
#     dXdxI,J,M,Glob,KoeffDiv,dtau,ww,qMin[:,:,1],qMax[:,:,1],Stencil,ndrange=ndrange)
#   KernelAbstractions.synchronize(backend)  
  else
    @views KHyperViscTracerKoeffKernel!(F[:,:,1+NumV],CacheTr,Rho,DS,DW,dXdxI,J,M,Glob,
      KoeffDiv,ndrange=ndrange)
    KernelAbstractions.synchronize(backend)

    @views KDivRhoTrUpwind3Kernel!(F[:,:,1+NumV],U[:,:,1+NumV],U,DS,
      dXdxI,J,M,Glob,ndrange=ndrange)
    KernelAbstractions.synchronize(backend)  

    KDivRhoKernel!(F,U,DS,dXdxI,J,M,Glob,ndrange=ndrange)
    KernelAbstractions.synchronize(backend)  
  end

# Data exchange  
  Parallels.ExchangeData3DSendGPU(F[:,:,1+NumV],Exchange)
  Parallels.ExchangeData3DRecvGPU!(F[:,:,1+NumV],Exchange)

end

function FcnGPU!(F,U,FE,Metric,Phys,Cache,Exchange,Global,Param,DiscType)

  backend = get_backend(F)
  FT = eltype(F)
  @. F = 0
  Glob = FE.Glob
  DS = FE.DS
  DW = FE.DW
  M = FE.M
  dXdxI = Metric.dXdxI
  X = Metric.X
  J = Metric.J
  lat = Metric.lat  
  dz = Metric.dz  
  DoF = FE.DoF
  N = size(FE.DS,1)
  Nz = size(F,1)
  NDoF = size(F,2)
  NF = size(Glob,2)
  NumV  = Global.Model.NumV 
  NumTr  = Global.Model.NumTr 
  InteriorFaces = Global.Grid.InteriorFaces
  BoundaryFaces = Global.Grid.BoundaryFaces
  Koeff = Global.Model.HyperDDiv
  Temp1 = Cache.Temp1
  NumberThreadGPU = Global.ParallelCom.NumberThreadGPU
  Force = Global.Model.Force
  MicrophysicsSource = Global.Model.MicrophysicsSource

  KoeffCurl = Global.Model.HyperDCurl
  KoeffGrad = Global.Model.HyperDGrad
  KoeffDiv = Global.Model.HyperDDiv

# State vector
  @views Rho = U[:,:,1]
  @views u = U[:,:,2]
  @views v = U[:,:,3]
  @views w = U[:,:,4]
  @views RhoTr = U[:,:,5]
# Tendency
  @views FRho = F[:,:,1]
  @views FRhoTr = F[:,:,5]
# Cache
  @views CacheF = Temp1[:,:,1:6]
  @views CacheFF = Temp1[:,:,1:6+NumTr]
  @views p = Cache.AuxG[:,:,1]
  KV = Cache.KV
  TSurf = Cache.TSurf
  RhoVSurf = Cache.RhoVSurf
  uStar = Cache.uStar
  CT = Cache.CT
  CH = Cache.CH
# Ranges
  NzG = min(div(NumberThreadGPU,N*N),Nz)
  group = (N, N, NzG, 1)
  ndrange = (N, N, Nz, NF)
  ndrangeB = (N, N, Nz, length(BoundaryFaces))
  ndrangeI = (N, N, Nz, length(InteriorFaces))
  groupTr = group
  ndrangeTr = ndrange
  NDoFG = min(div(NumberThreadGPU,Nz),NDoF)
  groupG = (Nz, NDoFG)  
  ndrangeG = (Nz, NDoF)  

  KRhoGradKinKernel! = RhoGradKinKernel!(backend,group)
  KGradKernel! = GradKernel!(backend,group)
  KHyperViscKernel! = HyperViscKernel!(backend, group)
  KHyperViscKoeffKernel! = HyperViscKoeffKernel!(backend, group)
  KDivRhoThUpwind3Kernel! = DivRhoThUpwind3Kernel!(backend, group)
  KMomentumCoriolisKernel! = MomentumCoriolisKernel!(backend, group)
  KHyperViscTracerKernel! = HyperViscTracerKernel!(backend, groupTr)
  KHyperViscTracerKoeffKernel! = HyperViscTracerKoeffKernel!(backend, groupTr)
  KDivRhoTrUpwind3Kernel! = DivRhoTrUpwind3Kernel!(backend, groupTr)
  if Global.Model.SurfaceFlux
    NFG = min(div(NumberThreadGPU,N*N),NF)
    groupS = (N * N, NFG)
    KSurfaceFluxScalarsKernel = SurfaceFluxScalarsKernel(backend,groupS)  
  end  
  if Global.Model.VerticalDiffusion
    KVerticalDiffusionScalarKernel! = VerticalDiffusionScalarKernel!(backend,groupTr)  
  end  


####
# First phase  
####
  @. Temp1 = FT(0)
  @views MRho = CacheF[:,:,6]
  KHyperViscKernel!(CacheF,MRho,U,DS,DW,dXdxI,J,M,Glob,BoundaryFaces,ndrange=ndrangeB)
  for iT = 1 : NumTr
    @views CacheTr = Temp1[:,:,iT + 6]  
    KHyperViscTracerKernel!(CacheTr,U[:,:,iT+NumV],Rho,DS,DW,dXdxI,J,M,Glob,BoundaryFaces,ndrange=ndrangeB)
  end  
  Parallels.ExchangeData3DSendGPU(CacheFF,Exchange)


  KHyperViscKernel!(CacheF,MRho,U,DS,DW,dXdxI,J,M,Glob,InteriorFaces,ndrange=ndrangeI)
  KernelAbstractions.synchronize(backend)
  for iT = 1 : NumTr
    @views CacheTr = Temp1[:,:,iT + 6]  
    KHyperViscTracerKernel!(CacheTr,U[:,:,iT+NumV],Rho,DS,DW,dXdxI,J,M,Glob,InteriorFaces,ndrange=ndrangeI)
  end  

  Parallels.ExchangeData3DRecvGPU!(CacheFF,Exchange)
  KernelAbstractions.synchronize(backend)

####
# Second phase  
####

  @. F = 0
  KHyperViscKoeffKernel!(F,U,CacheF,DS,DW,dXdxI,J,M,Glob,BoundaryFaces,KoeffCurl,KoeffGrad,KoeffDiv,ndrange=ndrangeB)
  for iT = 1 : NumTr
    @views CacheTr = Temp1[:,:,iT + 6]  
    @views KHyperViscTracerKoeffKernel!(F[:,:,iT+NumV],CacheTr,Rho,DS,DW,dXdxI,J,M,Glob,BoundaryFaces,
      KoeffDiv,ndrange=ndrangeB)
  end  
  KGradKernel!(F,U,p,DS,dXdxI,J,M,MRho,Glob,BoundaryFaces,Phys,ndrange=ndrangeB)
  KMomentumCoriolisKernel!(F,U,DS,dXdxI,J,X,MRho,M,Glob,BoundaryFaces,Phys,ndrange=ndrangeB)
  KDivRhoThUpwind3Kernel!(F,U,DS,dXdxI,J,M,Glob,BoundaryFaces,ndrange=ndrangeB)
  for iT = 1 : NumTr
    @views KDivRhoTrUpwind3Kernel!(F[:,:,iT+NumV],U[:,:,iT+NumV],U,DS,
      dXdxI,J,M,Glob,BoundaryFaces,ndrange=ndrangeB)
  end  
  if Global.Model.VerticalDiffusion
    @views KVerticalDiffusionScalarKernel!(F[:,:,5],U[:,:,5],Rho,KV,
      dXdxI,J,M,Glob,BoundaryFaces,ndrange=ndrangeB)
    for iT = 1 : NumTr
      @views KVerticalDiffusionScalarKernel!(F[:,:,iT+NumV],U[:,:,iT+NumV],Rho,KV,
        dXdxI,J,M,Glob,BoundaryFaces,ndrange=ndrangeB)
    end  
  end    
  if Global.Model.SurfaceFlux
    ndrangeSB = (N * N,length(BoundaryFaces))  
    ndrangeSI = (N * N,length(InteriorFaces))  
    KSurfaceFluxScalarsKernel(F,U,p,TSurf,RhoVSurf,uStar,CT,CH,dXdxI,Glob,BoundaryFaces,M,Phys,ndrange=ndrangeSB)
  end  
  KernelAbstractions.synchronize(backend)

  Parallels.ExchangeData3DSendGPU(F,Exchange)


  KHyperViscKoeffKernel!(F,U,CacheF,DS,DW,dXdxI,J,M,Glob,InteriorFaces,KoeffCurl,KoeffGrad,KoeffDiv,ndrange=ndrangeI)
  for iT = 1 : NumTr
    @views CacheTr = Temp1[:,:,iT + 6]  
    @views KHyperViscTracerKoeffKernel!(F[:,:,iT+NumV],CacheTr,Rho,DS,DW,dXdxI,J,M,Glob,InteriorFaces,
      KoeffDiv,ndrange=ndrangeI)
  end  
  KGradKernel!(F,U,p,DS,dXdxI,J,M,MRho,Glob,InteriorFaces,Phys,ndrange=ndrangeI)
  KMomentumCoriolisKernel!(F,U,DS,dXdxI,J,X,MRho,M,Glob,InteriorFaces,Phys,ndrange=ndrangeI)
  KDivRhoThUpwind3Kernel!(F,U,DS,dXdxI,J,M,Glob,InteriorFaces,ndrange=ndrangeI)
  for iT = 1 : NumTr
    @views KDivRhoTrUpwind3Kernel!(F[:,:,iT+NumV],U[:,:,iT+NumV],U,DS,
      dXdxI,J,M,Glob,InteriorFaces,ndrange=ndrangeI)
  end  
  if Global.Model.VerticalDiffusion
    @views KVerticalDiffusionScalarKernel!(F[:,:,5],U[:,:,5],Rho,KV,
      dXdxI,J,M,Glob,InteriorFaces,ndrange=ndrangeI)
    for iT = 1 : NumTr
      @views KVerticalDiffusionScalarKernel!(F[:,:,iT+NumV],U[:,:,iT+NumV],Rho,KV,
        dXdxI,J,M,Glob,InteriorFaces,ndrange=ndrangeI)
    end  
  end    
  if Global.Model.SurfaceFlux
    ndrangeSB = (N * N,length(BoundaryFaces))  
    ndrangeSI = (N * N,length(InteriorFaces))  
    KSurfaceFluxScalarsKernel(F,U,p,TSurf,RhoVSurf,uStar,CT,CH,dXdxI,Glob,InteriorFaces,M,Phys,ndrange=ndrangeSI)
  end  
  KernelAbstractions.synchronize(backend)
      
  Parallels.ExchangeData3DRecvGPU!(F,Exchange)
  KernelAbstractions.synchronize(backend)

  if Global.Model.Forcing
    KForceKernel! = ForceKernel!(backend, groupG)
    KForceKernel!(Force,F,U,p,lat,ndrange=ndrangeG)  
    KernelAbstractions.synchronize(backend)
  end  

  if Global.Model.Microphysics
    KMicrophysicsKernel! = MicrophysicsKernel!(backend, groupG)
    KMicrophysicsKernel!(MicrophysicsSource,F,U,p,ndrange=ndrangeG)
    KernelAbstractions.synchronize(backend)
  end

end


