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

(type::Type{<:Integer})(ni::NamedInteger) = type(unname(ni))

Base.:*(ni1::NamedInteger, ni2::NamedInteger) = unname(ni1) * unname(ni2)
function Base.promote_rule(type1::Type{<:NamedInteger}, type2::Type{<:Integer})
  return promote_type(unname(type1), type2)
end
end
