module FluorophoreColors

# For custom colortypes, the main things we need are
# - utitlies for extracting channels
# - conversion to RGB for display
# Consequently the main representation is by emission wavelength.

const subscript = ('₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉')

"""
    EmissionPeaks{T,(λ₁, λ₂, ...)}(i₁, i₂, ...)    # coerce iⱼ to a particular chosen T
    EmissionPeaks{(λ₁, λ₂, ...)}(i₁, i₂, ...)      # selects T automatically from the iⱼs

Represent the multichannel fluorescence intensity at a point. `λⱼ` are the emission peak
wavelengths (in nanometers) of the fluorophores, and should be represented as a tuple of
`Float32` values. `iⱼ` is the intensity of each fluorophore. `T` is the element type used
to express the intensities, and should typically be on a 0-to-1 scale.

# Examples

To construct a 16-bit "pixel" from a EGFP (peak emission 507nm)/tdTomato (peak emission 581nm) image,
you might do the following:

```
julia> c = EmissionPeaks{(507f0,581f0)}(#= GFP intensity =# 0.2, #= tdTomato intensity =# 0.85)
```
"""
struct EmissionPeaks{T,W<:NTuple{N,Float32}} <: Color{T,N}
    channels::NTuple{N,T}
end
EmissionPeaks{W}(intensities::Vararg{T,N}) where W<:NTuple{N,Float32} where {T,N} =
    EmissionPeaks{T,W}(intensities...)
EmissionPeaks{W}(intensities::Vararg{Real,N}) where W<:NTuple{N,Float32} where {N} =
    EmissionPeaks{W}(promote(intensities...)...)

function Base.show(io::IO, c::EmissionPeaks)
    print(io, '(')
    isfirst = true
    for (j, intensity) in c.channels
        if isfirst
            isfirst = false
        else
            print(io, ", ")
        end
        print(io, intensity, subscript[j])
    end
end

"""
    Wavelength{λ}()

An "extractor" for retrieving the intensity of a particular wavelength from an `c::EmissionPeaks` color.

# Examples

```
julia> c = EmissionPeaks{(507.0f0,)}
```
"""
struct Wavelength{W<:Float32}
end
Wavelength(λ::Real) = Wavelength{Float32(λ)}()

end
