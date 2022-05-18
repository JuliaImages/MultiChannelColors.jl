"""
    AbstractMultiChannelColor{T<:Number,N}

An abstract type for multichannel/multiband/hyperspectral colors. Concrete derived types should have
a field, `channels`, which is a `NTuple{N,T}`. The channels can be returned with `Tuple(c::AbstractMultiChannelColor)`.
"""
abstract type AbstractMultiChannelColor{T<:Number,N} <: Color{T,N} end

ColorTypes.comp1(c::AbstractMultiChannelColor) = c.channels[1]
ColorTypes.comp2(c::AbstractMultiChannelColor) = c.channels[2]
ColorTypes.comp3(c::AbstractMultiChannelColor) = c.channels[3]
ColorTypes.comp4(c::AbstractMultiChannelColor) = c.channels[4]
ColorTypes.comp5(c::AbstractMultiChannelColor) = c.channels[5]

Base.Tuple(c::AbstractMultiChannelColor) = c.channels

Base.zero(::Type{C}) where C <: AbstractMultiChannelColor{T,N} where {T<:Number,N} = C(ntuple(i->zero(T), N))

function Base.show(io::IO, c::AbstractMultiChannelColor)
    print(io, '(')
    chans = Tuple(c)
    for (j, intensity) in enumerate(chans)
        j > 1 && print(io, ", ")
        print(io, intensity)
        print_subscript(io, length(chans), j)
    end
    print(io, ')')
end

"""
    MultiChannelColor(i₁, i₂, ...)
    MultiChannelColor((i₁, i₂, ...))
    MultiChannelColor{T}(...)                # coerce to element type T

Represent multichannel "raw" colors, which lack `convert` methods to standard color spaces.
If `c` is a `MultiChannelColor` object, then `Tuple(c)` is a tuple of intensities (one per channel).

[`ColorMixture`](@ref) is an alternative with a built-in conversion to RGB.
"""
struct MultiChannelColor{T<:Number,N} <: AbstractMultiChannelColor{T,N}
    channels::NTuple{N,T}
end

MultiChannelColor{T,N}(channels::Vararg{Number,N}) where {T<:Number,N} = MultiChannelColor{T,N}(channels)
MultiChannelColor{T,N}(c::MultiChannelColor{S,N}) where {T<:Number,N,S<:Number} = MultiChannelColor{T,N}(Tuple(c))

MultiChannelColor{T}(channels::NTuple{N,Number}) where {T<:Number,N} = MultiChannelColor{T,N}(channels)
MultiChannelColor{T}(channels::Vararg{Number,N}) where {T<:Number,N} = MultiChannelColor{T}(channels)

(MultiChannelColor{S,N} where S)(channels::NTuple{N,T}) where {T<:Number,N} = MultiChannelColor{T,N}(channels)
(MultiChannelColor{S,N} where S)(channels::Vararg{T,N}) where {T<:Number,N} = MultiChannelColor{T,N}(channels)
(MultiChannelColor{S,N} where S)(channels::NTuple{N,Number}) where N = (MultiChannelColor{R,N} where R)(promote(channels...))
(MultiChannelColor{S,N} where S)(channels::Vararg{Number,N}) where N = (MultiChannelColor{R,N} where R)(promote(channels...))

MultiChannelColor(channels::NTuple{N,Number}) where {N} = MultiChannelColor(promote(channels...))
MultiChannelColor(channels::Vararg{Number,N}) where {N} = MultiChannelColor(channels)

ColorTypes.base_colorant_type(::Type{MultiChannelColor{S,N}}) where {S<:Number,N} = MultiChannelColor{R,N} where R

Base.convert(::Type{MultiChannelColor{T}}, c::AbstractMultiChannelColor{S}) where {T<:Number,S<:Number} = MultiChannelColor{T}(Tuple(c))
Base.convert(::Type{MultiChannelColor{T,N}}, c::AbstractMultiChannelColor{S,N}) where {T<:Number,N,S<:Number} = MultiChannelColor{T,N}(Tuple(c))

"""
    ColorMixture((rgb₁, rgb₂, ...), (i₁, i₂, ...))
    ColorMixture((rgb₁, rgb₂, ...), i₁, i₂, ...)
    ColorMixture{T}(...)                       # coerce intensities to element type

Represent a multichannel color with a defined conversion to RGB. `rgbⱼ` is an RGB color corresponding
to channel `j`, and its intensity is `iⱼ`. Colors are converted to RGB, `convert(RGB, c)`, using intensity-weighting:
`rgb = sum(ivalues .* rgbvalues)`.

[`MultiChannelColor`](@ref) is an alternative that does not require an `rgb` list and has no built-in conversion to RGB.
"""
struct ColorMixture{T<:Number,N,Cs} <: AbstractMultiChannelColor{T,N}
    channels::NTuple{N,T}

    Compat.@constprop :aggressive function ColorMixture{T,N,Cs}(channels::NTuple{N}) where {T,N,Cs}
        Cs isa NTuple{N,RGB{N0f8}} || throw(TypeError(:ColorMixture, "", NTuple{N,RGB{N0f8}}, Cs))
        return new{T,N,Cs}(channels)
    end
end

ColorMixture{T,N,Cs}(channels::Vararg{Number,N}) where {T,N,Cs} = ColorMixture{T,N,Cs}(channels)
ColorMixture{T,N,Cs}(c::ColorMixture{S,N}) where {T,N,Cs,S} = ColorMixture{T,N,Cs}(Tuple(c))

(ColorMixture{T,N,Cs} where T)(channels::NTuple{N,S}) where {S<:Number,N,Cs} = ColorMixture{S,N,Cs}(channels)
(ColorMixture{T,N,Cs} where T)(channels::Vararg{S,N}) where {S<:Number,N,Cs} = ColorMixture{S,N,Cs}(channels)
(ColorMixture{T,N,Cs} where T)(channels::NTuple{N,Number}) where {N,Cs} = (ColorMixture{R,N,Cs} where R)(promote(channels...))
(ColorMixture{T,N,Cs} where T)(channels::Vararg{Number,N}) where {N,Cs} = (ColorMixture{R,N,Cs} where R)(promote(channels...))

Compat.@constprop :aggressive ColorMixture{T}(Cs::NTuple{N,RGB{N0f8}}, channels::NTuple{N,Number}) where {T,N} = ColorMixture{T,N,Cs}(channels)
Compat.@constprop :aggressive ColorMixture{T}(Cs::NTuple{N,AbstractRGB}, channels::NTuple{N,Number}) where {T,N} = ColorMixture{T,N,RGB{N0f8}.(Cs)}(channels)
Compat.@constprop :aggressive ColorMixture{T}(Cs::NTuple{N,AbstractRGB}, channels::Vararg{Number,N}) where {T,N} = ColorMixture{T}(Cs, channels)

Compat.@constprop :aggressive ColorMixture(Cs::NTuple{N,AbstractRGB}, channels::NTuple{N,Integer}) where {N} = ColorMixture{N0f8}(Cs, channels)
Compat.@constprop :aggressive ColorMixture(Cs::NTuple{N,AbstractRGB}, channels::NTuple{N,Number}) where {N} = ColorMixture{eltype(map(z -> zero(N0f8)*z, channels))}(Cs, channels)
Compat.@constprop :aggressive ColorMixture(Cs::NTuple{N,AbstractRGB}, channels::Vararg{Number,N}) where {N} = ColorMixture(Cs, channels)

"""
    ctemplate = ColorMixture((rgb₁, rgb₂))        # create an all-zeros ColorMixture with N0f8 channel intensities
    ctemplate = ColorMixture{T}((rgb₁, rgb₂))     # same, but specify the element type
    c = ctemplate((i₁, i₂))                       # Construct non-zero ColorMixture of the same type as `ctemplate`

Create a ColorMixture "template" `ctemplate` from which other non-zero colors `c` may be created.

`ctemplate((i...,))` is a constructor form that is performance-favorable, if the type of `ctemplate`
is known. In conjunction with a [function barrier](https://docs.julialang.org/en/v1/manual/performance-tips/#kernel-functions),
this form can be used to circumvent performance problems due to poor inferrability.
"""
ColorMixture{T}(Cs::NTuple{N,AbstractRGB}) where {T<:Number,N} = ColorMixture{T}(Cs, ntuple(_ -> zero(T), N))
ColorMixture(Cs::NTuple{N,RGB{N0f8}}) where {N} = ColorMixture{N0f8}(Cs)

(::ColorMixture{T,N,Cs})(channels::NTuple{N,Number}) where {T,N,Cs} = ColorMixture{T,N,Cs}(channels)
(::ColorMixture{T,N,Cs})(channels::Vararg{Number,N}) where {T,N,Cs} = ColorMixture{T,N,Cs}(channels)

ColorTypes.base_colorant_type(::Type{ColorMixture{S,N,Cs}}) where {S<:Number,N,Cs} = ColorMixture{T,N,Cs} where T

Base.convert(::Type{ColorMixture{T,N,Cs}}, c::AbstractMultiChannelColor{S,N}) where {T<:Number,N,Cs,S<:Number} = ColorMixture{T,N,Cs}(Tuple(c))

# These definitions use floats to avoid overflow
function Base.convert(::Type{RGB{T}}, c::ColorMixture{R,N,Cs}) where {T,R<:Number,N,Cs}
    convert(RGB{T}, sum(map((w, rgb) -> convert(RGB{floattype(T)}, w*rgb), c.channels, Cs)))
end
Base.convert(::Type{RGB}, c::ColorMixture{T}) where T<:Number = convert(RGB{T}, c)
Base.convert(::Type{RGB24}, c::ColorMixture) = convert(RGB24, convert(RGB, c))

ColorTypes._comp(::Val{N}, c::ColorMixture) where N = c.channels[N]
Compat.@constprop :aggressive ColorTypes.mapc(f, c::ColorMixture{T,N,Cs}) where {T<:Number,N,Cs} = ColorMixture(Cs, map(f, c.channels))
Compat.@constprop :aggressive ColorTypes.mapreducec(f, op, v0, c::ColorMixture{T,N,Cs}) where {T<:Number,N,Cs} = mapreduce(f, op, c.channels; init=v0)
Compat.@constprop :aggressive ColorTypes.reducec(op, v0, c::ColorMixture{T,N,Cs}) where {T<:Number,N,Cs} = reduce(op, c.channels; init=v0)

Base.:(==)(a::ColorMixture{Ta,N,Cs}, b::ColorMixture{Tb,N,Cs}) where {Ta<:Number,Tb<:Number,N,Cs} = a.channels == b.channels
Base.:(==)(a::ColorMixture, b::ColorMixture) = false

Base.isequal(a::ColorMixture{Ta,N,Cs}, b::ColorMixture{Tb,N,Cs}) where {Ta<:Number,Tb<:Number,N,Cs} = isequal(a.channels, b.channels)
Base.isequal(a::ColorMixture, b::ColorMixture) = false

# Default mappings

"""
    GreenMagenta{T}(intensities)
    GreenMagenta(intensities)

Construct a [`ColorMixture`](@ref) with the specified intensities that colorizes the first channel with green and the second with magenta.
"""
const GreenMagenta{T} = ColorMixture{T,2,(RGB(0,1,0), RGB(1,0,1))}
"""
    MagentaGreen{T}(intensities)
    MagentaGreen(intensities)

Construct a [`ColorMixture`](@ref) with the specified intensities that colorizes the first channel with magenta and the second with green.
"""
const MagentaGreen{T} = ColorMixture{T,2,(RGB(1,0,1), RGB(0,1,0))}
