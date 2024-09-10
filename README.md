# SymbolicArrays

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://mtfishman.github.io/SymbolicArrays.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://mtfishman.github.io/SymbolicArrays.jl/dev/)
[![Build Status](https://github.com/mtfishman/SymbolicArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/mtfishman/SymbolicArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/mtfishman/SymbolicArrays.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/mtfishman/SymbolicArrays.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

## Introduction

````julia
using AbstractTrees: print_tree
using SymbolicArrays: SymbolicArray, expand
````

2×2 symbolic arrays/matrices `a` and `b`:

````julia
a = SymbolicArray(:a, 2, 2)
````

````
2×2 SymbolicArrays.SymbolicArray{Any, 2, Symbol}:
a
````

````julia
b = SymbolicArray(:b, 2, 2)
````

````
2×2 SymbolicArrays.SymbolicArray{Any, 2, Symbol}:
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
print_tree(r)
````

````
*
├─ *
│  ├─ a(:i, :j)
│  └─ a(:j, :k)
└─ *
   ├─ a(:k, :l)
   └─ +
      ├─ a(:l, :m)
      └─ b(:l, :m)

````

Expand the sums in the expression to generate
a sum of tensor network contractions:

````julia
print_tree(expand(r))
````

````
+
├─ *
│  ├─ *
│  │  ├─ a(:i, :j)
│  │  └─ a(:j, :k)
│  └─ *
│     ├─ a(:k, :l)
│     └─ a(:l, :m)
└─ *
   ├─ *
   │  ├─ a(:i, :j)
   │  └─ a(:j, :k)
   └─ *
      ├─ a(:k, :l)
      └─ b(:l, :m)

````

In the future we plan to support other expression manipulations, such as `substitute`
(similar to [Symbolics.substitute](https://docs.sciml.ai/Symbolics/stable/manual/expression_manipulation/#SymbolicUtils.substitute))
for substituting a tensor/subexpression with a new tensor/subexpression, contraction sequence
optimization, and differentiation.

## Plans

### Basic operations and modifications to implement

The following still need to be implemented:
1. complex conjugation of tensors (`conj(a(i, j))`),
2. `dag(a(i, j))` for swapping contravariant and covariant dimensions/indices (and complex conjugating),
3. `substitute(t::TensorExpr.Type, dict::Dict)` for replacing a subexpression with another expression
(see [Symbolics.substitute](https://symbolics.juliasymbolics.org/stable/manual/expression_manipulation/#SymbolicUtils.substitute)),
4. change the storage of sum arguments from `Set` to `Vector` (maybe, might make some operations like expression
comparison slower unless we sort arguments like is done in `Symbolics.jl`, but that may be difficult in general),
5. make `TensorExpr` an `AbstractArray`/`AbstractNamedDimArray` subtype, maybe rename `SymbolicNamedDimArray`,
6. measurements of complexity/computational cost (`cost`, `flops`/`removedsize`
([EinExprs.jl](https://bsc-quantic.github.io/EinExprs.jl/stable/counters)),
`time_complexity`/`space_complexity` ([OMEinsumContractionOrders.jl](https://github.com/TensorBFS/OMEinsumContractionOrders.jl))),
7. expression/contraction path/sequence/order optimization (`optimize_expr`/`optimize_contraction`,
`optimize_code` ([OMEinsumContractionOrders.jl](https://github.com/TensorBFS/OMEinsumContractionOrders.jl)),
`optimal_contraction_tree`/`optimal_contraction_order` ([TensorOperations.jl](https://jutho.github.io/TensorOperations.jl/stable/man/indexnotation/#TensorOperations.@tensoropt))),

and more.

### Visualization

Currently you can visualize an expression tree/directed acyclic graph (DAG) of tensor operations using
`AbstractTrees.print_tree` as shown above. In addition, the goal will be to support using
[GraphMakie.jl](https://graph.makie.org/stable/generated/syntaxtree) to visualize the tensor expression
as a graph by converting the expression tree/DAG to a graph. See [this section](https://graph.makie.org/stable/generated/syntaxtree)
of the `GraphMakie.jl` documentation as a reference, as well as [TreeView.jl](https://github.com/JuliaTeX/TreeView.jl)
which visualizes Julia expressions using TikZ. Also see [this code](https://github.com/ITensor/ITensorVisualizationBase.jl/blob/v0.1.11/src/visualize.jl#L62-L102)
in [ITensorVisualizationBase.jl](https://github.com/ITensor/ITensorVisualizationBase.jl) as a reference for converting
an `AbstractTrees.jl`-compatible tree structure to a `Graphs.jl`-compatible graph.

### Code transformations

Currently the package only supports expanding subexpressions which are sums of tensors into
outer sums of tensor contractions using the `SymbolicArrays.expand` function.
The goal is to support a wider range of code transformations, such as:
1. optimizing the contraction sequences/paths of tensor networks (see [EinExprs.jl](https://github.com/bsc-quantic/EinExprs.jl),
[OMEinsumContractionOrders.jl](https://github.com/TensorBFS/OMEinsumContractionOrders.jl), [cotengra](https://github.com/jcmgray/cotengra), etc.),
2. computing first and higher order derivatives of tensor networks (see [AutoHoot](https://github.com/LinjianMa/AutoHOOT)),
3. common subexpression elimination (see [CommonSubexpressions.jl](https://github.com/rdeits/CommonSubexpressions.jl)),
4. parallelization over independent operations (see [Dagger.jl](https://github.com/JuliaParallel/Dagger.jl)),

and more.

Related projects for symbolic manipulations in Julia include
[SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl)/[Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl),
which is mostly focused on scalar manipulations but has growing support for
[symbolic array operations](https://symbolics.juliasymbolics.org/stable/manual/arrays/#symbolic_arrays).
A prominant term rewriting tool in Julia is [Metatheory.jl](https://github.com/JuliaSymbolics/Metatheory.jl).
We may be able to interface `SymbolicArrays.jl` with `Metatheory.jl` through
[TermInterface.jl](https://github.com/JuliaSymbolics/TermInterface.jl).

See also [SimpleExpressions.jl](https://github.com/jverzani/SimpleExpressions.jl),
[DynamicsExpressions.jl](https://github.com/SymbolicML/DynamicExpressions.jl),
and [CallableExpressions.jl](https://gitlab.com/nsajko/CallableExpressions.jl).

Of course, this is a very ambitious list of goals, and the timeline for implementing them is unclear.
Additionally, there is clearly a lot of overlap with the goals of this package and existing work,
so minimzing duplication would be ideal. An advantage of the current approach is that it is based on
a very principled implementation of algebraic data types (ADTs) and pattern matching in Julia
through the wonderful [Moshi.jl](https://github.com/Roger-luo/Moshi.jl) package. Ideally
we will leverage more general tools for term rewriting, parallelization, and differentiation
that builds on top of the ADT and pattern matching of Moshi.jl and/or shares infrastructure with
other parts of the Julia ecosystem like Metatheory.jl, TermInterface.jl, and Symbolics.jl instead
of having to reimplement that from scratch.

Ultimately the goal is also to have tight interoperability of `SymbolicArrays.jl` with [ITensors.jl](https://github.com/ITensor/ITensors.jl)
and [ITensorNetworks.jl](https://github.com/ITensor/ITensorNetworks.jl), so that networks of ITensors can easily be
converted to symbolic expressions, transformed in some way, and then converted back to numerical tensors. ITensors
may even by wrapped into symbolic tensors or vice versa, the exact design is unclear at the moment and will require
some investigation. Some of that will be easier to implement with the upcoming
[redesign of the ITensor internals](https://github.com/ITensor/ITensors.jl/issues/1250), in particular basing
ITensors off of a more general [AbstractNamedDimArray](https://github.com/ITensor/ITensors.jl/tree/v0.6.17/NDTensors/src/lib/NamedDimsArrays)
interface, so that symbolic tensors and ITensors can both be `AbstractNamedDimArray` subtypes.

## Generating this README

This README was generated directly from
[this source file](https://github.com/mtfishman/SymbolicArrays.jl/blob/main/examples/README.jl)
running these commands from the package root of SymbolicArrays.jl:

```julia
import Pkg, Literate; Pkg.activate("examples"); Literate.markdown("examples/README.jl", "."; flavor=Literate.CommonMarkFlavor(), execute=true)
```

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

