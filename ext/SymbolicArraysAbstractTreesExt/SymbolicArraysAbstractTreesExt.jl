module SymbolicArraysAbstractTreesExt
using AbstractTrees: AbstractTrees
using Moshi.Match: @match
using SymbolicArrays:
  SymbolicNamedDimArray,
  SymbolicNamedDimArrayContract,
  SymbolicNamedDimArrayExpr,
  SymbolicNamedDimArrayScale,
  SymbolicNamedDimArraySum,
  SymbolicNamedDimIdentity,
  arguments,
  coefficient,
  unscale

function AbstractTrees.children(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArray() => ()
    _ => arguments(t)
  end
end

function AbstractTrees.nodevalue(t::SymbolicNamedDimArrayExpr)
  return @match t begin
    SymbolicNamedDimArray() || SymbolicNamedDimIdentity() => t
    SymbolicNamedDimArrayContract() || SymbolicNamedDimArrayScale() => *
    SymbolicNamedDimArraySum() => +
  end
end
end
