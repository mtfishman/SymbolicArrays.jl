using ..BaseExtensions: generic_map
using IterTools: flagfirst
using Moshi.Data: @data, variant_fieldnames, variant_type
using Moshi.Match: @match
using ..NamedIntegers: NamedIntegers, NamedInteger, name, named, unname

# TODO: Parametrize by Tensor name, namedsize, coefficient
# types, etc.
@data TensorExpr begin
  struct Tensor
    name::Any
    namedsize::Vector{NamedInteger}
  end
  struct Contract
    arguments::Vector{TensorExpr}
    leaf_arguments::Vector{TensorExpr}
    namedsize::Vector{NamedInteger}
  end
  struct Sum
    arguments::Set{TensorExpr}
    coefficients::Dict{TensorExpr,Number}
    namedsize::Vector{NamedInteger}
  end
  struct Scale
    coefficient::Number
    term::TensorExpr
  end
end

function NamedIntegers.name(t::TensorExpr.Type)
  @match t begin
    TensorExpr.Tensor(; name) => name
    _ => error("No name.")
  end
end

# Determine the named size from the arguments of
# a sum, either the first argument or empty
# if there are no arguments.
function namedsize_sum_arguments(arguments)
  isempty(arguments) && return NamedInteger[]
  return namedsize(first(arguments))
end

"""
Sum based on arguments.
"""
function TensorExpr.Sum(arguments::Set{TensorExpr.Type})
  coefficients = Dict((unscale(term) => coefficient(term) for term in arguments))
  namedsize = namedsize_sum_arguments(arguments)
  return TensorExpr.Sum(; arguments, coefficients, namedsize)
end

# TODO: This overwrite a method in Moshi.jl, check if This
# needs to be defined.
# TensorExpr.Sum() = TensorExpr.Sum(Set{TensorExpr.Type}())

"""
Sum based on arguments.
"""
function TensorExpr.Sum(coefficients::Dict{TensorExpr.Type,<:Number})
  arguments = Set([coefficients[unscale] * unscale for unscale in eachindex(coefficients)])
  namedsize = namedsize_sum_arguments(arguments)
  return TensorExpr.Sum(; arguments, coefficients, namedsize)
end

function namedsize(t::TensorExpr.Type)
  @match t begin
    TensorExpr.Tensor(; namedsize) => namedsize
    TensorExpr.Contract(; namedsize) => namedsize
    TensorExpr.Sum() => namedsize_sum_arguments(arguments(t))
    TensorExpr.Scale(; term) => namedsize(term)
  end
end

function Base.size(t::TensorExpr.Type)
  return unname.(namedsize(t))
end

function dimnames(t::TensorExpr.Type)
  return name.(namedsize(t))
end

"""
The (tensor) arguments of a tensor contraction or sum.
"""
function arguments(t::TensorExpr.Type)
  @match t begin
    TensorExpr.Tensor() => [t]
    TensorExpr.Contract(; arguments) => arguments
    TensorExpr.Sum(; arguments) => arguments
    TensorExpr.Scale(; term) => arguments(term)
  end
end

"""
The leaf (tensor) arguments of a nested tensor contraction or sum.
"""
function leaf_arguments(t::TensorExpr.Type)
  @match t begin
    TensorExpr.Tensor() => [t]
    TensorExpr.Contract(; leaf_arguments) => leaf_arguments
    TensorExpr.Sum(; arguments) => arguments
    TensorExpr.Scale(; term) => arguments(term)
  end
end

"""
The (tensor) arguments of a tensor contraction.
"""
function arguments_contract(t::TensorExpr.Type)
  @match t begin
    TensorExpr.Contract(; arguments) => arguments
    _ => [t]
  end
end

"""
The (tensor) arguments of a tensor sum.
"""
function arguments_sum(t::TensorExpr.Type)
  @match t begin
    TensorExpr.Sum(; arguments) => arguments
    _ => Set([t])
  end
end

function coefficient(t::TensorExpr.Type)
  return @match t begin
    TensorExpr.Scale(; coefficient) => coefficient
    TensorExpr.Tensor() || TensorExpr.Contract() => 1
    TensorExpr.Sum() => coefficient(only(arguments(t)))
  end
end

function coefficients(t::TensorExpr.Type)
  return @match t begin
    TensorExpr.Sum(; coefficients) => coefficients
    _ => Dict(unscale(t) => coefficient(t))
  end
end

function unscale(t::TensorExpr.Type)
  return @match t begin
    TensorExpr.Tensor() => t
    TensorExpr.Contract() => t
    TensorExpr.Sum() => t
    TensorExpr.Scale(; term) => term
  end
end

# Contract two tensors/tensor networks together.
function contract_tensors(t1, t2)
  expr = [t1, t2]
  res_arguments = [arguments_contract(t1); arguments_contract(t2)]
  return TensorExpr.Contract(expr, res_arguments, symdiff(namedsize(t1), namedsize(t2)))
end

function Base.:*(t1::TensorExpr.Type, t2::TensorExpr.Type)
  res_namedsize = symdiff(namedsize(t1), namedsize(t2))
  @match t1, t2 begin
    (TensorExpr.Scale(), _) => coefficient(t1) * (unscale(t1) * t2)
    (_, TensorExpr.Scale()) => coefficient(t2) * (t1 * unscale(t2))
    (_, _) => contract_tensors(t1, t2)
  end
end

function Base.:*(c::Number, t::TensorExpr.Type)
  return @match t begin
    TensorExpr.Sum() => TensorExpr.Sum(generic_map(term -> c * term, arguments(t)))
    TensorExpr.Scale() => c * coefficient(t) * unscale(t)
    _ => TensorExpr.Scale(c, t)
  end
end

function add_tensor_sum(t1, t2)
  c1 = coefficient(t1)
  ut1 = unscale(t1)
  c2 = coefficient.(arguments(t2))
  return ut2 = unscale.(arguments(t2))
end

# Assumes scalar multiplication is commutative.
# TODO: Make a definition which accounts for numbers that
# don't have commutative multiplication.
function Base.:*(t::TensorExpr.Type, c::Number)
  return c * t
end

function isequal_tensors(t1, t2)
  return name(t1) == name(t2) && namedsize(t1) == namedsize(t2)
end

function isequal_arguments(t1, t2)
  return leaf_arguments(t1) == leaf_arguments(t2)
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

function Base.:(==)(t1::TensorExpr.Type, t2::TensorExpr.Type)
  return @match (t1, t2) begin
    (TensorExpr.Tensor(), TensorExpr.Tensor()) => isequal_tensors(t1, t2)
    (TensorExpr.Scale(), _) => isequal_scales(t1, t2)
    (_, TensorExpr.Scale()) => isequal_scales(t1, t2)
    (TensorExpr.Contract(), TensorExpr.Contract()) => isequal_arguments(t1, t2)
    (TensorExpr.Sum(), TensorExpr.Sum()) => isequal_arguments(t1, t2)
    (_, _) => isequal_single_argument(t1, t2)
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

function Base.hash(t::TensorExpr.Type, h::UInt)
  return @match t begin
    TensorExpr.Tensor() => hash_tensor(t, h)
    TensorExpr.Scale() => hash_tensor(t, h)
    TensorExpr.Contract() => hash_contract_or_sum(t, h)
    TensorExpr.Sum() => hash_contract_or_sum(t, h)
  end
end

function add_sums(t1, t2)
  return TensorExpr.Sum(mergewith(+, coefficients(t1), coefficients(t2)))
end

function Base.:+(t1::TensorExpr.Type, t2::TensorExpr.Type)
  dimnames(t1) == dimnames(t2) || throw(ErrorException("Dimension names must match."))
  # TODO: Handle when t1 == t2 (combine into arguments with coefficients), combining sums, etc.
  return @match (t1, t2) begin
    (TensorExpr.Sum(), TensorExpr.Sum()) => add_sums(t1, t2)
    (TensorExpr.Sum(), _) => t1 + TensorExpr.Sum(Set([t2]))
    (_, TensorExpr.Sum()) => TensorExpr.Sum(Set([t1])) + t2
    (t, t) => 2t
    _ => TensorExpr.Sum(Set([t1, t2]))
  end
end

function expand_arguments_sums(t1, t2)
  return mapreduce(splat(*), +, Iterators.product(arguments(t1), arguments(t2)))
end

function expand_arguments(t1::TensorExpr.Type, t2::TensorExpr.Type)
  @match t1, t2 begin
    (TensorExpr.Sum(), TensorExpr.Sum()) => expand_arguments_sums(t1, t2)
    (TensorExpr.Sum(), _) => TensorExpr.Sum(generic_map(a1 -> a1 * t2, arguments(t1)))
    (_, TensorExpr.Sum()) => TensorExpr.Sum(generic_map(a2 -> t1 * a2, arguments(t2)))
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

function expand(t::TensorExpr.Type)
  @match t begin
    TensorExpr.Contract() => expand_contract(t)
    TensorExpr.Sum() => expand_sum(t)
    TensorExpr.Scale() => expand_scale(t)
    _ => t
  end
end

function substitute(t::TensorExpr.Type)
  @match t begin
    TensorExpr.Contract() => expand_contract(t)
    TensorExpr.Sum() => expand_sum(t)
    TensorExpr.Scale() => expand_scale(t)
    _ => t
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

function square_to_round_brackets(s::AbstractString)
  return replace(s, "[" => "(", "]" => ")")
end

function Base.show(io::IO, t::TensorExpr.Type)
  @match t begin
    TensorExpr.Tensor() => print(io, name(t), square_to_round_brackets(string(dimnames(t))))
    TensorExpr.Contract() => print_op_arguments(io, *, t)
    TensorExpr.Sum() => print_op_arguments(io, +, t)
    TensorExpr.Scale() => print(io, coefficient(t), " * ", unscale(t))
  end
end
