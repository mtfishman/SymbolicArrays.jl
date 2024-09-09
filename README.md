# SymbolicArrays

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://mtfishman.github.io/SymbolicArrays.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://mtfishman.github.io/SymbolicArrays.jl/dev/)
[![Build Status](https://github.com/mtfishman/SymbolicArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/mtfishman/SymbolicArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/mtfishman/SymbolicArrays.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/mtfishman/SymbolicArrays.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

## Introduction

````julia
using SymbolicArrays: SymbolicArray, expand
````

2×2 symbolic arrays/matrices `a` and `b`:

````julia
a = SymbolicArray(:a, 2, 2)
````

````
2×2 SymbolicArray{Any, 2, Symbol}:
a
````

````julia
b = SymbolicArray(:b, 2, 2)
````

````
2×2 SymbolicArray{Any, 2, Symbol}:
b
````

Index/dimension/mode names:

````julia
i, j, k, l, m = :i, :j, :k, :l, :m
````

````
(:i, :j, :k, :l, :m)
````

Example of a tensor expression involving contractions
and sums of tensors:

````julia
r = (a(i, j) * a(j, k)) * (a(k, l) * (a(l, m) + b(l, m)))
````

````
((a(:i, :j) * a(:j, :k)) * (a(:k, :l) * (a(:l, :m) + b(:l, :m))))
````

Expand the sums in the expression to generate
a sum of tensor network contractions:

````julia
expand(r)
````

````
(((a(:i, :j) * a(:j, :k)) * (a(:k, :l) * a(:l, :m))) + ((a(:i, :j) * a(:j, :k)) * (a(:k, :l) * b(:l, :m))))
````

This README was generated directly from
[this source file](https://github.com/mtfishman/SymbolicArrays.jl/blob/main/examples/README.jl)
running these commands from the package root of SymbolicArrays.jl:

```julia
using Literate: Literate
Literate.markdown("examples/README.jl", "."; flavor=Literate.CommonMarkFlavor(), execute=true)
```

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

