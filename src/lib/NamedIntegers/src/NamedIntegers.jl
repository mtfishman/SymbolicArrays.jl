module NamedIntegers
using AutoHashEquals: @auto_hash_equals

struct Name{Value}
  value::Value
end
unname(n::Name) = getfield(n, :value)
Base.:(==)(n1::Name, n2::Name) = unname(n1) == unname(n2)
Base.:(==)(n1::Name, n2) = unname(n1) == n2
Base.:(==)(n1, n2::Name) = n1 == unname(n2)

# Fix ambiguity issues.
Base.:(==)(n1::Name, n2::Missing) = unname(n1) == n2
Base.:(==)(n1::Missing, n2::Name) = n1 == unname(n2)
Base.:(==)(n1::Name, n2::WeakRef) = unname(n1) == n2
Base.:(==)(n1::WeakRef, n2::Name) = n1 == unname(n2)

@auto_hash_equals struct NamedInteger{Value<:Integer,Name} <: Integer
  value::Value
  name::Name
end
unname(ni::NamedInteger) = getfield(ni, :value)
unname(::Type{<:NamedInteger{Value}}) where {Value} = Value
name(ni::NamedInteger) = getfield(ni, :name)
named(value::Integer, name) = NamedInteger(value, name)

named_construct_integer(type::Type{<:Integer}, ni::NamedInteger) = type(unname(ni))
(type::Type{<:Integer})(ni::NamedInteger) = named_construct_integer(type, ni)
# Fix ambiguity errors.
Base.Integer(ni::NamedInteger) = named_construct_integer(Integer, ni)
Base.Bool(ni::NamedInteger) = named_construct_integer(Bool, ni)
Base.GMP.BigInt(ni::NamedInteger) = named_construct_integer(BigInt, ni)

Base.:*(ni1::NamedInteger, ni2::NamedInteger) = unname(ni1) * unname(ni2)
function Base.promote_rule(type1::Type{<:NamedInteger}, type2::Type{<:Integer})
  return promote_type(unname(type1), type2)
end
end
