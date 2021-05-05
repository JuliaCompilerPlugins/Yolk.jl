module ArrayAwareCSE

using Yolk
import Yolk: allow, YolkOptimizer
using InteractiveUtils

using Metatheory
using Metatheory.Library
using Metatheory.EGraphs

using BenchmarkTools

@metatheory_init()

#####
##### Array-aware CSE.
#####

using LinearAlgebra

function f(x1::Vector{Float64})
    x2  = x1
    x3  = x1 + x2
    x4  = x1 + x2 + x3
    x5  = x1 + x2 + x3 + x4
    x6  = x1 + x2 + x3 + x4 + x5
    x7  = x1 + x2 + x3 + x4 + x5 + x6
    x8  = x1 + x2 + x3 + x4 + x5 + x6 + x7
    x9  = x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8
    x10 = x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9
    x11 = x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10
    x12 = x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11
    return x12
end

static = @theory begin
    a::Vector + a::Vector => 2 * a
end

th = static

# Optimize.
println("Pre-opt:")
src = opt(f, Tuple{Vector{Float64}}; ctx = YolkOptimizer(th), opt = false)
display(src)
println("Julia native opt:")
src = opt(f, Tuple{Vector{Float64}}; ctx = YolkOptimizer(th, false), opt = true)
display(src)
fn = opt(f, Tuple{Vector{Float64}}; emit_callable = true,
          ctx = YolkOptimizer(th, false), opt = true)
@assert(f([1.0, 1.0]) == fn([1.0, 1.0]))
println("(Metatheory) + Julia native opt:")
src = opt(f, Tuple{Vector{Float64}}; ctx = YolkOptimizer(th), opt = true)
display(src)

end # module
