using MultiChannelColors
using Documenter

DocMeta.setdocmeta!(MultiChannelColors, :DocTestSetup, :(using MultiChannelColors); recursive=true)

makedocs(;
    modules=[MultiChannelColors],
    authors="Tim Holy <tim.holy@gmail.com> and contributors",
    repo="https://github.com/JuliaImages/MultiChannelColors.jl/blob/{commit}{path}#{line}",
    sitename="MultiChannelColors.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaImages.github.io/MultiChannelColors.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "FAQ" => "faq.md",
        "Reference" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaImages/MultiChannelColors.jl",
    devbranch="main",
)
