using Aqua: Aqua
using SymbolicArrays.BaseExtensions: BaseExtensions
using Test: @test, @testset

@testset "BaseExtensions.jl" begin
  @testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(BaseExtensions)
  end
  # Write your tests here.
end
