module FluorophoreColors

using Compat   # for Compat.@constprop

using Reexport
@reexport using FixedPointNumbers
@reexport using ColorTypes
using Colors
using ColorVectorSpace
using Requires

export fluorophore_rgb, @fluorophore_rgb_str, ColorMixture

include("types.jl")
include("fluorophores.jl")

function __init__()
    @require StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a" include("structarrays.jl")
end

end
