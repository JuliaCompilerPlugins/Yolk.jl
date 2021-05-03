module EqualitySaturation

using Yolk
import Yolk: allow, YolkOptimizer

f(x) = begin
    z = (x - x) + (10 * 15)
    y = z + 10
    return y
end

allow(::YolkOptimizer, m) = m == EqualitySaturation
src = opt(f, Float64)
display(src)

end # module
