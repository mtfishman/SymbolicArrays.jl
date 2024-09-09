using Aqua: Aqua
using SymbolicArrays.NamedIntegers: NamedIntegers
using Test: @test, @testset

@testset "NamedIntegers.jl" begin
  @testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(NamedIntegers)
  end
  # Write your tests here.
end
