module BaseExtensions
"""
Extension of `map` that works for Dict and Set.
"""
generic_map(f, v) = map(f, v)
generic_map(f, v::AbstractDict) = Dict(eachindex(v) .=> map(f, values(v)))
generic_map(f, v::AbstractSet) = Set([f(x) for x in v])
end
