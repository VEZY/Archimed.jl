using Documenter, Archimed

makedocs(;
    modules=[Archimed],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/VEZY/Archimed.jl/blob/{commit}{path}#L{line}",
    sitename="Archimed.jl",
    authors="remi.vezy <VEZY@users.noreply.github.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/VEZY/Archimed.jl",
)
