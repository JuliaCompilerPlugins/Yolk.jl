module EqualitySaturation

using Yolk
import Yolk: allow, YolkOptimizer
using InteractiveUtils

using Metatheory
using Metatheory.Library
using Metatheory.EGraphs

using BenchmarkTools

@metatheory_init()

#####
##### Exceedingly simple.
#####

f(x) = begin
    z = (x - x) + (10 * 15)
    y = z + 10
    return y
end

#####
##### Define theory.
#####

# Automatic.
fold = @theory begin
    Base.:(+)(a::Number, b::Number) |> a + b
end
display(fold)

# Manual.
th = []
left = Metatheory.PatTerm(:call, [PatLiteral(Base.:(-)), PatVar(:a), PatVar(:a)])
right = Metatheory.PatLiteral(0)
new = Metatheory.RewriteRule(left, right)
push!(th, new)
left = Metatheory.PatTerm(:call, [PatLiteral(Base.:(+)), PatTypeAssertion(PatVar(:a), Number), PatTypeAssertion(PatVar(:b), Number)])
right =  fold[1].right
new = Metatheory.DynamicRule(left, right)
push!(th, new)
left = Metatheory.PatTerm(:call, [PatLiteral(Base.:(*)), PatTypeAssertion(PatVar(:a), Number), PatTypeAssertion(PatVar(:b), Number)])
new = Metatheory.DynamicRule(left, Expr(:call, Base.:(*), :a, :b))
push!(th, new)
display(th)

# Optimize.
println("Pre-opt:")
src = opt(f, Tuple{Int}; ctx = YolkOptimizer(th), opt = false)
display(src)
println("Julia native opt:")
src = opt(f, Tuple{Int}; ctx = YolkOptimizer(th, false), opt = true)
display(src)
println("(Metatheory) + Julia native opt:")
src = opt(f, Tuple{Int}; ctx = YolkOptimizer(th), opt = true)
display(src)
end # module
