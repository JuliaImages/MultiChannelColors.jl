module MultiChannelColors

using Compat

using Reexport
@reexport using FixedPointNumbers
@reexport using ColorTypes
using Colors
using ColorVectorSpace

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

@static if !isdefined(Base, :get_extension)
    using Requires
end

function __init__()
    @static if !isdefined(Base, :get_extension)
        @require StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a" include("../ext/StructArraysExt.jl")
        @require ImageCore = "a09fc81d-aa75-5fe9-8630-4744c3626534" include("../ext/ImageCoreExt.jl")
    end
end

end
