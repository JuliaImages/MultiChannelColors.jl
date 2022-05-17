```@meta
CurrentModule = MultiChannelColors
```

# MultiChannelColors

[MultiChannelColors](https://github.com/JuliaImages/MultiChannelColors.jl) aims to support "unconventional colors," such as might arise in applications like multichannel fluorescence microscopy and hyperspectral imaging. Consistent with the philosophy of the [JuliaImages ecosystem](https://juliaimages.org/latest/), this package allows you to bundle together the different color channels into a "color object," and many color objects can be stored in an array. Having each entry of the array represent a complete pixel or voxel makes it much easier to write generic code supporting a wide range of image types.

## Installation

Install the package with `add MultiChannelColors` from the `pkg>` prompt, which you access by typing `]` from the `julia>` prompt. See the [Pkg documentation](https://pkgdocs.julialang.org/v1/getting-started/) for more information.

## Usage

Use the package interactively or in code with

```jldoctest demo
julia> using MultiChannelColors
```

In addition to giving access to specific types defined below, this will import the namespaces of [FixedPointNumbers](https://github.com/JuliaMath/FixedPointNumbers.jl) (which harmonizes the interpretation of "integer" and "floating-point" pixel-encodings) and [ColorTypes](https://github.com/JuliaGraphics/ColorTypes.jl) (which defines core color types and low-level manipulation). It will also define arithmetic for colors such as RGB (see [ColorVectorSpace](https://github.com/JuliaGraphics/ColorVectorSpace.jl)).

The color types in this package support two fundamental categories of operations:

- arithmetic operations such as `+` and `-` and multiplying or dividing by a scalar. You can also scale each color channel independently with `⊙` (obtained with `\odot<tab>`) or its synonym `hadamard`, e.g., `g ⊙ c` where `c` is a color object defined in this package and `g` is a tuple of real numbers (the "gains").
- extracting the independent channel intensities as a tuple with `Tuple(c)`.

When creating `c`, you have two choices which primarily affect visualization:

- to use ["bare" colors](@ref index_multichannelcolor) that store the multichannel data but lack any default conversion to other color spaces. This might be most appropriate if you have more than 3 channels, for which there may be many different ways to visualize the data they encode.
- to use [colors with built-in conversion to RGB](@ref index_colormixture), making them work automatically in standard visualization tools. This may be most appropriate when you have 3 or fewer channels.

Both options will be discussed below. See the [JuliaImages documentation on visualization](https://juliaimages.org/latest/install/#sec_visualization) for more information about tools for viewing images.

### ["Bare" colors: `MultiChannelColor`](@id index_multichannelcolor)

A `MultiChannelColor` object is essentially a glorified tuple, one that can be recognized as a [`Colorant`](https://github.com/JuliaGraphics/ColorTypes.jl#the-type-hierarchy-and-abstract-types) but with comparatively few automatic behaviors. For example, if you're working with [Landsat 8](https://en.wikipedia.org/wiki/Landsat_8) data with
[11 wavelength bands](https://landsat.gsfc.nasa.gov/satellites/landsat-8/landsat-8-bands/), one might create a pixel this way:

```jldoctest demo
julia> c = MultiChannelColor{N4f12}(0.2, 0.1, 0.2, 0.2, 0.25, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2)
(0.2N4f12₀₁, 0.1001N4f12₀₂, 0.2N4f12₀₃, 0.2N4f12₀₄, 0.2501N4f12₀₅, 0.2N4f12₀₆, 0.2N4f12₀₇, 0.2N4f12₀₈, 0.2N4f12₀₉, 0.2N4f12₁₀, 0.2N4f12₁₁)
```

See the [FixedPointNumbers](https://github.com/JuliaMath/FixedPointNumbers.jl) package for information about the 16-bit data type `N4f12` (Landsat 8 quantizes with 12 bits).

The usual way to visualize such an object is to define a custom function that converts such colors to more conventional colors (`RGB` or `Gray`). For example, we might compute the [Enhanced Vegetation Index](https://www.usgs.gov/landsat-missions/landsat-enhanced-vegetation-index)
and render positive values in green and negative values in magenta:

```jldoctest demo
julia> function evi(c::MultiChannelColor{T,11}) where T<:FixedPoint
           # Valid for Landsat 8 with 11 spectral bands
           b = Tuple(c)                      # extract the bands
           evi = 2.5f0 * (b[5] - b[4]) / (b[5] + 6*b[4] - 7.5f0*b[2] + eps(T))
           return evi > 0 ? RGB(0, evi, 0) : RGB(-evi, 0, -evi)
       end;

julia> evi(c)
RGB{Float32}(0.0f0,0.17894554f0,0.0f0)
```

If `img` is a whole image of such pixels, `evi.(img)` converts the entire array to RGB. For large data, you might prefer to use the [MappedArrays package](https://github.com/JuliaArrays/MappedArrays.jl) to do such conversions "lazily" (on an as-needed basis) to avoid exhausting computer memory:

```julia
julia> using MappedArrays

julia> imgrgb = mappedarray(evi, img);
```

### [RGB-convertible colors: `ColorMixture`](@id index_colormixture)

`ColorMixture` objects are like `MultiChannelColor` objects except they have a built-in conversion to RGB. Each channel gets assigned a specific RGB color, say `rgbⱼ` for the `j`th channel, along with an intensity `iⱼ`.
`rgbⱼ` is a feature of the *type* (shared by all objects of the same type) whereas `iⱼ` is a property of *objects*.

`ColorMixture` objects are converted to RGB with intensity-weighting,

``
c_{rgb} = \sum_j i_j \mathrm{rgb}_j
``

Depending on the the `rgbⱼ` and `iⱼ`, values may exceed the 0-to-1 colorscale of RGBs.
Conversion to `RGB{Float32}` may be safer than `RGB{T}` where `T` is limited to 0-to-1.
It is also faster, as the result does not have to be checked for whether it exceeds the bounds of the type.
(To prevent overflow, all internal operations are performed using floating-point intermediates even if you want a `FixedPoint` output.)

!!! note
    While `ColorMixture` objects can be converted to RGB, they are *not* AbstractRGB
    colors: `red(c)`, `green(c)`, and `blue(c)` are not defined for `c::ColorMixture`, and low-level utilities
    like `mapc` operate on the raw channel intensities rather than the RGB values.


There are several ways you can create these colors. An easy approach is to define the type through a "template" object:

```jldoctest demo
julia> ctemplate = ColorMixture{Float32}((RGB(0,1,0), RGB(1,0,0)))
(0.0₁, 0.0₂)
```

`ctemplate` is an all-zeros `ColorMixture` object, but can be used to construct arbitrary `c` with specified intensities:

```jldoctest demo
julia> typeof(ctemplate)
ColorMixture{Float32, 2, (RGB{N0f8}(0.0,1.0,0.0), RGB{N0f8}(1.0,0.0,0.0))}

julia> c = ctemplate(0.2, 0.4)
(0.2₁, 0.4₂)

julia> Tuple(c)
(0.2f0, 0.4f0)
```

You can also create them with a single call `ColorMixture(rgbs, intensities)`:

```jldoctest demo
julia> c = ColorMixture{Float32}((RGB(0,1,0), RGB(1,0,0)), (0.2, 0.4))
(0.2₁, 0.4₂)
```

or even by explicit type construction:

```jldoctest demo
julia> ColorMixture{Float32, 2, (RGB{N0f8}(0.0,1.0,0.0), RGB{N0f8}(1.0,0.0,0.0))}(0.2, 0.4)
(0.2₁, 0.4₂)
```

!!! tip
    All but the last form require [constant propagation](https://en.wikipedia.org/wiki/Constant_folding) for inferrability.
    Julia 1.7 and higher can use "aggressive" constant propagation to solve inference problems that may reduce performance on Julia 1.6.

### Importing external data

When objects are not created by code but instead loaded from an external source such as a file, you have several avenues for creating arrays of multichannel color objects. There are two particularly common cases:

1. If the imported data are an array `A` of size `(nc, m, n)`, where `nc` is the number of color channels (i.e., color is the fastest dimension), then use `reinterpret(reshape, C, A)` where `C` is the color type you want to use (e.g., `MultiChannelColor{T,nc}` or `ColorMixture{T,nc,rgbs}`). For instance, Landsat 8 data might look something like this:

   ```julia
   A = rand(0x0000:0x0fff, 11, 100, 100);
   img = reinterpret(reshape, MultiChannelColor{N4f12,11}, A);
   ```

2. If the imported data have the color channel last, or use separate arrays for each channel, use the [StructArrays package](https://github.com/JuliaArrays/StructArrays.jl). For example:

   ```julia
   A = rand(0x0000:0x0fff, 100, 100, 11);
   img = StructArray{MultiChannelColor{N4f12,11}}(A; dims=3)
   ```

It is possible that simpler syntaxes will be developed in future releases.

## Additional features

### Fluorophores

This package also exports a lookup table for common [fluorophores](https://en.wikipedia.org/wiki/Fluorophore). If desired, these can be used as the `rgbⱼ` values for `ColorMixture` channels. For example:

```jldoctest demo
julia> channels = (fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"])
(RGB{N0f8}(0.0,0.925,0.365), RGB{N0f8}(1.0,0.859,0.0))

julia> ctemplate = ColorMixture{N0f16}(channels)
(0.0N0f16₁, 0.0N0f16₂)
```

If you'll be hard-coding the name of the fluorophore, consider using a slightly different syntax:

```jldoctest demo
julia> channels = (fluorophore_rgb"EGFP", fluorophore_rgb"tdTomato")
(RGB{N0f8}(0.0,0.925,0.365), RGB{N0f8}(1.0,0.859,0.0))
```

Note the absence of `[]` brackets around the fluorophore names.  This form creates types inferrably, but the fluorophore name must be a literal string constant.

The RGB values are computed from the peak emission wavelength of each fluorophore; note, however, that the perceptual appearance is often more red-shifted due to the asymmetric shape of emission spectra.

### Green/magenta coloration

For good separability in two-color imaging, the `GreenMagenta{T}` and `MagentaGreen{T}` types are convenient:

```jldoctest demo
julia> c = GreenMagenta{N0f8}(0.2, 0.4)
(0.2N0f8₁, 0.4N0f8₂)

julia> convert(RGB, c)
RGB{N0f8}(0.4,0.2,0.4)
```

Green and magenta are distinguishable even by individuals with common forms of color blindness, and is thus a good default for two-color imaging.
