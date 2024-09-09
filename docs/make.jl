using SymbolicArrays
using Documenter

DocMeta.setdocmeta!(SymbolicArrays, :DocTestSetup, :(using SymbolicArrays); recursive=true)

makedocs(;
  modules=[SymbolicArrays],
  authors="Matthew Fishman <mfishman@flatironinstitute.org> and contributors",
  sitename="SymbolicArrays.jl",
  format=Documenter.HTML(;
    canonical="https://mtfishman.github.io/SymbolicArrays.jl",
    edit_link="main",
    assets=String[],
  ),
  pages=["Home" => "index.md"],
)

deploydocs(; repo="github.com/mtfishman/SymbolicArrays.jl", devbranch="main")
