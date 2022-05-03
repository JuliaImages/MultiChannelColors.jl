using FluorophoreColors
using Documenter

DocMeta.setdocmeta!(FluorophoreColors, :DocTestSetup, :(using FluorophoreColors); recursive=true)

makedocs(;
    modules=[FluorophoreColors],
    authors="Tim Holy <tim.holy@gmail.com> and contributors",
    repo="https://github.com/JuliaImages/FluorophoreColors.jl/blob/{commit}{path}#{line}",
    sitename="FluorophoreColors.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaImages.github.io/FluorophoreColors.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaImages/FluorophoreColors.jl",
    devbranch="main",
)
