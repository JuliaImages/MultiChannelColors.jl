using FluorophoreColors
using Test

# interacts via @require
using StructArrays

@testset "FluorophoreColors.jl" begin
    @test isempty(detect_ambiguities(FluorophoreColors))

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
        cols = FluorophoreColors.Colors.distinguishable_colors(16, [RGB(0,0,0)]; dropseed=true)
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
    end

    @testset "IO" begin
        channels = (fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"])
        c = ColorMixture(channels, (1, 0))
        @test sprint(show, c) == "(1.0₁, 0.0₂)"

        # Hyperspectral
        cols = FluorophoreColors.Colors.distinguishable_colors(16, [RGB(0,0,0)]; dropseed=true)
        ctemplate = ColorMixture{Float32}((cols...,))
        c = ctemplate([i/16 for i = 0:15]...)
        @test sprint(show, c) == "(0.0₀₁, 0.0625₀₂, 0.125₀₃, 0.1875₀₄, 0.25₀₅, 0.3125₀₆, 0.375₀₇, 0.4375₀₈, 0.5₀₉, 0.5625₁₀, 0.625₁₁, 0.6875₁₂, 0.75₁₃, 0.8125₁₄, 0.875₁₅, 0.9375₁₆)"
    end
end
