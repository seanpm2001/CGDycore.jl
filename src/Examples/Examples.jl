module Examples

import ..Grids
import ..Thermodynamics


function InitialProfile!(Model,Problem,Param,Phys)
  # Initial values
  if Problem == "Galewski"
    Profile = Examples.GalewskiExample()(Param,Phys)
    Model.InitialProfile = Profile
  elseif Problem == "BaroWaveDrySphere" || Problem == "BaroWaveHillDrySphere"
    Profile = Examples.BaroWaveExample()(Param,Phys)
    Model.InitialProfile = Profile
  elseif Problem == "SchaerSphericalSphere"
    Profile = Examples.SchaerSphereExample()(Param,Phys)
    Model.InitialProfile = Profile
  elseif Problem == "HeldSuarezDrySphere"
    Profile, Force = Examples.HeldSuarezDryExample()(Param,Phys)
    Model.InitialProfile = Profile
    Model.Force = Force
  elseif Problem == "HeldSuarezMoistSphere"
    Profile, Force, Eddy = Examples.HeldSuarezMoistExample()(Param,Phys)
    Model.InitialProfile = Profile
    Model.Force = Force
    Model.Eddy = Eddy
  elseif Problem == "Stratified" || Problem == "HillAgnesiXCart"
    Profile = Examples.StratifiedExample()(Param,Phys)
    Model.InitialProfile = Profile
    @show "Stratified"
  elseif Problem == "WarmBubble2DXCart"
    Profile = Examples.WarmBubbleCartExample()(Param,Phys)
    Model.InitialProfile = Profile
  elseif Problem == "BryanFritschCart"
    ProfileBF = Models.TestRes(Phys)
    Profile = Examples.BryanFritsch(ProfileBF)(Param,Phys)
    Model.InitialProfile = Profile
  end
end

include("parameters.jl")
include("initial.jl")
include("force.jl")
include("topography.jl")
include("PerturbProfile.jl")

end
