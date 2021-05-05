module Yolk

using Mixtape
import Mixtape: CompilationContext, allow, optimize!
using MacroTools: @capture, postwalk, rmlines, unblock
using CodeInfoTools
using CompilerPluginTools: inline_const!
using Core.Compiler: Const, is_pure_intrinsic_infer, intrinsic_nothrow, anymap, quoted, cfg_simplify!, compact!, adce_pass!

using Metatheory
using Metatheory.Library
using Metatheory.EGraphs

@metatheory_init()

include("methodtheory.jl")

struct YolkOptimizer <: CompilationContext
    theory::Vector{Rule}
    block_size_limit::Int
    opt::Bool
    YolkOptimizer(t) = new(t, 2, true)
    YolkOptimizer(t, b) = new(t, 2, b)
    YolkOptimizer() = new(Rule[])
end
allow(::YolkOptimizer, m::Module, args...) = true

shrink(ex::Expr, t) = t
shrink(ex::T, t) where T = Const(ex)

local_inline(g, stmts) = g
local_inline(g::GlobalRef, stmts) = CodeInfoTools.resolve(g)
function local_inline(g::Core.Compiler.SSAValue, stmts)
    g.id <= length(stmts) || return g
    local_inline(Core.Compiler.getindex(stmts, g.id)[:inst], stmts)
end
local_inline(ex::Expr, stmts) = Expr(ex.head, map(a -> local_inline(a, stmts), ex.args)...)

function extract!(ctx, ir)
    theory = ctx.theory
    for i in 1 : ctx.block_size_limit : length(ir.stmts)
        stmt = ir.stmts[i][:inst]
        type = ir.stmts[i][:type]
        if stmt isa Expr && stmt.head == :call
            if allow(ctx, CodeInfoTools.resolve(stmt.args[1]))
                r = local_inline(stmt, ir.stmts)
                G = EGraph(r)
                saturate!(G, theory)
                ex = Metatheory.EGraphs.extract!(G, astsize)
                if !(ex == r)
                    Core.Compiler.setindex!(ir.stmts[i], ex, :inst)
                    Core.Compiler.setindex!(ir.stmts[i], shrink(ex, type), :type)
                end
            end
        end
    end
    return ir
end

function optimize!(ctx::YolkOptimizer, b)
    ir = get_ir(b)
    if !ctx.opt
        ir = julia_passes!(ir, b.sv.src, b.sv)
    else
        ir = extract!(ctx, ir)
        ir = inline_const!(ir)
        ir = compact!(ir, true)
        ir = cfg_simplify!(ir)
        ir = julia_passes!(ir, b.sv.src, b.sv)
    end
    return ir
end

function opt(fn, tt::Type{T};
        emit_callable = false,
        ctx = YolkOptimizer(), 
        opt = true) where T <: Tuple
    emit_callable && return jit(fn, tt; ctx = ctx, opt = opt)
    return emit(fn, tt; ctx = ctx, opt = opt)
end

export opt, YolkOptimizer, @methodtheory

end # module
