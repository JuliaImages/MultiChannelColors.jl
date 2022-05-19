@inline ColorVectorSpace._mapc(::Type{C}, f, c) where {C<:AbstractMultiChannelColor} = C(f.(Tuple(c))...)
@inline ColorVectorSpace._mapc(::Type{C}, f, a, b) where {C<:AbstractMultiChannelColor} = C(f.(Tuple(a), Tuple(b))...)

## Generic algorithms
Base.add_sum(c1::AbstractMultiChannelColor,c2::AbstractMultiChannelColor) = mapc(Base.add_sum, c1, c2)
Base.add_sum(c1::AbstractMultiChannelColor{Bool}, c2::AbstractMultiChannelColor{Bool}) = mapc((x1, x2) -> FixedPointNumbers.Treduce(x1) + FixedPointNumbers.Treduce(x2), c1, c2)
Base.reduce_first(::typeof(Base.add_sum), c::AbstractMultiChannelColor) = mapc(x->Base.reduce_first(Base.add_sum, x), c)
Base.reduce_first(::typeof(Base.add_sum), c::AbstractMultiChannelColor{Bool}) = mapc(x->Base.reduce_first(Base.add_sum, N0f8(x)), c)
function Base.reduce_empty(::typeof(Base.add_sum), ::Type{C}) where C<:AbstractMultiChannelColor{T} where {T}
    z = Base.reduce_empty(Base.add_sum, T)
    return zero(base_colorant_type(C){typeof(z)})
end
Base.reduce_empty(::typeof(Base.add_sum), ::Type{C}) where C<:AbstractMultiChannelColor{Bool} =
    Base.reduce_empty(Base.add_sum, base_colorant_type(C){N0f8})

# Common
Base.copy(c::AbstractMultiChannelColor) = c
(*)(f::Real, c::AbstractMultiChannelColor) = _mapc(rettype(*, f, c), v -> _mul(f, v), c)
(*)(c::AbstractMultiChannelColor, f::Real) = (*)(f, c)
(/)(c::AbstractMultiChannelColor, f::Real) = _mapc(rettype(/, c, f), v -> _div(v, f), c)
(+)(c::AbstractMultiChannelColor) = mapc(+, c)
(+)(c::AbstractMultiChannelColor{Bool}) = c
(-)(c::AbstractMultiChannelColor) = mapc(-, c)
Base.abs(c::AbstractMultiChannelColor) = mapc(abs, c)
LinearAlgebra.norm(c::AbstractMultiChannelColor, p::Real=2) = norm(Tuple(c), p)
Base.abs2(c::AbstractMultiChannelColor) = mapreducec(v->v^2, +, zero(acctype(eltype(c))), c)

(+)(a::C, b::C) where {C<:AbstractMultiChannelColor} = _mapc(rettype(+, a, b), +, a, b)
(-)(a::C, b::C) where {C<:AbstractMultiChannelColor} = _mapc(rettype(-, a, b), -, a, b)
(⊙)(a::C, b::C) where {C<:AbstractMultiChannelColor} = _mapc(rettype(*, a, b), _mul, a, b)
(⋅)(a::C, b::C) where {C<:AbstractMultiChannelColor} = reduce(+, Tuple(a) .* Tuple(b); init=zero(acctype(eltype(C))))

## Mixed types
(+)(a::AbstractMultiChannelColor, b::AbstractMultiChannelColor) = (+)(promote(a, b)...)
(-)(a::AbstractMultiChannelColor, b::AbstractMultiChannelColor) = (-)(promote(a, b)...)
(⊙)(a::AbstractMultiChannelColor, b::AbstractMultiChannelColor) = (⊙)(promote(a, b)...)
(⋅)(a::AbstractMultiChannelColor, b::AbstractMultiChannelColor) = (⋅)(promote(a, b)...) # not fully supported, but used for error hints

(⊙)(a::C, b::NTuple{N,Number}) where {C<:AbstractMultiChannelColor{<:Real,N}} where N = base_color_type(C)(Tuple(a) .* b)
(⊙)(a::NTuple{N,Number}, b::C) where {C<:AbstractMultiChannelColor{<:Real,N}} where N = base_color_type(C)(a .* Tuple(b))
