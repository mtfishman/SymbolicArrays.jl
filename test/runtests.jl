using SymbolicArrays
using Test
using Aqua

@testset "SymbolicArrays.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(SymbolicArrays)
    end
    # Write your tests here.
end
