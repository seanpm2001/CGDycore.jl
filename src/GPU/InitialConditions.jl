function InitialConditions(backend,FTB,CG,Metric,Phys,Global,Profile,Param)
  Model = Global.Model
  Nz = Global.Grid.nz
  NF = Global.Grid.NumFaces
  NumV = Model.NumV
  NumTr = Model.NumTr
  State = Model.State
  N = CG.OrdPoly + 1
  Glob = CG.Glob
  X = Metric.X
  time = 0


  # Ranges
  NzG = min(div(256,N*N),Nz)
  group = (N * N, NzG, 1)
  ndrange = (N * N, Nz, NF)
  lengthU = NumV
  if Model.TkePos > 0
    lengthU += 1
  end  
  if NumTr > 0
    lengthU += NumTr  
  end
  if Model.EDMF
    ND = Model.NDEDMF  
    lengthU += ND*(1 + 1 + 1 + NumTr)
  end    

  U = KernelAbstractions.zeros(backend,FTB,Nz,CG.NumG,lengthU)
  @views Rho = U[:,:,Model.RhoPos]
  @views u = U[:,:,Model.uPos]
  @views v = U[:,:,Model.vPos]
  @views w = U[:,:,Model.wPos]
  @views RhoTh = U[:,:,Model.ThPos]
  KRhoFunCKernel! = RhoFunCKernel!(backend, group)
  KuvwFunCKernel! = uvwFunCKernel!(backend, group)

  KRhoFunCKernel!(Profile,Rho,time,Glob,X,Param,Phys,ndrange=ndrange)
  KernelAbstractions.synchronize(backend)
  KuvwFunCKernel!(Profile,u,v,w,time,Glob,X,Param,Phys,ndrange=ndrange)
  KernelAbstractions.synchronize(backend)
  if State == "Dry" || State == "Moist" || State == "ShallowWater"
    KRhoThFunCKernel! = RhoThFunCKernel!(backend, group)
    KRhoThFunCKernel!(Profile,RhoTh,time,Glob,X,ndrange=ndrange)
  elseif State == "DryEnergy" || State == "MoistEnergy"
    KRhoEFunCKernel! = RhoEFunCKernel!(backend, group)
    KRhoEFunCKernel!(Profile,RhoTh,time,Glob,X,ndrange=ndrange)
  end
  KernelAbstractions.synchronize(backend)
  if Model.RhoVPos > 0
    @views RhoV = U[:,:,Model.RhoVPos]
    KRhoVFunCKernel! = RhoVFunCKernel!(backend, group)
    KRhoVFunCKernel!(Profile,RhoV,time,Glob,X,ndrange=ndrange)
    KernelAbstractions.synchronize(backend)
  end  
  if Model.RhoCPos > 0
    @views RhoC = U[:,:,Model.RhoCPos]
    KRhoCFunCKernel! = RhoCFunCKernel!(backend, group)
    KRhoCFunCKernel!(Profile,RhoC,time,Glob,X,ndrange=ndrange)
    KernelAbstractions.synchronize(backend)
  end  
  if Model.TkePos > 0
    @views @. U[:,:,Model.TkePos] = U[:,:,Model.RhoPos] * 1.e-2 
  end  

  return U
end  

function InitialConditionsAdvection(backend,FTB,CG,Metric,Phys,Global,Profile,Param)
  Model = Global.Model
  Nz = Global.Grid.nz
  NF = Global.Grid.NumFaces
  NumV = Model.NumV
  NumTr = Model.NumTr
  N = CG.OrdPoly + 1
  Glob = CG.Glob
  X = Metric.X
  time = 0

  # Ranges
  NzG = min(div(256,N*N),Nz)
  group = (N * N, NzG, 1)
  ndrange = (N * N, Nz, NF)

  U = KernelAbstractions.zeros(backend,FTB,Nz,CG.NumG,NumV+NumTr)
  @views Rho = U[:,:,Model.RhoPos]
  @views u = U[:,:,Model.uPos]
  @views v = U[:,:,Model.vPos]
  @views w = U[:,:,Model.wPos]
  @views Tr = U[:,:,Model.NumV+1]
  KRhoFunCKernel! = RhoFunCKernel!(backend, group)
  KRhoFunCKernel!(Profile,Rho,time,Glob,X,Param,Phys,ndrange=ndrange)
  KernelAbstractions.synchronize(backend)
  KuvwFunCKernel! = uvwFunCKernel!(backend, group)
  KuvwFunCKernel!(Profile,u,v,w,time,Glob,X,Param,Phys,ndrange=ndrange)
  KernelAbstractions.synchronize(backend)
  KTrFunCKernel! = TrFunCKernel!(backend, group)
  KTrFunCKernel!(Profile,Tr,time,Glob,X,Param,Phys,ndrange=ndrange)
  KernelAbstractions.synchronize(backend)
  return U
end  
