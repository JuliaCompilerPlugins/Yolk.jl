module Yolk

using Mixtape
import Mixtape: CompilationContext, allow, preopt!
using CodeInfoTools
using Core.Compiler: Const

using Metatheory
using Metatheory.Library
using Metatheory.EGraphs

@metatheory_init()

struct YolkOptimizer <: CompilationContext end

comm_monoid = commutative_monoid(:(*), 1);

comm_group = @theory begin
    a + 0 => a
    a + b => b + a
    a + inv(a) => 0 # inverse
    a + (b + c) => (a + b) + c
end

distrib = @theory begin
	a * (b + c) => (a * b) + (a * c)
	(a * b) + (a * c) => a * (b + c)
end

powers = @theory begin
	a * a => a^2
	a => a^1
	a^n * a^m => a^(n+m)
end

logids = @theory begin
	log(a^n) => n * log(a)
	log(x * y) => log(x) + log(y)
	log(1) => 0
	log(:e) => 1
	:e^(log(x)) => x
end

fold = @theory begin
	a::Number + b::Number |> a + b
	a::Number * b::Number |> a * b
    a::Number - b::Number |> a - b
    a::Number / b::Number |> a / b
end

t = comm_monoid ∪ comm_group ∪ distrib ∪ powers ∪ logids ∪ fold;

function extract!(ir)
    for i in 1 : length(ir.stmts)
        stmt = ir.stmts[i][:inst]
        if stmt isa Expr
            G = EGraph(stmt)
            saturate!(G, t)
            ex = Metatheory.EGraphs.extract!(G, astsize)
            Core.Compiler.setindex!(ir.stmts[i], ex, :inst)
        end
    end
    return ir
end

function constant_propagation!(ir)
    for i in 1 : length(ir.stmts)
        stmt = ir.stmts[i][:inst]
        if stmt isa Expr && stmt.head === :call
            sig = Core.Compiler.call_sig(ir, stmt)
            f, ft, atypes = sig.f, sig.ft, sig.atypes
            allconst = true
            for atype in sig.atypes
                if !isa(atype, Const)
                    allconst = false
                    break
                end
            end
            if allconst &&
                isa(f, Core.IntrinsicFunction) &&
                is_pure_intrinsic_infer(f) &&
                intrinsic_nothrow(f, atypes[2:end])
                fargs = anymap(x::Const -> x.val, atypes[2:end])
                val = f(fargs...)
                Core.Compiler.setindex!(ir.stmts[i], quoted(val), :inst)
                Core.Compiler.setindex!(ir.stmts[i], Const(val), :type)
            elseif allconst && isa(f, Core.Builtin) && (f === Core.tuple || f === Core.getfield)
                fargs = anymap(x::Const -> x.val, atypes[2:end])
                val = f(fargs...)
                Core.Compiler.setindex!(ir.stmts[i], quoted(val), :inst)
                Core.Compiler.setindex!(ir.stmts[i], Const(val), :type)
            end
        end
    end
    return ir
end

function preopt!(::YolkOptimizer, ir)
    ir = extract!(ir)
    ir = constant_propagation!(ir)
    return ir
end

opt(fn, as...) = emit(fn, Tuple{as...}; 
                      ctx = YolkOptimizer(), opt = true)

export allow, opt, YolkOptimizer

end # module