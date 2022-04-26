function BoundaryW!(wCG,v1CG,v2CG,CG,Global,iF)
dXdxIC = Global.Metric.dXdxIC
@views @. wCG= -(dXdxIC[:,:,1,3,1,iF] * v1CG[:,:,1] +
  dXdxIC[:,:,1,3,2,iF] * v2CG[:,:,1])/
  dXdxIC[:,:,1,3,3,iF]
end



