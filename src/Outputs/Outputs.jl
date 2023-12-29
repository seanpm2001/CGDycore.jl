module Outputs

import ..DG
import ..Grids
import ..Thermodynamics

using WriteVTK
using KernelAbstractions
using KernelAbstractions: @atomic, @atomicswap, @atomicreplace

include("vtkCG.jl")	
include("vtkCGGrid.jl")	
include("vtkSphere.jl")
include("vtkOutputKernel.jl")

end
