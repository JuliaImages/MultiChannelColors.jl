module MultiChannelColors

using Compat

using Reexport
@reexport using FixedPointNumbers
@reexport using ColorTypes
using Colors
using ColorVectorSpace
using Requires

using ColorVectorSpace: _mapc, _mul, _div, rettype, acctype

import Base: ==, +, -, *, /
import LinearAlgebra: LinearAlgebra, ⋅
import ColorVectorSpace.TensorCore: ⊙

export AbstractMultiChannelColor, MultiChannelColor, ColorMixture, GreenMagenta, MagentaGreen
export fluorophore_rgb, @fluorophore_rgb_str
export ⋅, ⊙

include("types.jl")
include("fluorophores.jl")
include("utils.jl")
include("operations.jl")

function __init__()
    @require StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a" include("structarrays.jl")
    @require ImageCore = "a09fc81d-aa75-5fe9-8630-4744c3626534" include("imagecore.jl")
end

end
