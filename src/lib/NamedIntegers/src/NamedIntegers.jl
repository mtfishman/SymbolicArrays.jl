module NamedIntegers
using AutoHashEquals: @auto_hash_equals
@auto_hash_equals struct NamedInteger{Value<:Integer,Name} <: Integer
  value::Value
  name::Name
end
unname(n::NamedInteger) = n.value
name(n::NamedInteger) = n.name
named(value::Integer, name) = NamedInteger(value, name)
end
