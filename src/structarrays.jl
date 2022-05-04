function StructArrays.staticschema(::Type{ColorMixture{T,N,Cs}}) where {T, N, Cs}
    # Define the desired names and eltypes of the "fields"
    names = ntuple(i -> Symbol("channel" * lpad(i, N-ndigits(i), '0')), N)
    types = Tuple{ntuple(i -> T, N)...}
    return NamedTuple{names, types}
end

@noinline throw_channelerror(key::Symbol) = error("channel $key not available")
StructArrays.component(c::ColorMixture{T,1}, key::Symbol) where T = key == :channel1 ? c.channels[1] : throw_channelerror(key)
StructArrays.component(c::ColorMixture{T,2}, key::Symbol) where T = key == :channel1 ? c.channels[1] :
                                                                    key == :channel2 ? c.channels[2] : throw_channelerror(key)
StructArrays.component(c::ColorMixture{T,3}, key::Symbol) where T = key == :channel1 ? c.channels[1] :
                                                                    key == :channel2 ? c.channels[2] :
                                                                    key == :channel3 ? c.channels[3] : throw_channelerror(key)

# function StructArrays.component(m::ColorMixture{T,N}, key::Symbol) where {T,N}
#     # Define the component-extractor
#     return key === :data ? getfield(m, 1) : getfield(getfield(m, 2), key)
# end

function StructArrays.createinstance(::Type{ColorMixture{T,N,Cs}}, args...) where {T, N, Cs}
    return ColorMixture{T,N,Cs}(args)
end
