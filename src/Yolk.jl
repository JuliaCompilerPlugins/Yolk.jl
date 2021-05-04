module Yolk

using Mixtape
import Mixtape: CompilationContext, allow, optimize!
using CodeInfoTools
using Core.Compiler: Const, is_pure_intrinsic_infer, intrinsic_nothrow, anymap, quoted

using Metatheory
using Metatheory.Library
using Metatheory.EGraphs

@metatheory_init()

struct YolkOptimizer <: CompilationContext
    theory::Vector{Rule}
    YolkOptimizer(t) = new(t)
    YolkOptimizer() = new(Rule[])
end
allow(::YolkOptimizer, m::Module, args...) = true

function extract!(ir, theory)
    for i in 1 : length(ir.stmts)
        stmt = ir.stmts[i][:inst]
        if stmt isa Expr
            G = EGraph(stmt)
            saturate!(G, theory)
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

function optimize!(ctx::YolkOptimizer, b)
    ir = get_ir(b)
    ir = extract!(ir, ctx.theory)
    ir = constant_propagation!(ir)
    ir = julia_passes!(ir, b.sv.src, b.sv)
    return ir
end

function opt(fn, tt::Type{T};
        ctx = YolkOptimizer(), opt = true) where T <: Tuple
    return emit(fn, tt; ctx = ctx, opt = opt)
end

export opt, YolkOptimizer

end # module
