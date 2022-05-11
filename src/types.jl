# For custom colortypes, the main things we need are
# - utitlies for extracting channels
# - conversion to RGB for display
# Making the main representation by RGB means we can do the latter efficiently without requiring
# world-age violations.

"""
    ColorMixture((rgb₁, rgb₂), (i₁, i₂))          # store intensities
    ColorMixture{T}((rgb₁, rgb₂), (i₁, i₂))       # same, but coerce to element type T for colors and intensities

Represent the multichannel fluorescence intensity at a point. `rgbⱼ` is an RGB color corresponding
to fluorophore `j` (e.g., see [`fluorophore_rgb`](@ref)) whose emission intensity is `iⱼ`.

While the example shows two fluorophores, any number may be used, as long as the number of `rgb` colors
matches the number of intensities `i`.

If you're constructing such colors in a high-performance loop, there may be other methods that may
yield better performance due to challenges with type-inference, unless the color is known
at compile time.

# Examples

To construct a 16-bit "pixel" from a dual-channel EGFP (peak emission 507nm)/tdTomato (peak emission 581nm) image,
you might do the following:

```jldoctest
julia> using FluorophoreColors

julia> channelcolors = (fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"]);

julia> c = ColorMixture{N0f16}(channelcolors, #= GFP intensity =# 0.2, #= tdTomato intensity =# 0.85)
(0.2N0f16₁, 0.85N0f16₂)

julia> convert(RGB, c)
RGB{N0f16}(0.85, 0.9151, 0.07294)
```

If you must construct colors inferrably inside a function body, use

```jldoctest; setup=:(using FluorophoreColors)
julia> channelcolors = (fluorophore_rgb"EGFP", fluorophore_rgb"tdTomato");

julia> c = ColorMixture{N0f8}(channelcolors, #= GFP intensity =# 0.2, #= tdTomato intensity =# 0.85)
(0.2N0f8₁, 0.851N0f8₂)
```

This allows the RGB *values* to be visible to the compiler. However, the fluorophore names must be hard-coded,
and you must preserve the `N0f8` element type of fluorophore_rgb"NAME".
"""
struct ColorMixture{T,N,Cs} <: Color{T,N}
    channels::NTuple{N,T}

    Compat.@constprop :aggressive function ColorMixture{T,N,Cs}(channels::NTuple{N}) where {T,N,Cs}
        Cs isa NTuple{N,RGB{N0f8}} || throw(TypeError(:ColorMixture, "", NTuple{N,RGB{N0f8}}, Cs))
        return new{T,N,Cs}(channels)
    end
end
ColorMixture{T,N,Cs}(channels::Vararg{Real,N}) where {T,N,Cs} = ColorMixture{T,N,Cs}(channels)
Compat.@constprop :aggressive ColorMixture{T}(Cs::NTuple{N,RGB{N0f8}}, channels::NTuple{N,Real}) where {T,N} = ColorMixture{T,N,Cs}(channels)
Compat.@constprop :aggressive ColorMixture{T}(Cs::NTuple{N,AbstractRGB}, channels::NTuple{N,Real}) where {T,N} = ColorMixture{T,N,RGB{N0f8}.(Cs)}(channels)
Compat.@constprop :aggressive ColorMixture{T}(Cs::NTuple{N,AbstractRGB}, channels::Vararg{Real,N}) where {T,N} = ColorMixture{T}(Cs, channels)

Compat.@constprop :aggressive ColorMixture(Cs::NTuple{N,AbstractRGB}, channels::NTuple{N,Real}) where {N} = ColorMixture{eltype(map(z -> zero(N0f8)*z, channels))}(Cs, channels)
Compat.@constprop :aggressive ColorMixture(Cs::NTuple{N,AbstractRGB}, channels::Vararg{Real,N}) where {N} = ColorMixture(Cs, channels)

"""
    cobj = ColorMixture((rgb₁, rgb₂))        # create an all-zeros ColorMixture with N0f8 channel intensities
    cobj = ColorMixture{T}((rgb₁, rgb₂))     # same, but specify the element type
    c = cobj((i₁, i₂))                       # Construct non-zero ColorMixture (inferrably)

Create a ColorMixture `c` from a "template" `cobj`. `c` will be the same type as `cobj`.

`cobj((i...,))` is a constructor form that is performance-favorable, if the type of `cobj`
is known. In conjunction with a [function barrier](https://docs.julialang.org/en/v1/manual/performance-tips/#kernel-functions),
this form can be used to circumvent performance problems due to poor inferrability.
"""
ColorMixture{T}(Cs::NTuple{N,AbstractRGB}) where {T,N} = ColorMixture{T}(Cs, ntuple(_ -> zero(T), N))
ColorMixture(Cs::NTuple{N,RGB{N0f8}}) where {N} = ColorMixture{N0f8}(Cs)

(::ColorMixture{T,N,Cs})(channels::NTuple{N,Real}) where {T,N,Cs} = ColorMixture{T,N,Cs}(channels)
(::ColorMixture{T,N,Cs})(channels::Vararg{Real,N}) where {T,N,Cs} = ColorMixture{T,N,Cs}(channels)


Base.:(==)(a::ColorMixture{Ta,N,Cs}, b::ColorMixture{Tb,N,Cs}) where {Ta,Tb,N,Cs} = a.channels == b.channels
Base.:(==)(a::ColorMixture, b::ColorMixture) = false

function Base.show(io::IO, c::ColorMixture)
    print(io, '(')
    for (j, intensity) in enumerate(c.channels)
        j > 1 && print(io, ", ")
        print(io, intensity)
        print_subscript(io, length(c), j)
    end
    print(io, ')')
end

# These definitions use floats to avoid overflow
function Base.convert(::Type{RGB{T}}, c::ColorMixture{T,N,Cs}) where {T,N,Cs}
    convert(RGB{T}, sum(map(*, c.channels, Cs); init=zero(RGB{floattype(T)})))
end
function Base.convert(::Type{RGB{T}}, c::ColorMixture{R,N,Cs}) where {T,R,N,Cs}
    convert(RGB{T}, sum(map((w, rgb) -> convert(RGB{floattype(T)}, w*rgb), c.channels, Cs)))
end
Base.convert(::Type{RGB}, c::ColorMixture{T}) where T = convert(RGB{T}, c)
Base.convert(::Type{RGB24}, c::ColorMixture) = convert(RGB24, convert(RGB, c))

ColorTypes._comp(::Val{N}, c::ColorMixture) where N = c.channels[N]
Compat.@constprop :aggressive ColorTypes.mapc(f, c::ColorMixture{T,N,Cs}) where {T,N,Cs} = ColorMixture(Cs, map(f, c.channels))
Compat.@constprop :aggressive ColorTypes.mapreducec(f, op, v0, c::ColorMixture{T,N,Cs}) where {T,N,Cs} = mapreduce(f, op, v0, c.channels)
Compat.@constprop :aggressive ColorTypes.reducec(op, v0, c::ColorMixture{T,N,Cs}) where {T,N,Cs} = reduce(op, c.channels; init=v0)
