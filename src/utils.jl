const subscripts = ('₀', '₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉')
function print_subscript(io::IO, N::Int, i::Int)
    nd = ndigits(N)
    base = 10^(nd-1)
    while nd > 1
        id, i = divrem(i, base)
        print(io, subscripts[id+1])
        nd -= 1
        base ÷= 10
    end
    print(io, subscripts[i+1])
    return nothing
end
