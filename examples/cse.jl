module ArrayAwareCSE

using Yolk
import Yolk: allow, YolkOptimizer
using InteractiveUtils
using CodeInfoTools

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
    #x6  = x1 + x2 + x3 + x4 + x5
    #x7  = x1 + x2 + x3 + x4 + x5 + x6
    #x8  = x1 + x2 + x3 + x4 + x5 + x6 + x7
    #x9  = x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8
    #x10 = x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9
    #x11 = x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10
    #x12 = x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11
    return x5
end

# Manual.

th = @methodtheory begin
    a + a => 2 * a
    +(a, b, c) => (a + b) + c
    +(a, b, c, d, e) => (a + b) + (c + d + e)
    a * (b * c) => (a * b) * c
    (k * a) + (n * a) => (k + n) * a
    a + (k::Number * a) => (k + 1) * a
    a::Number * b::Number |> a * b
end
display(th)

allow(::YolkOptimizer, ::typeof(*)) = true
allow(::YolkOptimizer, ::typeof(+)) = true

# Optimize.
src = opt(f, Tuple{Vector{Float64}}; ctx = YolkOptimizer(th), opt = true)
display(src)

end # module
