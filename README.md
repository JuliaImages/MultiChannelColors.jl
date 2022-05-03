# FluorophoreColors

[![Build Status](https://github.com/JuliaImages/FluorophoreColors.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaImages/FluorophoreColors.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaImages/FluorophoreColors.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaImages/FluorophoreColors.jl)

This package defines [color types](https://github.com/JuliaGraphics/ColorTypes.jl) for use with multichannel fluorescence imaging. Briefly, you can specify the intensity of each color channel plus an RGB value associated with the peak emission
wavelength of each fluorophore.

## Basic usage

Perhaps the easiest way to learn the package is by example. Suppose we are imaging two fluorophores, EGFP and tdTomato.

```julia
julia> using FluorophoreColors

julia> channels = (fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"])
(RGB{N0f8}(0.0,0.925,0.365), RGB{N0f8}(1.0,0.859,0.0))

julia> ctemplate = ColorMixture{N0f16}(channels)
(0.0N0f16₁, 0.0N0f16₂)
```

This creates an all-zero "template" color object. Note that we've specified the element type, `N0f16`, for 16-bit color depth.
The subscripts `₁` and `₂` are hints that this is not an ordinary tuple; each represents the intensity in the corresponding channel.

We use `ctemplate` to construct any other color:

```julia
julia> c = ctemplate(0.25, 0.75)
(0.25N0f16₁, 0.75N0f16₂)

julia> convert(RGB, c)
RGB{N0f16}(0.75,0.87549,0.09117)
```

The latter is how this color would be rendered in a viewer; embedded in a function, the conversion is extremely well optimized (~2.2ns on the author's machine).

## Advanced usage

`ctemplate` stores the RGB *values* for each fluorophore as a type-parameter. This allows efficient conversion to RGB
without running into world-age problems that might otherwise arise from auto-generated conversion methods.
However, constructing `ctemplate` as above is an inherently non-inferrable operation. If you want to construct such colors
inferrably, you can use the macro version:

```julia
f(i1, i2) = ColorMixture{N0f8}((fluorophore_rgb"EGFP", fluorophore_rgb"tdTomato"), (i1, i2))
```

Note the absence of `[]` brackets around the fluorophore names. For such constructors, `N0f8` is the only option if you're
looking up the RGB values with `fluorophore_rgb`; however, if you hard-code the RGB values there is no restriction
on the element type.
