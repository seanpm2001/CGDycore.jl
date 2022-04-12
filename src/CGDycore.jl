module CGDycore


#=
Look for

# TODO: check translation with Oswald
=#

using LinearAlgebra
using SparseArrays
#include("matlab_intrinsics.jl")

include("Grid/Node.jl")
include("Grid/Edge.jl")
include("Grid/Face.jl")
include("Grid/GridStruct.jl")
include("Grid/AddVerticalGrid.jl")
include("Grid/CartGrid.jl")
include("Grid/CubedGrid.jl")
include("Grid/FacesInNodes.jl")
include("Grid/JacobiDG3.jl")
include("Grid/JacobiSphere3.jl")
include("Grid/OrientFaceCart.jl")
include("Grid/OrientFaceSphere.jl")
include("Grid/Orientation.jl")
include("Grid/Renumbering.jl")
include("Grid/Topo.jl")
include("Grid/TransCart.jl")
include("Grid/TransSphere.jl")
include("Grid/cart2sphere.jl")
include("Grid/hS.jl")
include("Grid/sphere2cart.jl")
include("Grid/vtkWriteHex.jl")

include("DG/DLagrange.jl")
include("DG/DerivativeMatrixSingle.jl")
include("DG/GaussLobattoQuad.jl")
include("DG/Lagrange.jl")

include("DyCore/Average.jl")
include("DyCore/AverageFB.jl")
include("DyCore/BoundaryW.jl")
include("DyCore/BoundaryWOutput.jl")
include("DyCore/DampingKoeff.jl")
include("DyCore/Discretization.jl")
# include("DyCore/Energy.jl")
include("DyCore/FCurlNon3Vec.jl")
include("DyCore/FDiv3Vec.jl")
include("DyCore/FDivGrad2VecDSS.jl")
include("DyCore/FDivRhoGrad2Vec.jl")
include("DyCore/FGrad3Vec.jl")
include("DyCore/FGradDiv2Vec.jl")
include("DyCore/FGradDiv2VecDSS.jl")
include("DyCore/FRotCurl2Vec.jl")
include("DyCore/FRotCurl2VecDSS.jl")
include("DyCore/FVort2VecDSS.jl")
include("DyCore/FcnNHCurlVec.jl")
# include("DyCore/HyperDiffusionVec.jl")
include("DyCore/JacSchur.jl")
include("DyCore/MassCG.jl")
include("DyCore/NumberingFemCG.jl")
include("DyCore/Project.jl")
include("DyCore/ProjectW.jl")
include("DyCore/ProjectVec.jl")
include("DyCore/Source.jl")
include("DyCore/simpson.jl")
include("DyCore/vtkCG.jl")
include("DyCore/vtkCGGrid.jl")
include("DyCore/vtkOutput.jl")

include("IntegrationMethods/RosenbrockMethod.jl")
include("IntegrationMethods/RosenbrockSchur.jl")
include("IntegrationMethods/RungeKuttaExplicit.jl")
include("IntegrationMethods/RungeKuttaMethod.jl")
include("IntegrationMethods/SchurSolve.jl")
include("IntegrationMethods/JacStruc.jl")

include("Model/PhysParameters.jl")
include("Model/Pressure.jl")
include("Model/dPresdTh.jl")
include("Model/fRho.jl")
include("Model/fRhoBGrd.jl")
include("Model/fT.jl")
include("Model/fTBGrd.jl")
include("Model/fTheta.jl")
include("Model/fThetaBGrd.jl")
include("Model/fVel.jl")
include("Model/fVelW.jl")
include("Model/fpBGrd.jl")

end
