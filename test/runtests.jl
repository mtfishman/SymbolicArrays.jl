using Aqua: Aqua
using Moshi.Match: @match
using SymbolicArrays:
  SymbolicArrays,
  SymbolicArray,
  TensorExpr,
  arguments,
  coefficient,
  coefficients,
  dimnames,
  leaf_arguments,
  unscale
using Test: @test, @test_throws, @testset

@testset "SymbolicArrays.jl" begin
  @testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(SymbolicArrays)
  end
  a = SymbolicArray(:a, 2, 2)
  b = SymbolicArray(:b, 2, 2)
  i, j, k, l = :i, :j, :k, :l

  @test size(a(i, j)) == [2, 2]
  @test dimnames(a(i, j)) == [:i, :j]
  @test @match a(i, j) begin
    TensorExpr.Tensor() => true
    _ => false
  end
  @test isone(coefficient(a(i, j)))
  @test isone(coefficients(a(i, j))[a(i, j)])
  @test a(i, j) == a(i, j)
  @test a(i, j) == 1 * a(i, j)
  @test 1 * a(i, j) == a(i, j)

  r = a(i, j) * a(j, k)
  @test size(r) == [2, 2]
  @test dimnames(r) == [:i, :k]
  @test @match r begin
    TensorExpr.Contract() => true
    _ => false
  end
  @test issetequal(arguments(r), [a(i, j), a(j, k)])
  @test isone(coefficients(r)[r])

  r = a(i, j) * a(j, k) * a(k, l)
  @test size(r) == [2, 2]
  @test dimnames(r) == [:i, :l]
  @test issetequal(arguments(r), [a(i, j) * a(j, k), a(k, l)])
  @test issetequal(leaf_arguments(r), [a(i, j), a(j, k), a(k, l)])
  @test arguments(r)[1] == a(i, j) * a(j, k)
  @test arguments(r)[2] == a(k, l)
  @test isone(coefficients(r)[r])

  r = 2 * a(i, j)
  @test size(r) == [2, 2]
  @test dimnames(r) == [:i, :j]
  @test @match r begin
    TensorExpr.Scale() => true
    _ => false
  end
  @test unscale(r) == a(i, j)
  @test coefficient(r) == 2
  @test coefficients(r)[a(i, j)] == 2

  r = 3 * (2 * a(i, j))
  @test size(r) == [2, 2]
  @test dimnames(r) == [:i, :j]
  @test @match r begin
    TensorExpr.Scale() => true
    _ => false
  end
  @test unscale(r) == a(i, j)
  @test coefficient(r) == 6
  @test coefficients(r)[a(i, j)] == 6

  c = 3
  for r in (c * a(i, j) * a(j, k), a(i, j) * c * a(j, k), a(i, j) * a(j, k) * c)
    @test size(r) == [2, 2]
    @test dimnames(r) == [:i, :k]
    @test @match r begin
      TensorExpr.Scale(; term::TensorExpr.Contract()) => true
      _ => false
    end
    @test coefficient(r) == c
    x = unscale(r)
    @test unscale(x) == a(i, j) * a(j, k)
    @test issetequal(arguments(x), [a(i, j), a(j, k)])
    @test last(only(coefficients(r))) == c
    @test coefficients(r)[a(i, j) * a(j, k)] == c
  end

  r = a(i, j) + b(i, j)
  @test issetequal(arguments(r), [a(i, j), b(i, j)])
  @test @match r begin
    TensorExpr.Sum() => true
    _ => false
  end
  @test isone(coefficients(r)[a(i, j)])
  @test isone(coefficients(r)[b(i, j)])

  r = a(i, j) + a(i, j)
  @test r == 2 * a(i, j)
  @test coefficient(r) == 2
  @test unscale(r) == a(i, j)
  @test @match r begin
    TensorExpr.Scale() => true
    _ => false
  end
  @test coefficients(r)[a(i, j)] == 2

  @test_throws ErrorException a(i, j) + a(j, k)

  r = a(i, j) * a(j, k) + a(i, k)
  @test @match r begin
    TensorExpr.Sum() => true
    _ => false
  end
  @test isone(coefficients(r)[a(i, j) * a(j, k)])
  @test isone(coefficients(r)[a(i, k)])

  r = 2 * (a(i, j) * a(j, k) + a(i, k))
  @test @match r begin
    TensorExpr.Sum() => true
    _ => false
  end
  @test coefficients(r)[a(i, j) * a(j, k)] == 2
  @test coefficients(r)[a(i, k)] == 2

  # TODO: Test `expand`.
  # TODO: Test adding term to sum (sum involving three terms).
end
