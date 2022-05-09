channelname(N::Int, i::Int) = Symbol("channel" * lpad(string(i), ndigits(N), '0'))

function StructArrays.staticschema(::Type{ColorMixture{T,N,Cs}}) where {T, N, Cs}
    # Define the desired names and eltypes of the "fields"
    names = ntuple(i -> channelname(N, i), N)
    types = Tuple{ntuple(i -> T, N)...}
    return NamedTuple{names, types}
end

# Extract components
@noinline throw_channelerror(key::Symbol) = error("channel $key not available")
StructArrays.component(c::ColorMixture{T,1}, key::Symbol) where T = key == :channel1 ? c.channels[1] : throw_channelerror(key)
StructArrays.component(c::ColorMixture{T,2}, key::Symbol) where T = key == :channel1 ? c.channels[1] :
                                                                    key == :channel2 ? c.channels[2] : throw_channelerror(key)
StructArrays.component(c::ColorMixture{T,3}, key::Symbol) where T = key == :channel1 ? c.channels[1] :
                                                                    key == :channel2 ? c.channels[2] :
                                                                    key == :channel3 ? c.channels[3] : throw_channelerror(key)

@generated function StructArrays.component(c::ColorMixture{T,N}, key::Symbol) where {T,N}
    ex0 = ex = Expr(:if, :(key == $(QuoteNode(channelname(N, 1)))), :(return c.channels[1]))
    for i = 2:N
        push!(ex.args, Expr(:elseif, :(key == $(QuoteNode(channelname(N, i)))), :(return c.channels[$i])))
        ex = ex.args[end]
    end
    push!(ex.args, :(throw_channelerror(key)))
    return ex0
end

function StructArrays.createinstance(::Type{ColorMixture{T,N,Cs}}, args...) where {T, N, Cs}
    return ColorMixture{T,N,Cs}(args)
end
