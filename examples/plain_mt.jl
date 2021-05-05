module PlainMT

using Metatheory
using Metatheory.Library
using Metatheory.EGraphs

@metatheory_init()

static = @theory begin
    a + a => 2 * a
    a * (b * c) => (a * b) * c
end

dump(static[2])

dynamic = @theory begin
    a::Number * b::Number |> a * b
end

t = static ∪ dynamic

ex = Expr(:call, :+, 2, 2, Expr(:call, :*, 2, QuoteNode(:q)))
G = EGraph(ex)
saturate!(G, t)
ex = Metatheory.EGraphs.extract!(G, astsize)
display(ex)

end # module
