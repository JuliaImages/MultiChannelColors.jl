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

## Overflow protection

Depending on the colors you pick for conversion to RGB (e.g., `channels`), it is possible to exceed the 0-to-1 bounds of RGB.
With the choice above,

```julia
julia> c = ctemplate(0.99, 0.99)
(0.99001N0f16₁, 0.99001N0f16₂)

julia> convert(RGB, c)
ERROR: ArgumentError: component type N0f16 is a 16-bit type representing 65536 values from 0.0 to 1.0,
  but the values (0.9900053f0, 1.7664759f0, 0.36105898f0) do not lie within this range.
  See the READMEs for FixedPointNumbers and ColorTypes for more information.
Stacktrace:
[...]
```

If you want to guard against such errors, one good choice would be

```julia
julia> convert(RGB{Float32}, c)
RGB{Float32}(0.9900053, 1.7664759, 0.36105898)
```

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

## Why are the RGB colors encoded in the *type*? Why not a value field?

In many places, JuliaImages assumes that you can convert from one color space to another purely from knowing the type you want to convert to. This would not be possible if the RGB colors were encoded as a second field of the color.

## I wrote some code and got lousy performance. How can I fix it?

To achieve good performance, in some cases the RGB *values* must be aggressively constant-propagated, a feature available only on Julia 1.7 and higher. So if you're experiencing this problem on Julia 1.6, try a newer version.

In greater detail, the issue is that there are circumstances where inference might need to be able to anticipate a type change like `C1 -> C2`, where

```julia
julia> C1 = typeof(ColorMixture(channels))
ColorMixture{N0f8, 2, (RGB{N0f8}(0.0, 0.925, 0.365), RGB{N0f8}(1.0, 0.859, 0.0))}

julia> C2 = typeof(ColorMixture(float.(channels)))
ColorMixture{Float32, 2, (RGB{Float32}(0.0, 0.9254902, 0.3647059), RGB{Float32}(1.0, 0.85882354, 0.0))}
```

For a method that takes type `C1` as input and returns type `C2`, being able to infer the return type (including those numeric values) generally requires Julia 1.7 or higher.
A good workaround is to write code that returns `ColorMixture{T}` values with the same `T` as the inputs; see, for example, the definition of `clamp01` in this package.
