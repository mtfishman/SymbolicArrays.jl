using ..BaseExtensions: generic_map
using Combinatorics: combinations
using IterTools: flagfirst
using Moshi.Data: @data, variant_fieldnames, variant_type
using Moshi.Match: @match
using ..NamedIntegers: NamedIntegers, Name, NamedInteger, name, named, unname

# TODO: Make this a subtype of `NamedDimArrays.AbstractNamedDimArray`
# TODO: Parametrize by NamedDimArray name, namedsize, coefficient
# types, etc.
@data SymbolicNamedDimArrayVariants <: AbstractArray{Any,Any} begin
  struct Array
    name::Any
    namedsize::Vector
  end
  struct Identity
    codomain_namedlength::Any
    domain_namedlength::Any
  end
  struct Isometry
    name::Any
    codomain_namedsize::Vector
    domain_namedsize::Vector
  end
  struct Conj
    argument::SymbolicNamedDimArrayVariants
  end
  struct Contract
    arguments::Vector{SymbolicNamedDimArrayVariants}
    leaf_arguments::Vector{SymbolicNamedDimArrayVariants}
    namedsize::Vector
  end
  struct Sum
    arguments::Set{SymbolicNamedDimArrayVariants}
    coefficients::Dict{SymbolicNamedDimArrayVariants,Number}
    namedsize::Vector
  end
  struct Scale
    coefficient::Number
    term::SymbolicNamedDimArrayVariants
  end
end

const SymbolicNamedDimArrayExpr = SymbolicNamedDimArrayVariants.Type
const SymbolicNamedDimArray = SymbolicNamedDimArrayVariants.Array
const SymbolicNamedDimIdentity = SymbolicNamedDimArrayVariants.Identity
const SymbolicNamedDimIsometry = SymbolicNamedDimArrayVariants.Isometry
const SymbolicNamedDimArrayConj = SymbolicNamedDimArrayVariants.Conj
const SymbolicNamedDimArrayContract = SymbolicNamedDimArrayVariants.Contract
const SymbolicNamedDimArraySum = SymbolicNamedDimArrayVariants.Sum
const SymbolicNamedDimArrayScale = SymbolicNamedDimArrayVariants.Scale

# TODO: Move to `SymbolicArraysSymbolicTensorsExt`.
function Base.getindex(a::AbstractSymbolicArray, dimnames::Name...)
  @assert ndims(a) == length(dimnames)
  return SymbolicNamedDimArray(name(a), named.(size(a), unname.(dimnames))...)
end
function Base.getindex(a::SymbolicIdentity, dimnames::Name...)
  @assert ndims(a) == length(dimnames)
  return SymbolicNamedDimIdentity(named.(size(a), unname.(dimnames))...)
end

# TODO: Use `AbstractNamedInteger`.
function SymbolicNamedDimArray(name, namedsize::NamedInteger...)
  return SymbolicNamedDimArray(name, [namedsize...])
end

function NamedIntegers.name(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArray(; name) => name
    SymbolicNamedDimIdentity() => name(unname(t))
    _ => error("No name.")
  end
end

function NamedIntegers.unname(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArray() => SymbolicArray(name(t), size(t)...)
    SymbolicNamedDimIdentity() => SymbolicIdentity(size(t)[1]) # TODO: Use `codomain_length`?
    _ => error("No name.")
  end
end

# Determine the named size from the arguments of
# a sum, either the first argument or empty
# if there are no arguments.
function namedsize_sum_arguments(arguments)
  # TODO: Use `AbstractNamedInteger[]`?
  isempty(arguments) && return []
  return namedsize(first(arguments))
end

"""
Sum based on arguments.
"""
function SymbolicNamedDimArraySum(arguments::Set{SymbolicNamedDimArrayExpr})
  coefficients = Dict((unscale(term) => coefficient(term) for term in arguments))
  namedsize = namedsize_sum_arguments(arguments)
  return SymbolicNamedDimArraySum(; arguments, coefficients, namedsize)
end

function SymbolicNamedDimArraySum(arguments::Vector{SymbolicNamedDimArrayExpr})
  return SymbolicNamedDimArraySum(Set(arguments))
end

# TODO: This overwrite a method in Moshi.jl, check if this
# needs to be defined.
# SymbolicNamedDimArraySum() = SymbolicNamedDimArraySum(Set{SymbolicNamedDimArrayExpr}())

"""
Sum based on arguments.
"""
function SymbolicNamedDimArraySum(coefficients::Dict{SymbolicNamedDimArrayExpr,<:Number})
  arguments = Set([coefficients[unscale] * unscale for unscale in eachindex(coefficients)])
  namedsize = namedsize_sum_arguments(arguments)
  return SymbolicNamedDimArraySum(; arguments, coefficients, namedsize)
end

function namedsize(t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArray(; namedsize) => namedsize
    SymbolicNamedDimIdentity(; codomain_namedlength, domain_namedlength) =>
      [codomain_namedlength, domain_namedlength]
    SymbolicNamedDimArrayContract(; namedsize) => namedsize
    SymbolicNamedDimArraySum() => namedsize_sum_arguments(arguments(t))
    SymbolicNamedDimArrayScale(; term) => namedsize(term)
  end
end

function Base.size(t::SymbolicNamedDimArrayExpr)
  return unname.(namedsize(t))
end

function dimnames(t::SymbolicNamedDimArrayExpr)
  return name.(namedsize(t))
end

"""
The function/operator associated with the head/root of the
symbolic expression, see also `SymbolicUtils.operator`
and `arguments`.
"""
function operator(t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArray() || SymbolicNamedDimIdentity() => nothing
    SymbolicNamedDimArrayScale() => *
    SymbolicNamedDimArrayContract() => *
    SymbolicNamedDimArraySum() => +
  end
end

"""
The (NamedDimArray) arguments of a NamedDimArray contraction or sum.
See also `SymbolicUtils.arguments` and `TermInterface.arguments`.
"""
function arguments(t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArray() || SymbolicNamedDimIdentity() => ()
    SymbolicNamedDimArrayScale() => (coefficient(t), unscale(t))
    SymbolicNamedDimArrayContract(; arguments) => arguments
    SymbolicNamedDimArraySum(; arguments) => arguments
  end
end

function map_arguments(f, t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArray() || SymbolicNamedDimIdentity() => ()
    SymbolicNamedDimArrayScale() => f(coefficient(t)) * f(unscale(t))
    SymbolicNamedDimArrayContract() =>
      SymbolicNamedDimArrayContract(generic_map(f, arguments(t)))
    SymbolicNamedDimArraySum() => SymbolicNamedDimArraySum(generic_map(f, arguments(t)))
  end
end

"""
The leaf (NamedDimArray) arguments of a nested NamedDimArray contraction or sum.
"""
function leaf_arguments(t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArray() || SymbolicNamedDimIdentity() => [t]
    SymbolicNamedDimArrayContract(; leaf_arguments) => leaf_arguments
    SymbolicNamedDimArraySum(; arguments) => arguments
    SymbolicNamedDimArrayScale(; term) => arguments(term)
  end
end

function leaf_contract_arguments(t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArrayContract() => leaf_arguments(t)
    _ => t
  end
end

"""
The (NamedDimArray) arguments of a NamedDimArray contraction.
"""
function arguments_contract(t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArrayContract(; arguments) => arguments
    _ => [t]
  end
end

"""
The (NamedDimArray) arguments of a NamedDimArray sum.
"""
function arguments_sum(t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArraySum(; arguments) => arguments
    _ => Set([t])
  end
end

"""
The coefficient of a NamedDimArray.
"""
function coefficient(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArrayScale(; coefficient) => coefficient
    SymbolicNamedDimArray() || SymbolicNamedDimArrayContract() => 1
    SymbolicNamedDimArraySum() => coefficient(only(arguments(t)))
  end
end

"""
The coefficient of an unscaled term in a sum.
"""
function coefficient(t::SymbolicNamedDimArrayExpr, arg::SymbolicNamedDimArrayExpr)
  return coefficients(t)[arg]
end

"""
A dictionary from unscaled arguments/terms of a sum
to their corresponding coefficients.
"""
function coefficients(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArraySum(; coefficients) => coefficients
    _ => Dict(unscale(t) => coefficient(t))
  end
end

function unscale(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArray() => t
    SymbolicNamedDimArrayContract() => t
    SymbolicNamedDimArraySum() => t
    SymbolicNamedDimArrayScale(; term) => term
  end
end

function SymbolicNamedDimArrayContract(arguments::Vector{SymbolicNamedDimArrayExpr})
  leaf_arguments = if length(arguments) < 2
    arguments
  else
    mapreduce(leaf_contract_arguments, vcat, arguments)
  end
  new_namedsize = mapreduce(namedsize, symdiff, arguments)
  return SymbolicNamedDimArrayContract(; arguments, leaf_arguments, namedsize=new_namedsize)
end

# Contract two tensors/tensor networks together.
function contract_tensors(t1, t2)
  arguments = [t1, t2]
  leaf_arguments = [leaf_contract_arguments(t1); leaf_contract_arguments(t2)]
  new_namedsize = symdiff(namedsize(t1), namedsize(t2))
  return SymbolicNamedDimArrayContract(; arguments, leaf_arguments, namedsize=new_namedsize)
end

function Base.:*(t1::SymbolicNamedDimArrayExpr, t2::SymbolicNamedDimArrayExpr)
  res_namedsize = symdiff(namedsize(t1), namedsize(t2))
  @match t1, t2 begin
    (SymbolicNamedDimArrayScale(), _) => coefficient(t1) * (unscale(t1) * t2)
    (_, SymbolicNamedDimArrayScale()) => coefficient(t2) * (t1 * unscale(t2))
    (_, _) => contract_tensors(t1, t2)
  end
end

function Base.:*(c::Number, t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArraySum() => map_arguments(term -> c * term, t)
    SymbolicNamedDimArrayScale() => c * coefficient(t) * unscale(t)
    _ => SymbolicNamedDimArrayScale(c, t)
  end
end

# Assumes scalar multiplication is commutative.
# TODO: Make a definition which accounts for numbers that
# don't have commutative multiplication.
function Base.:*(t::SymbolicNamedDimArrayExpr, c::Number)
  return c * t
end

Base.:-(t::SymbolicNamedDimArrayExpr) = -1 * t

function Base.:/(t::SymbolicNamedDimArrayExpr, c::Number)
  return t * inv(c)
end

function isequal_tensors(t1, t2)
  return name(t1) == name(t2) && namedsize(t1) == namedsize(t2)
end

function isequal_arguments(t1, t2)
  return issetequal(leaf_arguments(t1), leaf_arguments(t2))
end

function isequal_single_argument(t1, t2)
  if isone(length(leaf_arguments(t1))) && isone(length(leaf_arguments(t2)))
    return only(leaf_arguments(t1)) == only(leaf_arguments(t2))
  end
  return false
end

function isequal_scales(t1, t2)
  return (coefficient(t1) == coefficient(t2)) && (unscale(t1) == unscale(t2))
end

# TODO: How should this be defined? Equality of expressions is nontrivial:
# https://github.com/JuliaSymbolics/Symbolics.jl/issues/492
# https://www.stochasticlifestyle.com/useful-algorithms-that-are-not-optimized-by-jax-pytorch-or-tensorflow
# https://docs.sciml.ai/Symbolics/stable/manual/faq/#Equality-and-set-membership-tests
# https://discourse.julialang.org/t/checking-for-equality-and-for-equivalence-of-symbolic-expressions/61276
# https://discourse.julialang.org/t/when-are-two-expressions-equal/87045
# Maybe we should use `isequal` instead, like `Symbolics.jl` does.
# Also, consider calling `expand` on both sides of the equality first to try
# to canonicalize the expressions as much as possible.
function Base.:(==)(t1::SymbolicNamedDimArrayExpr, t2::SymbolicNamedDimArrayExpr)
  return @match (t1, t2) begin
    (SymbolicNamedDimArray(), SymbolicNamedDimArray()) => isequal_tensors(t1, t2)
    (SymbolicNamedDimIdentity(), SymbolicNamedDimIdentity()) => isequal_tensors(t1, t2)
    (SymbolicNamedDimIdentity(), SymbolicNamedDimArray()) ||
      (SymbolicNamedDimArray(), SymbolicNamedDimIdentity()) => false
    (SymbolicNamedDimArrayScale(), SymbolicNamedDimArrayScale()) ||
      (SymbolicNamedDimArrayScale(), SymbolicNamedDimArray()) ||
      (SymbolicNamedDimArray(), SymbolicNamedDimArrayScale()) ||
      (SymbolicNamedDimArrayScale(), SymbolicNamedDimArrayContract()) ||
      (SymbolicNamedDimArrayContract(), SymbolicNamedDimArrayScale()) =>
      isequal_scales(t1, t2)
    (SymbolicNamedDimArrayContract(), SymbolicNamedDimArrayContract()) ||
      (SymbolicNamedDimArraySum(), SymbolicNamedDimArraySum()) => isequal_arguments(t1, t2)
    (SymbolicNamedDimArraySum(), _) => t1 == SymbolicNamedDimArraySum([t2])
    (_, SymbolicNamedDimArraySum()) => SymbolicNamedDimArraySum([t1]) == t2
    (SymbolicNamedDimArrayContract(), _) => t1 == SymbolicNamedDimArrayContract([t2])
    (_, SymbolicNamedDimArrayContract()) => SymbolicNamedDimArrayContract([t1]) == t2
    (_, _) => error("Not implemented.")
  end
end

function hash_tensor(t, h::UInt)
  h = hash(Symbol(variant_type(t)), h)
  for fieldname in variant_fieldnames(t)
    h = hash(getproperty(t, fieldname), h)
  end
  return h
end

function hash_contract_or_sum(t, h::UInt)
  h = hash(Symbol(variant_type(t)), h)
  return hash(leaf_arguments(t), h)
end

function Base.hash(t::SymbolicNamedDimArrayExpr, h::UInt)
  return @match t begin
    SymbolicNamedDimArray() || SymbolicNamedDimIdentity() => hash_tensor(t, h)
    SymbolicNamedDimArrayScale(; coefficient=1) => hash(unscale(t), h)
    SymbolicNamedDimArrayScale() => hash_tensor(t, h)
    SymbolicNamedDimArrayContract() => hash_contract_or_sum(t, h)
    SymbolicNamedDimArraySum() => hash_contract_or_sum(t, h)
  end
end

function add_sums(t1, t2)
  return SymbolicNamedDimArraySum(mergewith(+, coefficients(t1), coefficients(t2)))
end

function Base.:+(t1::SymbolicNamedDimArrayExpr, t2::SymbolicNamedDimArrayExpr)
  dimnames(t1) == dimnames(t2) || throw(ErrorException("Dimension names must match."))
  # TODO: Handle when t1 == t2 (combine into arguments with coefficients), combining sums, etc.
  return @match (t1, t2) begin
    (t, t) => 2t
    (SymbolicNamedDimArraySum(), SymbolicNamedDimArraySum()) => add_sums(t1, t2)
    (SymbolicNamedDimArraySum(), _) => t1 + SymbolicNamedDimArraySum(Set([t2]))
    (_, SymbolicNamedDimArraySum()) => SymbolicNamedDimArraySum(Set([t1])) + t2
    _ => SymbolicNamedDimArraySum(Set([t1, t2]))
  end
end

function Base.:-(t1::SymbolicNamedDimArrayExpr, t2::SymbolicNamedDimArrayExpr)
  return @match (t1, t2) begin
    (t, t) => 0t
    _ => t1 + -t2
  end
end

function expand_arguments_sums(t1, t2)
  return mapreduce(splat(*), +, Iterators.product(arguments(t1), arguments(t2)))
end

function expand_arguments(t1::SymbolicNamedDimArrayExpr, t2::SymbolicNamedDimArrayExpr)
  @match t1, t2 begin
    (SymbolicNamedDimArraySum(), SymbolicNamedDimArraySum()) =>
      expand_arguments_sums(t1, t2)
    (SymbolicNamedDimArraySum(), _) =>
      SymbolicNamedDimArraySum(generic_map(a1 -> a1 * t2, arguments(t1)))
    (_, SymbolicNamedDimArraySum()) =>
      SymbolicNamedDimArraySum(generic_map(a2 -> t1 * a2, arguments(t2)))
    (_, _) => t1 * t2
  end
end

function expand_contract(t)
  return mapreduce(expand, expand_arguments, arguments(t))
end

function expand_sum(t)
  return mapreduce(expand, +, arguments(t))
end

function expand_scale(t)
  return coefficient(t) * expand(unscale(t))
end

function expand(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArrayContract() => expand_contract(t)
    SymbolicNamedDimArraySum() => expand_sum(t)
    SymbolicNamedDimArrayScale() => expand_scale(t)
    _ => t
  end
end

# Covers things like `Number`.
isexpr(x) = false

function isexpr(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArray() => false
    _ => true
  end
end

"""
Substitute the specified subexpression for a new one.
"""
function substitute(t::SymbolicNamedDimArrayExpr, substitutions::AbstractDict)
  haskey(substitutions, t) && return substitutions[t]
  !isexpr(t) && return t
  return map_arguments(a -> substitute(a, substitutions), t)
end

function substitute(t::SymbolicNamedDimArrayExpr, substitutions::AbstractVector)
  return substitute(t, Dict(substitutions))
end

abstract type AbstractContext end

function overdub(ctx::AbstractContext, f, args...)
  return f(args...)
end

function recurse(ctx::AbstractContext, f, args...)
  return overdub(ctx, f, args...)
end

struct DefaultCtx <: AbstractContext end

evaluate(t::SymbolicNamedDimArrayExpr) = recurse(DefaultCtx(), evaluate, t)

# Evaluate the expression, but allow for "overdubbing" the function calls
# in the style of [Cassette.jl](https://github.com/JuliaLabs/Cassette.jl)
# to implement custom functionality.
# See also [GFlops.jl](https://github.com/triscale-innov/GFlops.jl) and
# [CountFlops.jl](https://github.com/charleskawczynski/CountFlops.jl).
function recurse(ctx::AbstractContext, ::typeof(evaluate), t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArray() => t
    SymbolicNamedDimArrayScale() =>
      recurse(ctx, operator(t), coefficient(t), recurse(ctx, evaluate, unscale(t)))
    SymbolicNamedDimArrayContract() || SymbolicNamedDimArraySum() => mapreduce(
      (args...) -> recurse(ctx, evaluate, args...),
      (args...) -> recurse(ctx, operator(t), args...),
      arguments(t),
    )
  end
end

function time_complexity(
  ::typeof(*), t1::SymbolicNamedDimArrayExpr, t2::SymbolicNamedDimArrayExpr
)
  return prod(setdiff(namedsize(t1), namedsize(t2)) ∪ namedsize(t2))
end

function time_complexity(
  ::typeof(+), t1::SymbolicNamedDimArrayExpr, t2::SymbolicNamedDimArrayExpr
)
  @assert issetequal(namedsize(t1), namedsize(t2))
  return prod(size(t1))
end

function time_complexity(::typeof(*), c::Number, t::SymbolicNamedDimArrayExpr)
  return prod(size(t))
end

function time_complexity(::typeof(*), t::SymbolicNamedDimArrayExpr, c::Number)
  return time_complexity(*, c, t)
end

mutable struct TimeComplexityCtx <: AbstractContext
  time_complexity::Int
end
TimeComplexityCtx() = TimeComplexityCtx(0)

function overdub(ctx::TimeComplexityCtx, f::Function, args...)
  ctx.time_complexity += time_complexity(f, args...)
  return f(args...)
end

function time_complexity(t::SymbolicNamedDimArrayExpr)
  ctx = TimeComplexityCtx()
  recurse(ctx, evaluate, t)
  return ctx.time_complexity
end

"""
The space complexity of the expression.
"""
function space_complexity(t::SymbolicNamedDimArrayExpr)
  return error("Not implemented.")
end

"""
Flatten a nested expression down to a flat expression,
removing information about the order of operations.
"""
function flatten_expr(t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArray() || SymbolicNamedDimIdentity() => t
    SymbolicNamedDimArrayScale() => coefficient(t) * flatten_expr(unscale(t))
    SymbolicNamedDimArrayContract() =>
      SymbolicNamedDimArrayContract(flatten_expr.(leaf_arguments(t)))
    SymbolicNamedDimArraySum() => map_arguments(flatten_expr, t)
  end
end

function optimize_flattened_contraction_order(alg, t::SymbolicNamedDimArrayExpr)
  return error("Not implemented.")
end

function optimize_flattened_evaluation_order(alg, t::SymbolicNamedDimArrayExpr)
  @match t begin
    # TODO: Add support for `Identity`.
    SymbolicNamedDimArray() => t
    SymbolicNamedDimArrayScale() =>
      coefficient(t) * optimize_evaluation_order(alg, unscale(t))
    SymbolicNamedDimArrayContract() => optimize_flattened_contraction_order(alg, t)
    # TODO: Identify common subexpressions and optimize only once.
    SymbolicNamedDimArraySum() => map_arguments(a -> optimize_evaluation_order(alg, a), t)
  end
end

function optimize_evaluation_order(alg, t::SymbolicNamedDimArrayExpr)
  return optimize_flattened_evaluation_order(alg, flatten_expr(t))
end

function optimize_evaluation_order(
  t::SymbolicNamedDimArrayExpr; alg=default_optimize_evaluation_order_alg()
)
  return optimize_evaluation_order(alg, t)
end

struct Eager end

default_optimize_evaluation_order_alg() = Eager()

function optimize_flattened_contraction_order(alg::Eager, t::SymbolicNamedDimArrayExpr)
  @assert @match t begin
    SymbolicNamedDimArrayContract() => true
    _ => false
  end
  if (length(arguments(t)) == 1) || (length(arguments(t)) == 2)
    return t
  end
  # TODO: Only search through neighbors instead of all combinations,
  # requires building a graph first.
  a1, a2 = argmin(a -> time_complexity(a[1] * a[2]), combinations(arguments(t), 2))
  return optimize_flattened_contraction_order(
    alg,
    SymbolicNamedDimArrayContract(
      [filter(a -> (a ≠ a1) && (a ≠ a2), arguments(t)); [a1 * a2]]
    ),
  )
end

function isidentity(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimIdentity() => true
    _ => false
  end
end

function replace_dimname_array(t, replacement)
  new_dimnames = replace(dimnames(t), replacement)
  return SymbolicNamedDimArray(name(t), named.(size(t), new_dimnames)...)
end

function replace_dimname_identity(t, replacement)
  new_dimnames = replace(dimnames(t), replacement)
  return SymbolicNamedDimIdentity(named.(size(t), new_dimnames)...)
end

# Replace one named dimension with another one.
function replace_dimname(t::SymbolicNamedDimArrayExpr, replacement::Pair)
  return @match t begin
    SymbolicNamedDimArray() => replace_dimname_array(t, replacement)
    SymbolicNamedDimIdentity() => replace_dimname_identity(t, replacement)
    SymbolicNamedDimArrayScale() =>
      coefficient(t) * replace_dimname(unscale(t), replacement)
    SymbolicNamedDimArrayContract() =>
      map_arguments(a -> replace_dimname(a, replacement), t)
    SymbolicNamedDimArraySum() => map_arguments(a -> replace_dimname(a, replacement), t)
  end
end

function simplify_contract(t)
  simplified_args = copy(arguments(t))
  id_index = findfirst(isidentity, simplified_args)
  # TODO: Make this recursive with a `while` loop,
  # call `findfirst(isidentity, simplified_args)` at
  # the end of the loop to find the next identity.
  while !isnothing(id_index)
    id = simplified_args[id_index]
    # Remove the identity tensor.
    other_args = setdiff(simplified_args, [id])
    for other_arg in other_args
      shared_dimnames = dimnames(id) ∩ dimnames(other_arg)
      if isone(length(shared_dimnames))
        # TODO: Handle logic of contravariant and covariant (dual and non-dual)
        # dimensions/axes, i.e. only allow contracting dual with non-dual.
        # TODO: If the length is 2, this corresponds to a trace, maybe rewrite
        # the expression using a trace or handle that in another special way.
        shared_dimname = only(shared_dimnames)
        id_dimname = only(setdiff(dimnames(id), dimnames(other_arg)))
        # Replace the dimension.
        # TODO: Do this using axes to handle more sophisticated
        # cases like blocked or graded spaces, offset axes, etc.
        other_arg_new = replace_dimname(other_arg, shared_dimname => id_dimname)
        # Replace the tensor with the new tensor where the dimension
        # is replaced.
        simplified_args = replace(other_args, other_arg => other_arg_new)
        break
      end
    end
    id_index = findfirst(isidentity, simplified_args)
  end
  t_simplified = SymbolicNamedDimArrayContract(simplified_args)
  if isone(length(arguments(t_simplified)))
    t_simplified = simplify(only(arguments(t_simplified)))
  end
  if !isexpr(t_simplified)
    return t_simplified
  end
  return map_arguments(simplify, t_simplified)
end

function simplify(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArray() || SymbolicNamedDimIdentity() => t
    SymbolicNamedDimArrayContract() => simplify_contract(t)
    _ => map_arguments(simplify, t)
  end
end

function print_op_arguments(io::IO, f::Function, t)
  print(io, "(")
  for (isfirst, term) in flagfirst(arguments(t))
    !isfirst && print(io, " ", f, " ")
    print(io, term)
  end
  print(io, ")")
  return nothing
end

function Base.show(io::IO, t::SymbolicNamedDimArrayExpr)
  @match t begin
    SymbolicNamedDimArray() || SymbolicNamedDimIdentity() =>
      print(io, name(t), string(dimnames(t)))
    SymbolicNamedDimArrayContract() => print_op_arguments(io, *, t)
    SymbolicNamedDimArraySum() => print_op_arguments(io, +, t)
    SymbolicNamedDimArrayScale() => print(io, coefficient(t), " * ", unscale(t))
  end
end
