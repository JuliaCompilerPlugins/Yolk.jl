module SimpleMT

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

t = fold

ex = :(10 + 15)
G = EGraph(ex)
saturate!(G, t)
ex = Metatheory.EGraphs.extract!(G, astsize)
display(ex)

end # module
