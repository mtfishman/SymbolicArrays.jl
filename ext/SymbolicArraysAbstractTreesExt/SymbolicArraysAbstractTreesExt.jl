module SymbolicArraysAbstractTreesExt
using AbstractTrees: AbstractTrees
using Moshi.Match: @match
using SymbolicArrays: TensorExpr, arguments, coefficient, unscale

function AbstractTrees.children(t::TensorExpr.Type)
  return @match t begin
    TensorExpr.Tensor() => ()
    _ => arguments(t)
  end
end

function AbstractTrees.nodevalue(t::TensorExpr.Type)
  return @match t begin
    TensorExpr.Tensor() => t
    TensorExpr.Contract() || TensorExpr.Scale() => *
    TensorExpr.Sum() => +
  end
end
end
