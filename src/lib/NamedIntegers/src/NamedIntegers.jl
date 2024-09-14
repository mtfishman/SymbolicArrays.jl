module NamedIntegers
using AutoHashEquals: @auto_hash_equals
@auto_hash_equals struct NamedInteger{Value<:Integer,Name} <: Integer
  value::Value
  name::Name
end
unname(ni::NamedInteger) = ni.value
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
