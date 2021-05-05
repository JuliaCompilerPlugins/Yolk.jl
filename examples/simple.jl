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

# Define theory.
static = @theory begin
    a - a => 0
end

fold = @theory begin
    a::Number + b::Number |> a + b
    a::Number * b::Number |> a * b
    a::Number - b::Number |> a - b
    a::Number / b::Number |> a / b
end

th = fold ∪ static;

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
