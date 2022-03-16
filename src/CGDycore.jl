module CGDycore

#=
Look for

# TODO: check translation with Oswald
=#

# using StatsBase
using LinearAlgebra
include("matlab_intrinsics.jl")

include("Grid/Node/Node.jl")
include("Grid/Edge/Edge.jl")
include("Grid/Face/Face.jl")
# include("Grid/Cell/Cell.jl")
include("Grid/GridStruct.jl")

# include("Grid/Annulus.jl")
# include("Grid/AnnulusGrid.jl")
# include("Grid/CFPToGrid.jl")
# include("Grid/Cart.jl")
include("Grid/CartGrid.jl")
include("Grid/CubedGrid.jl") # translate this
# include("Grid/DGNodes.jl")
# include("Grid/FacesInEdges.jl")
include("Grid/FacesInNodes.jl")
# # include("Grid/GaussLobattoQuad.jl") # delete?
# include("Grid/Grid2DCFP.jl")
# include("Grid/GridToKiteGrid.jl")
# include("Grid/GridToKiteGridNeu.jl")
# include("Grid/HexagonGrid.jl")
# include("Grid/HexagonGridNeu.jl")
# include("Grid/InputGrid.jl")
# include("Grid/JacobiAnnulus.jl")
# include("Grid/JacobiAnnulusCyl.jl")
# include("Grid/JacobiCart.jl")
# include("Grid/JacobiCart1.jl")
# include("Grid/JacobiCartV1.jl")
# include("Grid/JacobiDG.jl")
# include("Grid/JacobiDG1.jl")
# include("Grid/JacobiDG2.jl")
include("Grid/JacobiDG3.jl")
# include("Grid/JacobiShallowSphere3.jl")
# include("Grid/JacobiSphere.jl")
# include("Grid/JacobiSphere2.jl")
# include("Grid/JacobiSphere2TT.jl")
include("Grid/JacobiSphere3.jl")
# include("Grid/JacobiSphereDG.jl")
# include("Grid/JacobiTri.jl")
# include("Grid/MetricGuba.jl")
# include("Grid/MetricGubaOld.jl")
# include("Grid/MetricGubaOld2.jl")
include("Grid/OrientFaceCart.jl")
include("Grid/OrientFaceSphere.jl")
include("Grid/Orientation.jl")
# include("Grid/Plot2.jl")
# include("Grid/Plot2BBB.jl")
# include("Grid/PlotFaceGrid.jl")
# include("Grid/PlotFaceKiteGrid.jl")
# include("Grid/PolygonGrid.jl")
# include("Grid/PolygonToGrid.jl")
include("Grid/Renumbering.jl")
# include("Grid/SingleHexagonGrid.jl")
include("Grid/Topo.jl")
# include("Grid/Topo2.jl")
include("Grid/TransCart.jl")
include("Grid/TransSphere.jl")
# include("Grid/TriGrid.jl")
# include("Grid/cart2Radial.jl")
include("Grid/cart2sphere.jl")
include("Grid/hS.jl")
# include("Grid/sphere2cart.jl")
include("Grid/vtkWriteHex.jl")
# include("Grid/vtkWriteQuad.jl")

include("DG/DLagrange.jl")
# include("DG/DerivativeMatrix.jl")
include("DG/DerivativeMatrixSingle.jl")
# include("DG/GaussLegendreQuad.jl")
include("DG/GaussLobattoQuad.jl")
# include("DG/GetQuadMeth.jl")
# include("DG/GradGrad.jl")
# include("DG/InitMethodDG.jl")
include("DG/Lagrange.jl")
include("DyCore/Average.jl")
include("DyCore/AverageFB.jl")
# include("DyCore/BoundaryW.jl")
# include("DyCore/BoundaryWOutput.jl")
# include("DyCore/DampingKoeff.jl")
include("DyCore/Discretization.jl")
# include("DyCore/Energy.jl")
# include("DyCore/FCurlNon3Vec.jl")
# include("DyCore/FDiv3UpwindVec.jl")
# include("DyCore/FDiv3Vec.jl")
# include("DyCore/FDivGrad2Vec.jl")
# include("DyCore/FDivGrad2VecDSS.jl")
# include("DyCore/FDivRhoGrad2Vec.jl")
# include("DyCore/FGrad3Vec.jl")
# include("DyCore/FGradDiv2Vec.jl")
# include("DyCore/FGradDiv2VecDSS.jl")
# include("DyCore/FRotCurl2Vec.jl")
# include("DyCore/FRotCurl2VecDSS.jl")
# include("DyCore/FVort2VecDSS.jl")
# include("DyCore/FcnDiff.jl")
# include("DyCore/FcnNHCurlVec.jl")
# include("DyCore/FcnVec.jl")
# include("DyCore/HyperDiffusionVec.jl")
# include("DyCore/Jac.jl")
# include("DyCore/JacSchur.jl")
include("DyCore/MassCG.jl")
include("DyCore/NumberingFemCG.jl")
# include("DyCore/PlotCG.jl")
# include("DyCore/PlotDG.jl")
include("DyCore/Project.jl")
include("DyCore/ProjectVec.jl")
# include("DyCore/Source.jl")
# include("DyCore/SphereGrid.jl")
# include("DyCore/simpson.jl")
include("DyCore/vtkCG.jl")
include("DyCore/vtkCGGrid.jl")
include("DyCore/vtkOutput.jl")
# include("IntegrationMethods/JacVec.jl")
# include("IntegrationMethods/MethodRKIMEX.jl")
# include("IntegrationMethods/MethodRos.jl")
# include("IntegrationMethods/Rosenbrock.jl")
# include("IntegrationMethods/RosenbrockMethod.jl")
# include("IntegrationMethods/RosenbrockSchur.jl")
# include("IntegrationMethods/RosenbrockSchur1.jl")
# include("IntegrationMethods/RungeKuttaExplicit.jl")
# include("IntegrationMethods/RungeKuttaHEVI.jl")
# include("IntegrationMethods/RungeKuttaMethod.jl")
# include("IntegrationMethods/SchurSolve.jl")
# include("Model/EnergyToPot.jl")
# include("Model/EtaFromZ.jl")
# include("Model/PhiBaroWave.jl")
include("Model/PhysParameters.jl")
# include("Model/PotToEnergy.jl")
# include("Model/Pres.jl")
include("Model/Pressure.jl")
# include("Model/SymJac.jl")
# include("Model/TBaroWave.jl")
# include("Model/TFromThetaRho.jl")
# include("Model/dPresdTh.jl")
include("Model/fRho.jl")
include("Model/fRhoBGrd.jl")
include("Model/fT.jl")
include("Model/fTBGrd.jl")
include("Model/fTheta.jl")
include("Model/fThetaBGrd.jl")
# include("Model/fTr.jl")
include("Model/fVel.jl")
# include("Model/fVelW.jl")
include("Model/fpBGrd.jl")
# include("Model/pFromTheta.jl")


end # module