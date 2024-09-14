using .NamedIntegers: name, named

"""
A symbolic array, without dimension names.
"""
struct SymbolicArray{T,N,Name} <: AbstractArray{T,N}
  name::Name
  size::NTuple{N,Int}
end
const SymbolicVector{T,Name} = SymbolicArray{T,1,Name}
const SymbolicMatrix{T,Name} = SymbolicArray{T,2,Name}
function SymbolicArray(name, size::Integer...)
  return SymbolicArray{Any,length(size),typeof(name)}(name, size)
end
Base.size(a::SymbolicArray) = getfield(a, :size)
NamedIntegers.name(a::SymbolicArray) = getfield(a, :name)
function Base.show(io::IO, a::SymbolicArray)
  summary(io, a)
  print(io, ":\n", name(a))
  return nothing
end
function Base.show(io::IO, mime::MIME"text/plain", a::SymbolicArray)
  return show(io, a)
end

# TODO: Move to `SymbolicArraysSymbolicTensorsExt`.
function (a::SymbolicArray)(dimnames...)
  @assert ndims(a) == length(dimnames)
  return SymbolicNamedDimArray(name(a), named.(size(a), collect(dimnames)))
end
