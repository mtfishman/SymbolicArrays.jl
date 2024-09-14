@eval module $(gensym())
using Aqua: Aqua
using Moshi.Match: @match
using SymbolicArrays:
  SymbolicArrays,
  SymbolicArray,
  SymbolicNamedDimArray,
  SymbolicNamedDimArrayContract,
  SymbolicNamedDimArrayScale,
  SymbolicNamedDimArraySum,
  arguments,
  coefficient,
  dimnames,
  expand,
  flatten_expression,
  leaf_arguments,
  time_complexity,
  unscale
using Test: @test, @test_broken, @test_throws, @testset

@testset "SymbolicArrays.jl" begin
  @testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(SymbolicArrays)
  end
  @testset "README" begin
    include(joinpath(pkgdir(SymbolicArrays), "examples", "README.jl"))
  end
  @testset "Basics" begin
    a = SymbolicArray(:a, 2, 2)
    b = SymbolicArray(:b, 2, 2)
    c = SymbolicArray(:c, 2, 2)
    i, j, k, l, m = :i, :j, :k, :l, :m

    @test size(a(i, j)) == [2, 2]
    @test dimnames(a(i, j)) == [:i, :j]
    @test @match a(i, j) begin
      SymbolicNamedDimArray() => true
      _ => false
    end
    @test isone(coefficient(a(i, j)))
    @test isone(coefficient(a(i, j), a(i, j)))
    @test a(i, j) == a(i, j)
    @test a(i, j) == 1 * a(i, j)
    @test 1 * a(i, j) == a(i, j)

    r = a(i, j) * a(j, k)
    @test size(r) == [2, 2]
    @test dimnames(r) == [:i, :k]
    @test @match r begin
      SymbolicNamedDimArrayContract() => true
      _ => false
    end
    @test issetequal(arguments(r), [a(i, j), a(j, k)])
    @test isone(coefficient(r, r))

    r = a(i, j) * a(j, k) * a(k, l)
    @test size(r) == [2, 2]
    @test dimnames(r) == [:i, :l]
    @test issetequal(arguments(r), [a(i, j) * a(j, k), a(k, l)])
    @test issetequal(leaf_arguments(r), [a(i, j), a(j, k), a(k, l)])
    @test arguments(r)[1] == a(i, j) * a(j, k)
    @test arguments(r)[2] == a(k, l)
    @test isone(coefficient(r, r))

    r = 2 * a(i, j)
    @test size(r) == [2, 2]
    @test dimnames(r) == [:i, :j]
    @test @match r begin
      SymbolicNamedDimArrayScale() => true
      _ => false
    end
    @test unscale(r) == a(i, j)
    @test coefficient(r) == 2
    @test coefficient(r, a(i, j)) == 2

    r = a(i, j) / 2
    @test size(r) == [2, 2]
    @test dimnames(r) == [:i, :j]
    @test @match r begin
      SymbolicNamedDimArrayScale() => true
      _ => false
    end
    @test unscale(r) == a(i, j)
    @test coefficient(r) ≈ inv(2)
    @test coefficient(r, a(i, j)) ≈ inv(2)

    r = -a(i, j)
    @test size(r) == [2, 2]
    @test dimnames(r) == [:i, :j]
    @test @match r begin
      SymbolicNamedDimArrayScale() => true
      _ => false
    end
    @test unscale(r) == a(i, j)
    @test coefficient(r) ≈ -1
    @test coefficient(r, a(i, j)) ≈ -1

    r = 3 * (2 * a(i, j))
    @test size(r) == [2, 2]
    @test dimnames(r) == [:i, :j]
    @test @match r begin
      SymbolicNamedDimArrayScale() => true
      _ => false
    end
    @test unscale(r) == a(i, j)
    @test coefficient(r) == 6
    @test coefficient(r, a(i, j)) == 6

    α = 3
    for r in (α * a(i, j) * a(j, k), a(i, j) * α * a(j, k), a(i, j) * a(j, k) * α)
      @test size(r) == [2, 2]
      @test dimnames(r) == [:i, :k]
      @test @match r begin
        SymbolicNamedDimArrayScale(; term::SymbolicNamedDimArrayContract()) => true
        _ => false
      end
      @test coefficient(r) == α
      x = unscale(r)
      @test unscale(x) == a(i, j) * a(j, k)
      @test issetequal(arguments(x), [a(i, j), a(j, k)])
      @test coefficient(r, a(i, j) * a(j, k)) == α
    end

    r = a(i, j) + b(i, j)
    @test issetequal(arguments(r), [a(i, j), b(i, j)])
    @test @match r begin
      SymbolicNamedDimArraySum() => true
      _ => false
    end
    @test isone(coefficient(r, a(i, j)))
    @test isone(coefficient(r, b(i, j)))

    r = a(i, j) + b(i, j) - b(i, j)
    @test issetequal(arguments(r), [1 * a(i, j), 0 * b(i, j)])
    @test issetequal(arguments(r), [a(i, j), 0 * b(i, j)])
    @test @match r begin
      SymbolicNamedDimArraySum() => true
      _ => false
    end
    @test isone(coefficient(r, a(i, j)))
    @test iszero(coefficient(r, b(i, j)))

    r = a(i, j) + a(i, j)
    @test r == 2a(i, j)
    @test coefficient(r) == 2
    @test unscale(r) == a(i, j)
    @test @match r begin
      SymbolicNamedDimArrayScale() => true
      _ => false
    end
    @test coefficient(r, a(i, j)) == 2

    r = a(i, j) - a(i, j)
    @test r == 0a(i, j)
    @test iszero(coefficient(r))
    @test unscale(r) == a(i, j)
    @test @match r begin
      SymbolicNamedDimArrayScale() => true
      _ => false
    end
    @test iszero(coefficient(r, a(i, j)))

    @test_throws ErrorException a(i, j) + a(j, k)

    r = a(i, j) * a(j, k) + a(i, k)
    @test @match r begin
      SymbolicNamedDimArraySum() => true
      _ => false
    end
    @test isone(coefficient(r, a(i, j) * a(j, k)))
    @test isone(coefficient(r, a(i, k)))

    r = 2 * (a(i, j) * a(j, k) + a(i, k))
    @test @match r begin
      SymbolicNamedDimArraySum() => true
      _ => false
    end
    @test coefficient(r, a(i, j) * a(j, k)) == 2
    @test coefficient(r, a(i, k)) == 2

    # Regression test for summing more than 2 terms.
    r = a(i, j) + b(i, j) + c(i, j)
    @test @match r begin
      SymbolicNamedDimArraySum() => true
      _ => false
    end
    @test isone(coefficient(r, a(i, j)))
    @test isone(coefficient(r, b(i, j)))
    @test isone(coefficient(r, c(i, j)))

    @test 1 * a(i, j) * a(j, k) == a(i, j) * a(j, k)

    r = a(i, j) * a(j, k) + (a(i, j) + b(i, j)) * a(j, k)
    # TODO: Leaving off the coefficient in the second argument
    # of the sum leads to an error, investigate and fix.
    @test expand(r) == 2 * a(i, j) * a(j, k) + b(i, j) * a(j, k)
    @test expand(r) == 2 * a(i, j) * a(j, k) + 1 * b(i, j) * a(j, k)

    r = (a(i, j) + b(i, j)) * ((a(j, k) + b(j, k)) * a(k, l))
    @test expand(r) ==
      a(i, j) * (a(j, k) * a(k, l)) +
          a(i, j) * (b(j, k) * a(k, l)) +
          b(i, j) * (a(j, k) * a(k, l)) +
          b(i, j) * (b(j, k) * a(k, l))

    r = (a(i, j) * a(j, k)) * (a(k, l) * (a(l, m) + b(l, m)))
    @test expand(r) ==
      (a(i, j) * a(j, k)) * (a(k, l) * a(l, m)) +
          (a(i, j) * a(j, k)) * (a(k, l) * b(l, m))

    r = a(i, j) * a(j, k) * a(k, l)
    r = flatten_expression(r)
    @test @match r begin
      SymbolicNamedDimArrayContract() => true
      _ => false
    end
    @test issetequal(arguments(r), [a(i, j), a(j, k), a(k, l)])

    r = a(i, j) * a(j, k)
    @test time_complexity(r) == 8

    r = a(i, j) + a(i, j)
    @test time_complexity(r) == 4

    r = 3 * a(i, j)
    @test time_complexity(r) == 4

    r = a(i, j) + b(i, j)
    @test time_complexity(r) == 4

    r = a(i, j) * a(j, k) * a(k, l)
    @test time_complexity(r) == 16
  end
end
end
