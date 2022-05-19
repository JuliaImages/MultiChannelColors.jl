using MultiChannelColors
using Test
using LinearAlgebra

# interacts via @require
using StructArrays
using ImageCore

@testset "MultiChannelColors.jl" begin
    @test isempty(detect_ambiguities(MultiChannelColors))

    @testset "Fluorophore lookup" begin
        cfp = fluorophore_rgb["ECFP"]
        @test blue(cfp) > green(cfp) && blue(cfp) > red(cfp)
        tdtomato = fluorophore_rgb["tdTomato"]
        @test red(tdtomato) > green(tdtomato) && red(tdtomato) > blue(tdtomato)

        @test fluorophore_rgb"ECFP" === cfp
    end

    @testset "Construction and RGB conversion" begin
        channels = (fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"])
        c0 = c = ColorMixture(channels, (1, 0))
        @test c.channels[1] == 1
        @test c.channels[2] == 0
        @test convert(RGB, c) == channels[1]
        c = ColorMixture(channels, (0, 1))
        @test c.channels[1] == 0
        @test c.channels[2] == 1
        @test convert(RGB, c) == channels[2]
        c = ColorMixture(channels, (0.5, 0.5))
        @test c.channels[1] == c.channels[2] == 0.5
        @test convert(RGB, c) ≈ 0.5*channels[1] + 0.5*channels[2]

        fchannels = float.(channels)
        if Base.VERSION >= v"1.8.0-DEV.363"
            @test_throws r"ColorMixture.*expected Tuple{RGB{N0f8}, +RGB{N0f8}}.*got a value of type Tuple{RGB{Float32}, +RGB{Float32}}" ColorMixture{Float32,2,fchannels}(0.1, 0.2)
        else
            @test_throws TypeError ColorMixture{Float32,2,fchannels}(0.1, 0.2)
        end

        # UnionAll constructors
        c = MultiChannelColor{Float32}(0.1, 0.2)
        @test eltype(base_color_type(c)((0.1N0f8, 0.2N0f8)))  === eltype(base_color_type(c)(0.1N0f8, 0.2N0f8))  === N0f8
        @test eltype(base_color_type(c)((0.1N0f8, 0.2N0f16))) === eltype(base_color_type(c)(0.1N0f8, 0.2N0f16)) === N0f16
        @test eltype(MultiChannelColor((0.1N0f8, 0.2N0f16)))  === eltype(MultiChannelColor(0.1N0f8, 0.2N0f16))  === N0f16
        @test eltype(convert(MultiChannelColor{N0f8}, c)) === N0f8

        c = MagentaGreen{Float32}(0.1, 0.2)
        @test eltype(base_color_type(c)((0.1N0f8, 0.2N0f8)))  === eltype(base_color_type(c)(0.1N0f8, 0.2N0f8))  === N0f8
        @test eltype(base_color_type(c)((0.1N0f8, 0.2N0f16))) === eltype(base_color_type(c)(0.1N0f8, 0.2N0f16)) === N0f16
        @test eltype(MagentaGreen((0.1N0f8, 0.2N0f16)))  === eltype(MagentaGreen(0.1N0f8, 0.2N0f16))  === N0f16
        @test eltype(convert(MagentaGreen{N0f8}, c)) === N0f8
        fT(x, y) = ColorMixture{Float64}((RGB(0,1,0), RGB(1,0,0)), x, y)
        f(x, y) = ColorMixture((RGB(0,1,0), RGB(1,0,0)), x, y)
        @test Tuple(Base.VERSION >= v"1.7.0" ? @inferred(fT(0.1, 0.2)) : fT(0.1, 0.2)) === (0.1, 0.2)
        @test Tuple(Base.VERSION >= v"1.7.0" ? @inferred(f(0.1, 0.2)) : f(0.1, 0.2)) === (0.1, 0.2)

        # Overflow behavior
        ctemplate = ColorMixture{N0f8}((RGB(1, 0, 0), RGB(0.5, 0.5, 0)))
        c = ctemplate(0.8, 0.8)
        if Base.VERSION >= v"1.8.0-DEV.363"
            @test_throws "the values (1.2f0, 0.4f0, 0.0f0) do not lie within this range" convert(RGB{N0f8}, c)
            @test_throws "the values (1.2f0, 0.4f0, 0.0f0) do not lie within this range" convert(RGB24, c)
            @test_throws "the values (1.2f0, 0.4f0, 0.0f0) do not lie within this range" convert(RGB, c)
        else
            @test_throws ArgumentError convert(RGB{N0f8}, c)
            @test_throws ArgumentError convert(RGB24, c)
            @test_throws ArgumentError convert(RGB, c)
        end
        @test convert(RGB{Float32}, c) === RGB{Float32}(1.2, 0.4, 0)

        # Macro syntax & inferrability
        f_infer(i1, i2) = ColorMixture{N0f8}((fluorophore_rgb"EGFP", fluorophore_rgb"tdTomato"), (i1, i2))
        f_noinfer(i1, i2) = ColorMixture((fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"]), (i1, i2))
        @test f_infer(1, 0) == f_noinfer(1, 0)
        @test f_infer(1, 0) != f_noinfer(0, 1)
        @test_throws Exception @inferred(f_noinfer(1, 0))
        c2 = Base.VERSION >= v"1.7.0" ? @inferred(f_infer(1, 0)) : f_infer(1, 0)
        @test c2 == c0

        f_infer16(i1, i2) = ColorMixture{N0f16}((fluorophore_rgb"EGFP", fluorophore_rgb"tdTomato"), (i1, i2))
        @test_broken @inferred f_infer16(1, 0)

        # Inferrability from a template
        ctmpl = ColorMixture(channels)
        @test @inferred(ctmpl(1, 0)) === ColorMixture{N0f8}(channels, (1, 0))
    end

    @testset "traits" begin
        for c in (MultiChannelColor{Float32}(0.2, 0.4), GreenMagenta{Float32}(0.2, 0.4))
            @test eltype(c) === Float32
            @test length(c) == 2
            @test color_type(c) === typeof(c)
            @test !isconcretetype(base_color_type(c))
            @test isconcretetype(base_color_type(c){N0f8})
            @test isconcretetype(base_colorant_type(c){N0f8})
            @test eltype(base_color_type(c){N0f8}) === N0f8
            @test comp1(c) === 0.2f0
            @test comp2(c) === 0.4f0
        end
    end

    @testset "mapc etc" begin
        channels = (fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"])
        ctemplate = ColorMixture{N0f8}(channels)
        c = ctemplate(0.4, 0.2)
        if Base.VERSION >= v"1.7"
            @test @inferred(mapc(x->2x, c)) === ColorMixture{Float32}(channels, (0.8, 0.4))
        else
            @test_broken @inferred(mapc(x->2x, c)) === ColorMixture{Float32}(channels, (0.8, 0.4))
        end
        @test @inferred(mapreducec(x->2x, +, 0f0, c)) === 1.2f0
        @test @inferred(reducec(+, 0N0f8, c)) === reduce(+, (0.4N0f8, 0.2N0f8))
    end

    @testset "Operations" begin
        MCC{T} = MultiChannelColor{T,2}
        CM{T} = GreenMagenta{T}
        g = (3, 2)
        for (Ta, Tb) in ((N0f8, N0f8),
                         (Float32, Float32),
                         (N0f8, Float32),
                         (Float32, N0f8))
            for C in (MCC, CM)
                a, b = C{Ta}(0.2, 0.4), C{Tb}(0.2, 0.1)
                @test +a === a
                if Ta <: AbstractFloat
                    @test -a === C{Ta}(-0.2, -0.4)
                    @test abs(-a) === a
                end
                @test norm(a) == norm([Tuple(a)...])
                @test abs2(a) === float(Ta(0.2)^2) + Ta(0.4)^2
                @test a + b === C(Ta(0.2) + Tb(0.2), Ta(0.4) + Tb(0.1))
                @test a - b === C(Ta(0.2) - Tb(0.2), Ta(0.4) - Tb(0.1))
                @test 2a === a*2 === C(2*Ta(0.2), 2*Ta(0.4))
                @test a/2 === C(Ta(0.2)/2, Ta(0.4)/2)
                @test a ⊙ b === C(Ta(0.2)*Tb(0.2), Ta(0.4)*Tb(0.1))
                @test g ⊙ a === a ⊙ g === C(g[1]*comp1(a), g[2]*comp2(a))
                @test a ⋅ b === float(Ta(0.2)*Tb(0.2)) + Ta(0.4)*Tb(0.1)

                @test a === copy(a)
                x = [a, b]
                @test sum(x) ≈ float(a) + b
                x = typeof(a)[]
                @test sum(x) == float(zero(a))
                x = [a]
                @test sum(x) ≈ float(a)
            end
        end
        for C in (MCC, CM)
            a = C{Bool}(true, false)
            @test +a === a
            x = [a, a]
            @test sum(x) == 2a
            x = typeof(a)[]
            @test sum(x) == float(zero(a))
            x = [a]
            @test sum(x) == float(a)
        end

        a = GreenMagenta(0.1, 0.2)
        b = MagentaGreen(0.1, 0.2)
        c = MagentaGreen(0.2, 0.1)
        @test a != b
        @test a != c
        @test a == a
        @test !isequal(a, b)
        @test !isequal(a, c)
        @test  isequal(a, a)
        a = GreenMagenta(0.1, NaN)
        b = MagentaGreen(0.1, NaN)
        @test a != a
        @test isequal(a, a)
        @test !isequal(a, b)
    end

    @testset "Conversion (other color spaces)" begin
        if Base.VERSION >= v"1.8.0-DEV.363"
            @test_throws "No conversion of (0.1₁, 0.2₂) to RGB{Float64} has been defined" convert(RGB, MultiChannelColor(0.1, 0.2))
        end
        @test convert(HSV, GreenMagenta{Float32}(0.2, 0.4)) === convert(HSV, RGB{Float32}(0.4, 0.2, 0.4))
    end

    @testset "StructArrays" begin
        channels = (fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"])
        ctemplate = ColorMixture(channels)
        green, red = N0f8[0.2, 0.4], N0f8[0.8, 0.6]
        soa = StructArray{typeof(ctemplate)}((green, red))
        @test soa[1] === ctemplate(green[1], red[1])
        @test soa[2] === ctemplate(green[2], red[2])
        soa[1] = ctemplate((0.5, 0.0))
        @test green[1] === 0.5N0f8
        @test red[1] === 0.0N0f8

        # Hyperspectral
        cols = MultiChannelColors.Colors.distinguishable_colors(16, [RGB(0,0,0)]; dropseed=true)
        ctemplate = ColorMixture{Float32}((cols...,))
        comps = collect(reshape((0:31)/32f0, 16, 2))
        compsr = reinterpret(reshape, typeof(ctemplate), comps)
        soa = StructArray{typeof(ctemplate)}(comps; dims=1)
        @test soa == compsr
        @test size(soa) == (2,)
        @test soa[1] == ctemplate(ntuple(i->(i-1)/32, 16))
        compst = collect(transpose(comps))
        soa = StructArray{typeof(ctemplate)}(compst; dims=2)
        @test soa[1] == ctemplate(ntuple(i->(i-1)/32, 16))
        c = soa[1]
        @test comp3(c) === Tuple(c)[3]
        @test comp4(c) === Tuple(c)[4]
        @test comp5(c) === Tuple(c)[5]
    end

    @testset "ImageCore" begin
        # Integration with the rest of the JuliaImages ecosystem
        ctemplate = ColorMixture{N0f8}((RGB(1, 0, 0), RGB(0.5, 0.5, 0)))
        c = ctemplate(0.8, 0.8)
        @test convert(RGB{Float32}, c) === RGB{Float32}(1.2, 0.4, 0)
        @test clamp01(c)    === RGB{N0f8}(1, 0.4, 0)
        @test clamp01nan(c) === RGB{N0f8}(1, 0.4, 0)
        ctemplate = ColorMixture{Float32}((RGB(1, 0, 0), RGB(0.5, 0.5, 0)))
        c = ctemplate(0.8, NaN)
        @test isequal(convert(RGB, c), RGB{Float32}(NaN,NaN,NaN))
        @test clamp01nan(c) === RGB{Float32}(0, 0, 0)
    end

    @testset "IO" begin
        channels = (fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"])
        c = ColorMixture(channels, (1, 0))
        @test sprint(show, c) == "(1.0N0f8₁, 0.0N0f8₂)"

        # Hyperspectral
        cols = MultiChannelColors.Colors.distinguishable_colors(16, [RGB(0,0,0)]; dropseed=true)
        ctemplate = ColorMixture{Float32}((cols...,))
        c = ctemplate([i/16 for i = 0:15]...)
        @test sprint(show, c) == "(0.0₀₁, 0.0625₀₂, 0.125₀₃, 0.1875₀₄, 0.25₀₅, 0.3125₀₆, 0.375₀₇, 0.4375₀₈, 0.5₀₉, 0.5625₁₀, 0.625₁₁, 0.6875₁₂, 0.75₁₃, 0.8125₁₄, 0.875₁₅, 0.9375₁₆)"

        # To increase coverage (`csvparse` only runs when the package is built, so it appears untested even though it is not)
        @test MultiChannelColors.csvparse(joinpath(dirname(@__DIR__), "data", "organics.csv")) isa Dict{String,RGB{N0f8}}
    end
end
