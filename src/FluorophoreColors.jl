module FluorophoreColors

using Compat   # for Compat.@constprop

using Reexport
@reexport using FixedPointNumbers
@reexport using ColorTypes
using Colors
using ColorVectorSpace

export fluorophore_rgb, @fluorophore_rgb_str, ColorMixture

include("types.jl")
include("fluorophores.jl")

end
