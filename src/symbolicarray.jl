using .NamedIntegers: NamedIntegers, name, named

abstract type AbstractSymbolicArray{T,N,Name} <: AbstractArray{T,N} end
const AbstractSymbolicVector{T,Name} = AbstractSymbolicArray{T,1,Name}
const AbstractSymbolicMatrix{T,Name} = AbstractSymbolicArray{T,2,Name}
function Base.show(io::IO, a::AbstractSymbolicArray)
  summary(io, a)
  print(io, ":\n", name(a))
  return nothing
end
function Base.show(io::IO, mime::MIME"text/plain", a::AbstractSymbolicArray)
  return show(io, a)
end

"""
A symbolic array, without dimension names.
"""
struct SymbolicArray{T,N,Name} <: AbstractSymbolicArray{T,N,Name}
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

struct SymbolicIdentity{T} <: AbstractSymbolicMatrix{T,Any}
  domain_length::Int
end
# const Id{T} = SymbolicIdentity{T}
SymbolicIdentity(domain_length::Int) = SymbolicIdentity{Any}(domain_length)
function Base.size(a::SymbolicIdentity)
  n = getfield(a, :domain_length)
  return (n, n)
end
NamedIntegers.name(a::SymbolicIdentity) = :Id

struct SymbolicIsometry{T,N,Name,Ncodomain,Ndomain} <: AbstractSymbolicArray{T,N,Name}
  name::Name
  codomain_size::NTuple{Ncodomain,Int}
  domain_size::NTuple{Ndomain,Int}
end
