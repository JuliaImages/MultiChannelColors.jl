using FluorophoreColors
using Test

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

        f_infer(i1, i2) = ColorMixture{N0f8}((fluorophore_rgb"EGFP", fluorophore_rgb"tdTomato"), (i1, i2))
        f_noinfer(i1, i2) = ColorMixture((fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"]), (i1, i2))
        @test f_infer(1, 0) == f_noinfer(1, 0)
        @test f_infer(1, 0) != f_noinfer(0, 1)
        @test_throws Exception @inferred(f_noinfer(1, 0))
        c2 = Base.VERSION >= v"1.7.0" ? @inferred(f_infer(1, 0)) : f_infer(1, 0)
        @test c2 == c0

        f_infer16(i1, i2) = ColorMixture{N0f16}((fluorophore_rgb"EGFP", fluorophore_rgb"tdTomato"), (i1, i2))
        @test_broken @inferred f_infer16(1, 0)

        ctmpl = ColorMixture(channels)
        @test @inferred(ctmpl(1, 0)) === ColorMixture{N0f8}(channels, (1, 0))
    end

    @testset "IO" begin
        channels = (fluorophore_rgb["EGFP"], fluorophore_rgb["tdTomato"])
        c = ColorMixture(channels, (1, 0))
        @test sprint(show, c) == "(1.0₁, 0.0₂)"
    end
end
