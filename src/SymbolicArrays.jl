module SymbolicArrays
include("lib/BaseExtensions/src/BaseExtensions.jl")
using .BaseExtensions: BaseExtensions
include("lib/NamedIntegers/src/NamedIntegers.jl")
using .NamedIntegers: NamedIntegers
include("symbolicarray.jl")
include("symbolicnameddimarray.jl")
end
