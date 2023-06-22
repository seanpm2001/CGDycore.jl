function FcnPrepare!(U,CG,Global,Param,DiscType::Val{:VectorInvariant})
(;  RhoPos,
    uPos,
    vPos,
    wPos,
    ThPos,
    NumV,
    NumTr) = Global.Model

  Phys=Global.Phys
  Grav=Global.Phys.Grav
  OP=CG.OrdPoly+1;
  NF=Global.Grid.NumFaces;
  nz=Global.Grid.nz;
  J = Global.Metric.J
  RhoCG = Global.Cache.RhoCG
  ThCG = Global.Cache.ThCG
  TrCG = Global.Cache.TrCG
  v1CG = Global.Cache.v1CG
  v2CG = Global.Cache.v2CG
  wCG = Global.Cache.wCG
  PresCG = Global.Cache.PresCG
  KVCG = Global.Cache.KVCG
  wConFCG = Global.Cache.pBGrdCG
  wConCCG = Global.Cache.RhoBGrdCG
  @views CdThCG = Global.Cache.ThCG[:,:,1]
  @views CdTrCG = Global.Cache.TrCG[:,:,1,:]
  KE = Global.Cache.KE
  AuxG = Global.Cache.AuxG
  @views PresG = Global.Cache.AuxG[:,:,1]
  @views KVG = Global.Cache.AuxG[:,:,2]
  @views wConFG = Global.Cache.AuxG[:,:,3]
  @views wConCG = Global.Cache.AuxG[:,:,4]
  @views CdThG = Global.Cache.Aux2DG[:,:,1]
  @views CdTrG = Global.Cache.Aux2DG[:,:,2:1+NumTr]
  Aux2DG = Global.Cache.Aux2DG
  zPG = Global.Cache.zPG
  zP = Global.Metric.zP
  uStar = Global.Cache.uStar
  @. AuxG = 0.0
  @inbounds for iF in Global.Grid.BoundaryFaces
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          RhoCG[iP,jP,iz] = U[iz,ind,RhoPos]
          v1CG[iP,jP,iz] = U[iz,ind,uPos]
          v2CG[iP,jP,iz] = U[iz,ind,vPos]
          wCG[iP,jP,iz+1] = U[iz,ind,wPos]
          ThCG[iP,jP,iz] = U[iz,ind,ThPos]
          zPG[iP,jP,iz] = zP[iz,ind]
          @inbounds for iT = 1:NumTr
            TrCG[iP,jP,iz,iT] = U[iz,ind,NumV+iT]
          end
        end
      end
    end
#   Pressure
    @views Pressure!(PresCG,ThCG,RhoCG,TrCG,KE,zPG,Global)
    if Global.Model.VerticalDiffusion || Global.Model.SurfaceFlux
#     uStar
      @views uStarCoefficient!(uStar[:,:,iF],v1CG[:,:,1],v2CG[:,:,1],wCG[:,:,2],CG,
        Global.Metric.dXdxI[:,:,1,1,:,:,iF],Global.Metric.nS[:,:,:,iF])

#     Vertical Diffusion coefficient    
      if Global.Model.VerticalDiffusion
        eddy_diffusivity_coefficient!(KVCG,v1CG,v2CG,wCG,RhoCG,PresCG,CG,Global,Param,iF)
      end   
    end  
    @views wContraFace!(wConFCG,v1CG,v2CG,wCG,RhoCG,
      Global.Metric.dXdxI[:,:,:,:,3,:,iF],Global.Metric.J[:,:,:,:,iF])
    @views wContraCell!(wConCCG,v1CG,v2CG,wCG,RhoCG,
      Global.Metric.dXdxI[:,:,:,:,3,:,iF],Global.Metric.J[:,:,:,:,iF])
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        for iz = 1 : nz
          PresG[iz,ind] += PresCG[iP,jP,iz] *
            (J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF])  / CG.M[iz,ind]
          KVG[iz,ind] += KVCG[iP,jP,iz] *
            (J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF])  / CG.M[iz,ind]
          wConFG[iz,ind] += wConFCG[iP,jP,iz] *
            (J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF])  / CG.M[iz,ind]
          wConCG[iz,ind] += wConCCG[iP,jP,iz] *
            (J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF])  / CG.M[iz,ind]
        end    
      end
    end
  end  
  ExchangeData3DSend(AuxG,Global.Exchange)
  @inbounds for iF in Global.Grid.InteriorFaces
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          RhoCG[iP,jP,iz] = U[iz,ind,RhoPos]
          v1CG[iP,jP,iz] = U[iz,ind,uPos]
          v2CG[iP,jP,iz] = U[iz,ind,vPos]
          wCG[iP,jP,iz+1] = U[iz,ind,wPos]
          ThCG[iP,jP,iz] = U[iz,ind,ThPos]
          zPG[iP,jP,iz] = zP[iz,ind]
          @inbounds for iT = 1:NumTr
            TrCG[iP,jP,iz,iT] = U[iz,ind,NumV+iT]
          end
        end
      end
    end
#   Pressure
    @views Pressure!(PresCG,ThCG,RhoCG,TrCG,KE,zPG,Global)
    if Global.Model.VerticalDiffusion || Global.Model.SurfaceFlux
#     uStar
      @views uStarCoefficient!(uStar[:,:,iF],v1CG[:,:,1],v2CG[:,:,1],wCG[:,:,2],CG,
        Global.Metric.dXdxI[:,:,1,1,:,:,iF],Global.Metric.nS[:,:,:,iF])

#     Vertical Diffusion coefficient    
      if Global.Model.VerticalDiffusion
        eddy_diffusivity_coefficient!(KVCG,v1CG,v2CG,wCG,RhoCG,PresCG,CG,Global,Param,iF)
      end   
    end  
    @views wContraFace!(wConFCG,v1CG,v2CG,wCG,RhoCG,
      Global.Metric.dXdxI[:,:,:,:,3,:,iF],Global.Metric.J[:,:,:,:,iF])
    @views wContraCell!(wConCCG,v1CG,v2CG,wCG,RhoCG,
      Global.Metric.dXdxI[:,:,:,:,3,:,iF],Global.Metric.J[:,:,:,:,iF])
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          PresG[iz,ind] += PresCG[iP,jP,iz] *
            (J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF])  / CG.M[iz,ind]
          KVG[iz,ind] += KVCG[iP,jP,iz] *
            (J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF])  / CG.M[iz,ind]
          wConFG[iz,ind] += wConFCG[iP,jP,iz] *
            (J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF])  / CG.M[iz,ind]
          wConCG[iz,ind] += wConCCG[iP,jP,iz] *
            (J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF])  / CG.M[iz,ind]
        end
      end
    end
  end
  ExchangeData3DRecv!(AuxG,Global.Exchange)

  @. CdThG = 0.0
  @. CdTrG = 0.0
  @inbounds for iF in Global.Grid.BoundaryFaces
    if Global.Model.SurfaceFlux
      Cd_coefficient!(CdThCG,CdTrCG,CG,Global,Param,iF)
    end   
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        CdThG[1,ind] += CdThCG[iP,jP] *
          (J[iP,jP,1,1,iF] + J[iP,jP,2,1,iF])  / CG.M[1,ind]
        @views @. CdTrG[1,ind,:] += CdTrCG[iP,jP,1,:] *
          (J[iP,jP,1,1,iF] + J[iP,jP,2,1,iF])  / CG.M[1,ind]
      end
    end
  end  
  ExchangeData3DSend(Aux2DG,Global.Exchange)
  @inbounds for iF in Global.Grid.InteriorFaces
    if Global.Model.SurfaceFlux
      Cd_coefficient!(CdThCG,CdTrCG,CG,Global,Param,iF)
    end   

    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        CdThG[1,ind] += CdThCG[iP,jP,1] *
          (J[iP,jP,1,1,iF] + J[iP,jP,2,1,iF])  / CG.M[1,ind] / Global.Metric.dz[1,ind]
        @views @. CdTrG[1,ind,:] += CdTrCG[iP,jP,1,:] *
          (J[iP,jP,1,1,iF] + J[iP,jP,2,1,iF])  / CG.M[1,ind] / Global.Metric.dz[1,ind]
      end
    end
  end
  ExchangeData3DRecv!(Aux2DG,Global.Exchange)
end

function Fcn!(F,U,CG,Global,Param,DiscType::Val{:VectorInvariant})

(;  RhoPos,
    uPos,
    vPos,
    wPos,
    ThPos,
    NumV,
    NumTr) = Global.Model

  Phys=Global.Phys    
  Grav=Global.Phys.Grav    
  OP=CG.OrdPoly+1;
  NF=Global.Grid.NumFaces;
  nz=Global.Grid.nz;
  J = Global.Metric.J
  zP = Global.Metric.zP
  Temp1 = Global.Cache.Temp1
  @views Rot1 = Global.Cache.Temp1[:,:,1]
  @views Rot2 = Global.Cache.Temp1[:,:,2]
  @views Grad1 = Global.Cache.Temp1[:,:,3]
  @views Grad2 = Global.Cache.Temp1[:,:,4]
  @views Div = Global.Cache.Temp1[:,:,5]
  @views DivTh = Global.Cache.Temp1[:,:,6]
  @views Divw = Global.Cache.Temp1[:,:,7]
  @views JRho = Global.Cache.Temp1[:,:,8]
  @views JRhoF = Global.Cache.Temp1[:,:,9]
  @views DivTr = Global.Cache.Temp1[:,:,9+1:9+NumTr]
  FCG=Global.Cache.FCC
  FwCG=Global.Cache.FwCC
  Rot1CG=Global.Cache.Rot1C
  Rot2CG=Global.Cache.Rot2C
  Grad1CG=Global.Cache.Grad1C
  Grad2CG=Global.Cache.Grad2C
  DivCG=Global.Cache.DivC
  DivThCG=Global.Cache.DivThC
  DivwCG=Global.Cache.DivwC
  DivTrCG=Global.Cache.DivC
  @views RhoCG = Global.Cache.RhoCG[:,:,:]
  v1CG = Global.Cache.v1CG
  v2CG = Global.Cache.v2CG
  wCG = Global.Cache.wCG
  wCCG = Global.Cache.wCCG
  zPG = Global.Cache.zPG
  pBGrdCG = Global.Cache.pBGrdCG
  RhoBGrdCG = Global.Cache.RhoBGrdCG
  @views ThCG = Global.Cache.ThCG[:,:,:]
  @views TrCG = Global.Cache.TrCG[:,:,:,:]
  KE = Global.Cache.KE
  PresCG = Global.Cache.PresCG
  @views PresG = Global.Cache.AuxG[:,:,1]
  @views KVG = Global.Cache.AuxG[:,:,2]
  Temp = Global.Cache.Temp
  uStar = Global.Cache.uStar
  KVCG = Global.Cache.KVCG
  qMin = Global.Cache.qMin
  qMax = Global.Cache.qMax

  @. Rot1 = 0.0
  @. Rot2 = 0.0
  @. Grad1 = 0.0
  @. Grad2 = 0.0
  @. Div = 0.0
  @. DivTh = 0.0
  @. Divw = 0.0
  @. DivTr = 0.0
  @. F = 0.0
  @. JRho = 0.0
  @. JRhoF = 0.0


  # Hyperdiffusion 
  @inbounds for iF in Global.Grid.BoundaryFaces
    @inbounds for jP = 1 : OP
      @inbounds for iP = 1 : OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz = 1 : nz
          RhoCG[iP,jP,iz] = U[iz,ind,RhoPos]
          v1CG[iP,jP,iz] = U[iz,ind,uPos]
          v2CG[iP,jP,iz] = U[iz,ind,vPos]
          wCG[iP,jP,iz+1] = U[iz,ind,wPos]
          ThCG[iP,jP,iz] = U[iz,ind,ThPos]
        end
      end
    end
      

    @views RotCurl!(Rot1CG,Rot2CG,v1CG,v2CG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views GradDiv!(Grad1CG,Grad2CG,v1CG,v2CG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views DivRhoGrad!(DivCG,RhoCG,RhoCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views DivRhoGrad!(DivThCG,ThCG,RhoCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views DivGradF!(DivwCG,wCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)

    @inbounds for jP = 1 : OP
      @inbounds for iP = 1 : OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz = 1 : nz
          Rot1[iz,ind] += Rot1CG[iP,jP,iz] 
          Rot2[iz,ind] += Rot2CG[iP,jP,iz] 
          Grad1[iz,ind] += Grad1CG[iP,jP,iz] 
          Grad2[iz,ind] += Grad2CG[iP,jP,iz] 
          Div[iz,ind] += DivCG[iP,jP,iz] 
          DivTh[iz,ind] += DivThCG[iP,jP,iz] 
          JRho[iz,ind] += (J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF]) * RhoCG[iP,jP,iz]
        end
        @inbounds for iz=1:nz-1
          JRhoF[iz,ind] += (J[iP,jP,2,iz,iF] * RhoCG[iP,jP,iz] + J[iP,jP,1,iz+1,iF] * RhoCG[iP,jP,iz+1])
          Divw[iz,ind] += DivwCG[iP,jP,iz+1] 
        end
      end
    end
    @inbounds for iT=1:NumTr
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            ThCG[iP,jP,iz] = U[iz,ind,NumV+iT]
          end
        end
      end
      @views DivRhoGrad!(DivCG,ThCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            DivTr[iz,ind,iT] += DivCG[iP,jP,iz]
          end
        end
      end
    end
  end

  ExchangeData3DSend(Temp1,Global.Exchange)

  @inbounds for iF in Global.Grid.InteriorFaces
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          RhoCG[iP,jP,iz] = U[iz,ind,RhoPos]
          v1CG[iP,jP,iz] = U[iz,ind,uPos]
          v2CG[iP,jP,iz] = U[iz,ind,vPos]
          wCG[iP,jP,iz+1] = U[iz,ind,wPos]
          ThCG[iP,jP,iz] = U[iz,ind,ThPos]
        end
      end
    end
      

    @views RotCurl!(Rot1CG,Rot2CG,v1CG,v2CG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views GradDiv!(Grad1CG,Grad2CG,v1CG,v2CG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views DivRhoGrad!(DivCG,RhoCG,RhoCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views DivRhoGrad!(DivThCG,ThCG,RhoCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views DivGradF!(DivwCG,wCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)

    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          Rot1[iz,ind] += Rot1CG[iP,jP,iz] 
          Rot2[iz,ind] += Rot2CG[iP,jP,iz] 
          Grad1[iz,ind] += Grad1CG[iP,jP,iz] 
          Grad2[iz,ind] += Grad2CG[iP,jP,iz] 
          Div[iz,ind] += DivCG[iP,jP,iz] 
          DivTh[iz,ind] += DivThCG[iP,jP,iz] 
          JRho[iz,ind] += (J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF]) * RhoCG[iP,jP,iz]
        end
        @inbounds for iz=1:nz-1
          JRhoF[iz,ind] += (J[iP,jP,2,iz,iF] * RhoCG[iP,jP,iz] + J[iP,jP,1,iz+1,iF] * RhoCG[iP,jP,iz+1])
          Divw[iz,ind] += DivwCG[iP,jP,iz+1] 
        end
      end
    end
    @inbounds for iT=1:NumTr
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            ThCG[iP,jP,iz] = U[iz,ind,NumV+iT]
          end
        end
      end
      @views DivRhoGrad!(DivCG,ThCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            DivTr[iz,ind,iT] += DivCG[iP,jP,iz] 
          end
        end
      end
    end
  end

  ExchangeData3DRecv!(Temp1,Global.Exchange)

  @inbounds for iF in Global.Grid.BoundaryFaces
    @inbounds for jP = 1 : OP
      @inbounds for iP = 1 : OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz = 1 : nz
          RhoCG[iP,jP,iz] = U[iz,ind,RhoPos]
          v1CG[iP,jP,iz] = U[iz,ind,uPos]
          v2CG[iP,jP,iz] = U[iz,ind,vPos]
          wCG[iP,jP,iz+1] = U[iz,ind,wPos]
          ThCG[iP,jP,iz] = U[iz,ind,ThPos]
          Rot1CG[iP,jP,iz] = Rot1[iz,ind] / CG.M[iz,ind]
          Rot2CG[iP,jP,iz] = Rot2[iz,ind] / CG.M[iz,ind]
          Grad1CG[iP,jP,iz] = Grad1[iz,ind] / CG.M[iz,ind]
          Grad2CG[iP,jP,iz] = Grad2[iz,ind] / CG.M[iz,ind]
          DivCG[iP,jP,iz] = Div[iz,ind] / CG.M[iz,ind]
          DivThCG[iP,jP,iz] = DivTh[iz,ind] / CG.M[iz,ind]
          zPG[iP,jP,iz] = zP[iz,ind]
          pBGrdCG[iP,jP,iz] = Global.pBGrd[iz,ind]
          RhoBGrdCG[iP,jP,iz] = Global.RhoBGrd[iz,ind]
          PresCG[iP,jP,iz] = PresG[iz,ind]
          KVCG[iP,jP,iz] = KVG[iz,ind]
          @inbounds for iT = 1:NumTr
            TrCG[iP,jP,iz,iT] = U[iz,ind,NumV+iT] 
          end  
        end
        @inbounds for iz = 1 : nz - 1
          DivwCG[iP,jP,iz+1] = Divw[iz,ind] / CG.MW[iz,ind]
        end
      end
    end
    @. FCG = 0.0
    @. FwCG = 0.0

#   Hyperdiffusion Part 2
    @views RotCurl!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],Rot1CG,Rot2CG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDCurl)
    @views GradDiv!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],Grad1CG,Grad2CG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDGrad)
    @views DivRhoGrad!(FCG[:,:,:,RhoPos],DivCG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDDiv)
    @views DivRhoGrad!(FCG[:,:,:,ThPos],DivThCG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDDiv)
    @views DivGradF!(FwCG,DivwCG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDDiv)

#   Diagnostic values
#   Boundary value for vertical velocity and cell center   
    @views BoundaryW!(wCG[:,:,:],v1CG[:,:,:],v2CG[:,:,:],CG,
      Global.Metric.J,Global.Metric.dXdxI[:,:,:,1,:,:,iF])
    @views @. wCCG = 0.5*(wCG[:,:,1:nz] + wCG[:,:,2:nz+1])

    @views DivRhoColumn!(FCG[:,:,:,RhoPos],v1CG,v2CG,wCG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
#     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,DiscType)

    if Global.Model.RefProfile
      @views @. pBGrdCG = PresCG - pBGrdCG  
      @views @. RhoBGrdCG = RhoCG - RhoBGrdCG  
      @views GradColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],pBGrdCG,RhoBGrdCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,Phys)
      if Global.Model.Buoyancy
        @views Buoyancy!(FwCG,RhoBGrdCG,Global.Metric.J[:,:,:,:,iF],Phys)  
      end
    else
      @views GradColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],PresCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,Phys)
      if Global.Model.Buoyancy
        @views Buoyancy!(FwCG,RhoCG,Global.Metric.J[:,:,:,:,iF],Phys)  
      end
    end
    if Global.Model.Curl
#     3-dim Curl and Grad of kinetic Energy
#     Kinetic energy
      @views RhoGradKinColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],
        v1CG,v2CG,wCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
      @views MomentumColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],
        v1CG,v2CG,wCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
    else
      @views MomentumColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG,
        v1CG,v2CG,wCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:Advection))
    end    
    if Global.Model.Coriolis
      str = Global.Model.CoriolisType
      if str == "Sphere"
        Omega = Global.Phys.Omega
        @views CoriolisColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],v1CG,v2CG,RhoCG,CG,
          Global.Metric.X[:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Omega)
      end
    end  
#   Surface Momentum
    if Global.Model.SurfaceFluxMom
      @views BoundaryFluxMomentum!(FCG[:,:,1,uPos],FCG[:,:,1,vPos],v1CG[:,:,1],v2CG[:,:,1],
        wCG[:,:,1],Global,Param,iF)  
    end  
    if Global.Model.VerticalDiffusionMom
      @views VerticalDiffusionMomentum!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],v1CG,v2CG,RhoCG,KVCG,
        Global.Metric.dXdxI[:,:,:,:,3,3,iF],Global.Metric.J[:,:,:,:,iF],Global.Cache)
    end  


#   Divergence of Thermodynamic Variable
    if Global.Model.Thermo == "TotalEnergy"
      @views @. ThCG = ThCG + Pres[:,:,:,iF]  
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit)
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
      end
    elseif Global.Model.Thermo == "InternalEnergy" 
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit)
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
      end
      @views SourceIntEnergy!(FCG[:,:,:,ThPos],Pres[:,:,:,iF],v1CG,v2CG,wCG,CG,
       Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
    else
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:VectorInvariant))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
      end
      if Global.Model.VerticalDiffusion
        @views VerticalDiffusionScalar!(FCG[:,:,:,ThPos],ThCG,RhoCG,KVCG,CG,
          Global.Metric.dXdxI[:,:,:,:,3,3,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache)
      end  
    end  
#   Tracer transport
    @inbounds for iT = 1:NumTr
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            DivTrCG[iP,jP,iz] = DivTr[iz,ind,iT] / CG.M[iz,ind]
          end
        end
      end
#     Hyperdiffusion, second Laplacian
      @views DivRhoGrad!(FCG[:,:,:,iT+NumV],DivTrCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
        Global.Model.HyperDDiv)
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,iT+NumV],v1CG,v2CG,wCG,TrCG[:,:,:,iT],RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:VectorInvariant))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,iT+NumV],v1CG,v2CG,wCG,TrCG[:,:,:,iT],CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
      end
      if Global.Model.VerticalDiffusion
        @views VerticalDiffusionScalarRho!(FCG[:,:,:,iT+NumV],FCG[:,:,:,RhoPos],TrCG[:,:,:,iT],RhoCG,KVCG,CG,
          Global.Metric.dXdxI[:,:,:,:,3,3,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache)
      end  
    end
    if Global.Model.SurfaceFlux
      @views BoundaryFluxScalar!(FCG[:,:,1,:],ThCG[:,:,1],RhoCG[:,:,1],TrCG[:,:,1,:],PresCG[:,:,1],CG,Global,Param,iF)
    end  

    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          F[iz,ind,RhoPos] += FCG[iP,jP,iz,RhoPos] 
          F[iz,ind,uPos] += FCG[iP,jP,iz,uPos]
          F[iz,ind,vPos] += FCG[iP,jP,iz,vPos]
          F[iz,ind,ThPos] += FCG[iP,jP,iz,ThPos] 
          @inbounds for iT = 1:NumTr
            F[iz,ind,iT+NumV] += FCG[iP,jP,iz,iT+NumV] 
          end
        end
        @inbounds for iz=1:nz-1
          F[iz,ind,wPos] += FwCG[iP,jP,iz+1] 
        end
      end  
    end
  end  

  ExchangeData3DSend(F,Global.Exchange)

  @inbounds for iF in Global.Grid.InteriorFaces
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          RhoCG[iP,jP,iz] = U[iz,ind,RhoPos]
          v1CG[iP,jP,iz] = U[iz,ind,uPos]
          v2CG[iP,jP,iz] = U[iz,ind,vPos]
          wCG[iP,jP,iz+1] = U[iz,ind,wPos]
          ThCG[iP,jP,iz] = U[iz,ind,ThPos]
          Rot1CG[iP,jP,iz] = Rot1[iz,ind] / CG.M[iz,ind]
          Rot2CG[iP,jP,iz] = Rot2[iz,ind] / CG.M[iz,ind]
          Grad1CG[iP,jP,iz] = Grad1[iz,ind] / CG.M[iz,ind]
          Grad2CG[iP,jP,iz] = Grad2[iz,ind] / CG.M[iz,ind]
          DivCG[iP,jP,iz] = Div[iz,ind] / CG.M[iz,ind]
          DivThCG[iP,jP,iz] = DivTh[iz,ind] / CG.M[iz,ind]
          pBGrdCG[iP,jP,iz] = Global.pBGrd[iz,ind]
          RhoBGrdCG[iP,jP,iz] = Global.RhoBGrd[iz,ind]
          PresCG[iP,jP,iz] = PresG[iz,ind]
          KVCG[iP,jP,iz] = KVG[iz,ind]
          zPG[iP,jP,iz] = zP[iz,ind]
          @inbounds for iT = 1:NumTr
            TrCG[iP,jP,iz,iT] = U[iz,ind,NumV+iT]
          end  
        end
        @inbounds for iz = 1 : nz - 1
          DivwCG[iP,jP,iz+1] = Divw[iz,ind] / CG.MW[iz,ind]
        end
      end
    end
    @. FCG = 0.0
    @. FwCG = 0.0

    #   Hyperdiffusion Part 2
    @views RotCurl!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],Rot1CG,Rot2CG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDCurl)
    @views GradDiv!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],Grad1CG,Grad2CG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDGrad)
    @views DivRhoGrad!(FCG[:,:,:,RhoPos],DivCG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDDiv)
    @views DivRhoGrad!(FCG[:,:,:,ThPos],DivThCG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDDiv)
    @views DivGradF!(FwCG,DivwCG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDDiv)

#   Diagnostic values
#   Boundary value for vertical velocity and cell center   
    @views BoundaryW!(wCG[:,:,:],v1CG[:,:,:],v2CG[:,:,:],CG,
      Global.Metric.J,Global.Metric.dXdxI[:,:,:,1,:,:,iF])
    @views @. wCCG = 0.5*(wCG[:,:,1:nz] + wCG[:,:,2:nz+1])

    @views DivRhoColumn!(FCG[:,:,:,RhoPos],v1CG,v2CG,wCG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))

    if Global.Model.RefProfile
      @views @. pBGrdCG = PresCG - pBGrdCG  
      @views @. RhoBGrdCG = RhoCG - RhoBGrdCG  
      @views GradColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],pBGrdCG,RhoBGrdCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,Phys)
      if Global.Model.Buoyancy
        @views Buoyancy!(FwCG,RhoBGrdCG,Global.Metric.J[:,:,:,:,iF],Phys)  
      end
    else
      @views GradColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],PresCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,Phys)
      if Global.Model.Buoyancy
        @views Buoyancy!(FwCG,RhoCG,Global.Metric.J[:,:,:,:,iF],Phys)  
      end
    end
    if Global.Model.Curl
#     3-dim Curl and Grad of kinetic Energy
#     Kinetic energy
      @views RhoGradKinColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],
        v1CG,v2CG,wCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
      @views MomentumColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],
        v1CG,v2CG,wCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
    else
      @views MomentumColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],
        v1CG,v2CG,wCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:Advection))
    end
    if Global.Model.Coriolis
      str = Global.Model.CoriolisType
      if str == "Sphere"
        Omega = Global.Phys.Omega
        @views CoriolisColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],v1CG,v2CG,RhoCG,CG,
          Global.Metric.X[:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Omega)
      end
    end  
#   Surface Momentum
    if Global.Model.SurfaceFluxMom
      @views BoundaryFluxMomentum!(FCG[:,:,1,uPos],FCG[:,:,1,vPos],v1CG[:,:,1],v2CG[:,:,1],
        wCG[:,:,1],Global,Param,iF)  
    end  
    if Global.Model.VerticalDiffusionMom
      @views VerticalDiffusionMomentum!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],v1CG,v2CG,RhoCG,KVCG,
        Global.Metric.dXdxI[:,:,:,:,3,3,iF],Global.Metric.J[:,:,:,:,iF],Global.Cache)
    end  

#   Divergence of Thermodynamic Variable
    if Global.Model.Thermo == "TotalEnergy"
      @views @. ThCG = ThCG + Pres[:,:,:,iF]  
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:VectorInvariant))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
      end
    elseif Global.Model.Thermo == "InternalEnergy" 
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:VectorInvariant))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
      end
      @views SourceIntEnergy!(FCG[:,:,:,ThPos],Pres[:,:,:,iF],v1CG,v2CG,wCG,CG,
       Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
    else
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:VectorInvariant))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
      end
      if Global.Model.VerticalDiffusion
        @views VerticalDiffusionScalar!(FCG[:,:,:,ThPos],ThCG,RhoCG,KVCG,CG,
          Global.Metric.dXdxI[:,:,:,:,3,3,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache)
      end  
    end  
#   Tracer transport
    @inbounds for iT = 1:NumTr
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            DivTrCG[iP,jP,iz] = DivTr[iz,ind,iT] / CG.M[iz,ind]
          end
        end
      end
#     Hyperdiffusion, second Laplacian
      @views DivRhoGrad!(FCG[:,:,:,iT+NumV],DivTrCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
        Global.Model.HyperDDiv)
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,iT+NumV],v1CG,v2CG,wCG,TrCG[:,:,:,iT],RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:VectorInvariant))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,iT+NumV],v1CG,v2CG,wCG,TrCG[:,:,:,iT],CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:VectorInvariant))
      end
      if Global.Model.VerticalDiffusion
        @views VerticalDiffusionScalarRho!(FCG[:,:,:,iT+NumV],FCG[:,:,:,RhoPos],TrCG[:,:,:,iT],RhoCG,KVCG,CG,
          Global.Metric.dXdxI[:,:,:,:,3,3,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache)
      end  
    end
    if Global.Model.SurfaceFlux
      @views BoundaryFluxScalar!(FCG[:,:,1,:],ThCG[:,:,1],RhoCG[:,:,1],TrCG[:,:,1,:],PresCG[:,:,1],CG,Global,Param,iF)
    end  

    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          F[iz,ind,RhoPos] += FCG[iP,jP,iz,RhoPos]
          F[iz,ind,uPos] += FCG[iP,jP,iz,uPos]
          F[iz,ind,vPos] += FCG[iP,jP,iz,vPos]
          F[iz,ind,ThPos] += FCG[iP,jP,iz,ThPos] 
          @inbounds for iT = 1:NumTr
            F[iz,ind,iT+NumV] += FCG[iP,jP,iz,iT+NumV]
          end
        end
        @inbounds for iz=1:nz-1
          F[iz,ind,wPos] += FwCG[iP,jP,iz+1] 
        end
      end  
    end
  end  
  ExchangeData3DRecv!(F,Global.Exchange)
  @views @. F[:,:,RhoPos] /= CG.M
  @views @. F[:,:,ThPos] /= CG.M
  @inbounds for iT = 1:NumTr
    @views @.  F[:,:,iT+NumV] /= CG.M
  end
  @views @. F[:,:,uPos] /= JRho
  @views @. F[:,:,vPos] /= JRho
  @views @. F[1:nz-1,:,wPos] /= JRhoF[1:nz-1,:]

  if Global.Model.Damping
    if Global.Model.Geos
      @inbounds for iG=1:CG.NumG
        @views Damping!(F[:,iG,uPos],F[:,iG,vPos],F[:,iG,wPos],U[:,iG,uPos],
          U[:,iG,vPos],U[:,iG,wPos],Global.UGeo[:,iG],Global.VGeo[:,iG],Global)  
      end
    else    
      @inbounds for iG=1:CG.NumG
        @views Damping!(F[:,iG,wPos],U[:,iG,wPos],Global)  
      end
    end
  end
  if Global.Model.Source
    @inbounds for iG=1:CG.NumG
      @views Source!(F[:,iG,:],U[:,iG,:],PresG[:,iG],CG,Global,Param,iG)
    end
  end
  if Global.Model.Microphysics
    @inbounds for iG=1:CG.NumG
      @views SourceMicroPhysics(F[:,iG,:],U[:,iG,:],PresG[:,iG],CG,Global,iG)
    end  
  end
end

function Fcn!(F,U,CG,Global,Param,::Val{:Conservative})

(;  RhoPos,
    uPos,
    vPos,
    wPos,
    ThPos,
    NumV,
    NumTr) = Global.Model

  Phys=Global.Phys    
  Grav=Global.Phys.Grav    
  OP=CG.OrdPoly+1;
  NF=Global.Grid.NumFaces;
  nz=Global.Grid.nz;
  J = Global.Metric.J
  zP = Global.Metric.zP
  Temp1 = Global.Cache.Temp1
  @views Rot1 = Global.Cache.Temp1[:,:,1]
  @views Rot2 = Global.Cache.Temp1[:,:,2]
  @views Grad1 = Global.Cache.Temp1[:,:,3]
  @views Grad2 = Global.Cache.Temp1[:,:,4]
  @views Div = Global.Cache.Temp1[:,:,NumV]
  @views DivTr = Global.Cache.Temp1[:,:,NumV+1:NumV+NumTr]
  @views JJ = Global.Cache.Temp1[:,:,NumV+NumTr+1]
  FCG=Global.Cache.FCC
  FwCG=Global.Cache.FwCC
  Rot1CG=Global.Cache.Rot1C
  Rot2CG=Global.Cache.Rot2C
  Grad1CG=Global.Cache.Grad1C
  Grad2CG=Global.Cache.Grad2C
  DivCG=Global.Cache.DivC
  DivTrCG=Global.Cache.DivC
  @views RhoCG = Global.Cache.RhoCG[:,:,:]
  v1CG = Global.Cache.v1CG
  v2CG = Global.Cache.v2CG
  wCG = Global.Cache.wCG
  wCCG = Global.Cache.wCCG
  zPG = Global.Cache.zPG
  pBGrdCG = Global.Cache.pBGrdCG
  RhoBGrdCG = Global.Cache.RhoBGrdCG
  @views ThCG = Global.Cache.ThCG[:,:,:]
  @views TrCG = Global.Cache.TrCG[:,:,:,:]
  KE = Global.Cache.KE
  Pres = Global.Cache.Pres
  PresG = Global.Cache.PresG
  Temp = Global.Cache.Temp
  uStar = Global.Cache.uStar
  KVCG = Global.Cache.KVCG
  qMin = Global.Cache.qMin
  qMax = Global.Cache.qMax

  @. Rot1 = 0.0
  @. Rot2 = 0.0
  @. Grad1 = 0.0
  @. Grad2 = 0.0
  @. Div = 0.0
  @. DivTr = 0.0
  @. F = 0.0
  @. PresG = 0.0
  @. JJ = 0.0


  # Hyperdiffusion 
  @inbounds for iF in Global.Grid.BoundaryFaces
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          RhoCG[iP,jP,iz] = U[iz,ind,RhoPos]
          v1CG[iP,jP,iz] = U[iz,ind,uPos] 
          v2CG[iP,jP,iz] = U[iz,ind,vPos] 
          ThCG[iP,jP,iz] = U[iz,ind,ThPos] 
        end
      end
    end
      

    @views RotCurl!(Rot1CG,Rot2CG,v1CG,v2CG,RhoCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views GradDiv!(Grad1CG,Grad2CG,v1CG,v2CG,RhoCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views DivRhoGrad!(DivCG,ThCG,RhoCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)

    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          Rot1[iz,ind] += Rot1CG[iP,jP,iz] 
          Rot2[iz,ind] += Rot2CG[iP,jP,iz] 
          Grad1[iz,ind] += Grad1CG[iP,jP,iz] 
          Grad2[iz,ind] += Grad2CG[iP,jP,iz] 
          Div[iz,ind] += DivCG[iP,jP,iz] 
          JJ[iz,ind] += J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF]
        end
      end
    end
    @inbounds for iT=1:NumTr
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            ThCG[iP,jP,iz] = U[iz,ind,NumV+iT]
          end
        end
      end
      @views DivRhoGrad!(DivCG,ThCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            DivTr[iz,ind,iT] += DivCG[iP,jP,iz]
          end
        end
      end
    end
  end

  ExchangeData3DSend(Temp1,PresG,Global.Exchange)

  @inbounds for iF in Global.Grid.InteriorFaces
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          RhoCG[iP,jP,iz] = U[iz,ind,RhoPos]
          v1CG[iP,jP,iz] = U[iz,ind,uPos] 
          v2CG[iP,jP,iz] = U[iz,ind,vPos] 
          ThCG[iP,jP,iz] = U[iz,ind,ThPos]
        end
      end
    end
      

    @views RotCurl!(Rot1CG,Rot2CG,v1CG,v2CG,RhoCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views GradDiv!(Grad1CG,Grad2CG,v1CG,v2CG,RhoCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
    @views DivRhoGrad!(DivCG,ThCG,RhoCG,CG,
     Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)

    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          Rot1[iz,ind] += Rot1CG[iP,jP,iz] 
          Rot2[iz,ind] += Rot2CG[iP,jP,iz] 
          Grad1[iz,ind] += Grad1CG[iP,jP,iz] 
          Grad2[iz,ind] += Grad2CG[iP,jP,iz] 
          Div[iz,ind] += DivCG[iP,jP,iz] 
          JJ[iz,ind] += J[iP,jP,1,iz,iF] + J[iP,jP,2,iz,iF]
        end
      end
    end
    @inbounds for iT=1:NumTr
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            ThCG[iP,jP,iz] = U[iz,ind,NumV+iT]
          end
        end
      end
      @views DivRhoGrad!(DivCG,ThCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache)
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            DivTr[iz,ind,iT] += DivCG[iP,jP,iz] 
          end
        end
      end
    end
  end

  ExchangeData3DRecv!(Temp1,PresG,Global.Exchange)

  @inbounds for iF in Global.Grid.BoundaryFaces
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          RhoCG[iP,jP,iz] = U[iz,ind,RhoPos]
          v1CG[iP,jP,iz] = U[iz,ind,uPos]
          v2CG[iP,jP,iz] = U[iz,ind,vPos]
          wCG[iP,jP,iz+1] = U[iz,ind,wPos]
          ThCG[iP,jP,iz] = U[iz,ind,ThPos]
          Rot1CG[iP,jP,iz] = Rot1[iz,ind] / JJ[iz,ind]
          Rot2CG[iP,jP,iz] = Rot2[iz,ind] / JJ[iz,ind]
          Grad1CG[iP,jP,iz] = Grad1[iz,ind] / JJ[iz,ind]
          Grad2CG[iP,jP,iz] = Grad2[iz,ind] / JJ[iz,ind]
          DivCG[iP,jP,iz] = Div[iz,ind] / JJ[iz,ind]
          zPG[iP,jP,iz] = zP[iz,ind]
          pBGrdCG[iP,jP,iz] = Global.pBGrd[iz,ind]
          RhoBGrdCG[iP,jP,iz] = Global.RhoBGrd[iz,ind]
          @inbounds for iT = 1:NumTr
            TrCG[iP,jP,iz,iT] = U[iz,ind,NumV+iT] 
          end  
        end
      end
    end
    @. FCG = 0.0
    @. FwCG = 0.0

#   Hyperdiffusion Part 2
    @views RotCurl!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],Rot1CG,Rot2CG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDCurl)
    @views GradDiv!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],Grad1CG,Grad2CG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDGrad)
    @views DivRhoGrad!(FCG[:,:,:,ThPos],DivCG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDDiv)

#   Diagnostic values
#   Boundary value for vertical velocity and cell center   
    @views BoundaryW!(wCG[:,:,:],v1CG[:,:,:],v2CG[:,:,:],CG,
      Global.Metric.J,Global.Metric.dXdxI[:,:,:,1,:,:,iF])
    @views @. wCCG = 0.5*(wCG[:,:,1:nz] + wCG[:,:,2:nz+1])
#   Pressure
    @views Pressure!(Pres[:,:,:,iF],ThCG,RhoCG,TrCG,KE,zPG,Global)
#   Temperature

    if Global.Model.VerticalDiffusion || Global.Model.SurfaceFlux
#     uStar
      @views uStarCoefficient!(uStar[:,:,iF],v1CG[:,:,1],v2CG[:,:,1],wCCG[:,:,1],CG,Global,iF)

#     Vertical Diffusion coefficient    
      if Global.Model.VerticalDiffusion
        eddy_diffusivity_coefficient!(KVCG,v1CG,v2CG,wCCG,RhoCG,CG,Global,Param,iF)
      end   
    end   

    @views DivRhoColumn!(FCG[:,:,:,RhoPos],v1CG,v2CG,wCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)

    if Global.Model.RefProfile
      @views @. pBGrdCG = Pres[:,:,:,iF] - pBGrdCG  
      @views @. RhoBGrdCG = RhoCG - RhoBGrdCG  
      @views GradColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],pBGrdCG,RhoBGrdCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,Phys)
      if Global.Model.Buoyancy
        @views Buoyancy!(FwCG,RhoBGrdCG,Global.Metric.J[:,:,:,:,iF],Phys)  
      end
    else
      @views GradColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],Pres[:,:,:,iF],RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,Phys)
      if Global.Model.Buoyancy
        @views Buoyancy!(FwCG,RhoCG,Global.Metric.J[:,:,:,:,iF],Phys)  
      end
    end
    if Global.Model.Upwind
      @views DivRhoTrColumn!(FCG[:,:,:,uPos],v1CG,v2CG,wCG,v1CG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      @views DivRhoTrColumn!(FCG[:,:,:,vPos],v1CG,v2CG,wCG,v2CG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      @views MomentumWColumn!(FwCG,v1CG,v2CG,wCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:Conservative))
    else    
      @views MomentumColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG,
        v1CG,v2CG,wCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:Conservative))
    end

    if Global.Model.Coriolis
      str = Global.Model.CoriolisType
      if str == "Sphere"
        Omega = Global.Phys.Omega
        @views CoriolisColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],v1CG,v2CG,CG,
          Global.Metric.X[:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Omega)
      end
    end


#   Divergence of Thermodynamic Variable
    if Global.Model.Thermo == "TotalEnergy"
      @views @. ThCG = ThCG + Pres[:,:,:,iF]  
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:Conservative))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      end
    elseif Global.Model.Thermo == "InternalEnergy" 
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:Conservative))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      end
      @views SourceIntEnergy!(FCG[:,:,:,ThPos],Pres[:,:,:,iF],v1CG,v2CG,wCG,CG,
       Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
    else
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:Conservative))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      end
      if Global.Model.VerticalDiffusion
        @views VerticalDiffusionScalar!(FCG[:,:,:,ThPos],ThCG,RhoCG,KVCG,CG,Global,iF)
      end  
    end  
#   Tracer transport
    @inbounds for iT = 1:NumTr
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            DivTrCG[iP,jP,iz] = DivTr[iz,ind,iT]
          end
        end
      end
#     Hyperdiffusion, second Laplacian
      @views DivRhoGrad!(FCG[:,:,:,iT+NumV],DivTrCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
        Global.Model.HyperDDiv)
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,iT+NumV],v1CG,v2CG,wCG,TrCG[:,:,:,iT],RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit)
      else
        @views DivRhoTrColumn!(FCG[:,:,:,iT+NumV],v1CG,v2CG,wCG,TrCG[:,:,:,iT],RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      end
      if Global.Model.VerticalDiffusion
        @views VerticalDiffusionScalar!(FCG[:,:,:,iT+NumV],TrCG[:,:,:,iT],RhoCG,KVCG,CG,Global,iF)
      end  
    end
    if Global.Model.SurfaceFlux
      @views BoundaryFluxScalar!(FCG[:,:,1,:],ThCG[:,:,1],RhoCG[:,:,1],TrCG[:,:,1,:],CG,Global,Param,iF)
    end  

    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          PresG[iz,ind,RhoPos] += Pres[iP,jP,iz,iF] * 
            (J[iP,jP,1,iz,iF] + J[iP,jP,1,iz,iF])  / CG.M[iz,ind]
          F[iz,ind,RhoPos] += FCG[iP,jP,iz,RhoPos] 
          F[iz,ind,uPos] += FCG[iP,jP,iz,uPos]
          F[iz,ind,vPos] += FCG[iP,jP,iz,vPos]
          F[iz,ind,ThPos] += FCG[iP,jP,iz,ThPos] 
          @inbounds for iT = 1:NumTr
            F[iz,ind,iT+NumV] += FCG[iP,jP,iz,iT+NumV] 
          end
        end
        @inbounds for iz=1:nz-1
          F[iz,ind,wPos] += FwCG[iP,jP,iz+1] 
        end
      end  
    end
  end  

  ExchangeData3DSend(F,PresG,Global.Exchange)

  @inbounds for iF in Global.Grid.InteriorFaces
    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          RhoCG[iP,jP,iz] = U[iz,ind,RhoPos]
          v1CG[iP,jP,iz] = U[iz,ind,uPos]
          v2CG[iP,jP,iz] = U[iz,ind,vPos]
          wCG[iP,jP,iz+1] = U[iz,ind,wPos]
          ThCG[iP,jP,iz] = U[iz,ind,ThPos]
          Rot1CG[iP,jP,iz] = Rot1[iz,ind] / JJ[iz,ind]
          Rot2CG[iP,jP,iz] = Rot2[iz,ind] / JJ[iz,ind]
          Grad1CG[iP,jP,iz] = Grad1[iz,ind] / JJ[iz,ind]
          Grad2CG[iP,jP,iz] = Grad2[iz,ind] / JJ[iz,ind]
          DivCG[iP,jP,iz] = Div[iz,ind] / JJ[iz,ind]
          pBGrdCG[iP,jP,iz] = Global.pBGrd[iz,ind]
          RhoBGrdCG[iP,jP,iz] = Global.RhoBGrd[iz,ind]
          zPG[iP,jP,iz] = zP[iz,ind]
          @inbounds for iT = 1:NumTr
            TrCG[iP,jP,iz,iT] = U[iz,ind,NumV+iT]
          end  
        end
      end
    end
    @. FCG = 0.0
    @. FwCG = 0.0

    #   Hyperdiffusion Part 2
    @views RotCurl!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],Rot1CG,Rot2CG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDCurl)
    @views GradDiv!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],Grad1CG,Grad2CG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDGrad)
    @views DivRhoGrad!(FCG[:,:,:,ThPos],DivCG,RhoCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
      Global.Model.HyperDDiv)

#   Diagnostic values
#   Boundary value for vertical velocity and cell center   
    @views BoundaryW!(wCG[:,:,:],v1CG[:,:,:],v2CG[:,:,:],CG,
      Global.Metric.J,Global.Metric.dXdxI[:,:,:,1,:,:,iF])
    @views @. wCCG = 0.5*(wCG[:,:,1:nz] + wCG[:,:,2:nz+1])
#   Pressure
    @views Pressure!(Pres[:,:,:,iF],ThCG,RhoCG,TrCG,KE,zPG,Global)
#   Temperature

    if Global.Model.VerticalDiffusion || Global.Model.SurfaceFlux
#     uStar
      @views uStarCoefficient!(uStar[:,:,iF],v1CG[:,:,1],v2CG[:,:,1],wCCG[:,:,1],CG,Global,iF)

#     Vertical Diffusion coefficient    
      if Global.Model.VerticalDiffusion
        eddy_diffusivity_coefficient!(KVCG,v1CG,v2CG,wCCG,RhoCG,CG,Global,Param,iF)
      end   
    end   

    @views DivRhoColumn!(FCG[:,:,:,RhoPos],v1CG,v2CG,wCG,CG,
      Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)

    if Global.Model.RefProfile
      @views @. pBGrdCG = Pres[:,:,:,iF] - pBGrdCG  
      @views @. RhoBGrdCG = RhoCG - RhoBGrdCG  
      @views GradColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],pBGrdCG,RhoBGrdCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,Phys)
      if Global.Model.Buoyancy
        @views Buoyancy!(FwCG,RhoBGrdCG,Global.Metric.J[:,:,:,:,iF],Phys)  
      end
    else
      @views GradColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG[:,:,:],Pres[:,:,:,iF],RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,Phys)
      if Global.Model.Buoyancy
        @views Buoyancy!(FwCG,RhoCG,Global.Metric.J[:,:,:,:,iF],Phys)  
      end
    end

    if Global.Model.Upwind
      @views DivRhoTrColumn!(FCG[:,:,:,uPos],v1CG,v2CG,wCG,v1CG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      @views DivRhoTrColumn!(FCG[:,:,:,vPos],v1CG,v2CG,wCG,v2CG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      @views MomentumWColumn!(FwCG,v1CG,v2CG,wCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:Conservative))
    else    
      @views MomentumColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],FwCG,
        v1CG,v2CG,wCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache,Val(:Conservative))
    end  

    if Global.Model.Coriolis
      str = Global.Model.CoriolisType
      if str == "Sphere"
        Omega = Global.Phys.Omega
        @views CoriolisColumn!(FCG[:,:,:,uPos],FCG[:,:,:,vPos],v1CG,v2CG,CG,
          Global.Metric.X[:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Omega)
      end
    end

#   Divergence of Thermodynamic Variable
    if Global.Model.Thermo == "TotalEnergy"
      @views @. ThCG = ThCG + Pres[:,:,:,iF]  
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:Conservative))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      end
    elseif Global.Model.Thermo == "InternalEnergy" 
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:Conservative))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      end
      @views SourceIntEnergy!(FCG[:,:,:,ThPos],Pres[:,:,:,iF],v1CG,v2CG,wCG,CG,
       Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
    else
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:Conservative))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,ThPos],v1CG,v2CG,wCG,ThCG,RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      end
      if Global.Model.VerticalDiffusion
        @views VerticalDiffusionScalar!(FCG[:,:,:,ThPos],ThCG,RhoCG,KVCG,CG,Global,iF)
      end  
    end  
#   Tracer transport
    @inbounds for iT = 1:NumTr
      @inbounds for jP=1:OP
        @inbounds for iP=1:OP
          ind = CG.Glob[iP,jP,iF]
          @inbounds for iz=1:nz
            DivTrCG[iP,jP,iz] = DivTr[iz,ind,iT]
          end
        end
      end
#     Hyperdiffusion, second Laplacian
      @views DivRhoGrad!(FCG[:,:,:,iT+NumV],DivTrCG,RhoCG,CG,
        Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],Global.ThreadCache,
        Global.Model.HyperDDiv)
      if Global.Model.Upwind
        @views DivUpwindRhoTrColumn!(FCG[:,:,:,iT+NumV],v1CG,v2CG,wCG,TrCG[:,:,:,iT],RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.Metric.J[:,:,:,:,iF],
          Global.ThreadCache,Global.Model.HorLimit,Val(:Conservative))
      else
        @views DivRhoTrColumn!(FCG[:,:,:,iT+NumV],v1CG,v2CG,wCG,TrCG[:,:,:,iT],RhoCG,CG,
          Global.Metric.dXdxI[:,:,:,:,:,:,iF],Global.ThreadCache)
      end
      if Global.Model.VerticalDiffusion
        @views VerticalDiffusionScalar!(FCG[:,:,:,iT+NumV],TrCG[:,:,:,iT],RhoCG,KVCG,CG,Global,iF)
      end  
    end
    if Global.Model.SurfaceFlux
      @views BoundaryFluxScalar!(FCG[:,:,1,:],ThCG[:,:,1],RhoCG[:,:,1],TrCG[:,:,1,:],CG,Global,Param,iF)
    end  

    @inbounds for jP=1:OP
      @inbounds for iP=1:OP
        ind = CG.Glob[iP,jP,iF]
        @inbounds for iz=1:nz
          PresG[iz,ind,RhoPos] += Pres[iP,jP,iz,iF] * 
            (J[iP,jP,1,iz,iF] + J[iP,jP,1,iz,iF])  / CG.M[iz,ind]
          F[iz,ind,RhoPos] += FCG[iP,jP,iz,RhoPos]
          F[iz,ind,uPos] += FCG[iP,jP,iz,uPos]
          F[iz,ind,vPos] += FCG[iP,jP,iz,vPos]
          F[iz,ind,ThPos] += FCG[iP,jP,iz,ThPos] 
          @inbounds for iT = 1:NumTr
            F[iz,ind,iT+NumV] += FCG[iP,jP,iz,iT+NumV]
          end
        end
        @inbounds for iz=1:nz-1
          F[iz,ind,wPos] += FwCG[iP,jP,iz+1] 
        end
      end  
    end
  end  
  ExchangeData3DRecv!(F,PresG,Global.Exchange)
  @views @. F[:,:,RhoPos] /= JJ
  @views @. F[:,:,ThPos] /= JJ
  @inbounds for iT = 1:NumTr
    @views @.  F[:,:,iT+NumV] /= JJ
  end
  @views @. F[:,:,uPos] /= JJ
  @views @. F[:,:,vPos] /= JJ
  @views @. F[1:nz-1,:,wPos] /= 0.5 *(JJ[1:nz-1,:] + JJ[2:nz,:])

  if Global.Model.Damping
    @inbounds for iG=1:CG.NumG
      @views Damping!(F[:,iG,wPos],U[:,iG,wPos],Global)  
    end
  end
  if Global.Model.Source
    @inbounds for iG=1:CG.NumG
      @views Source!(F[:,iG,:],U[:,iG,:],PresG[:,iG],CG,Global,Param,iG)
    end
  end
  if Global.Model.Microphysics
    @inbounds for iG=1:CG.NumG
      @views SourceMicroPhysics(F[:,iG,:],U[:,iG,:],PresG[:,iG],CG,Global,iG)
    end  
  end
end
