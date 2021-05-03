module EqualitySaturation

using Yolk
import Yolk: allow, YolkOptimizer

f(x) = begin
    z = (x - x) + (10 * 15)
    y = z + 10
    return y
end

# Define theory.
using Metatheory
using Metatheory.Library
using Metatheory.EGraphs

@metatheory_init()

fold = @theory begin
    a::Number + b::Number |> a + b
    a::Number * b::Number |> a * b
    a::Number - b::Number |> a - b
    a::Number / b::Number |> a / b
end

th = fold;

# Optimize.
src = opt(f, Tuple{Float64}; ctx = YolkOptimizer(th), opt = false)
display(src)
src = opt(f, Tuple{Float64}; ctx = YolkOptimizer(th), opt = true)
display(src)

end # module
