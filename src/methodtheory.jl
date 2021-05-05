make_globals(s) = s
lift_global(s::Symbol) = GlobalRef(@__MODULE__, s)
function lift_global(ex::Expr)
    if ex.head == :.
        return GlobalRef(
                         CodeInfoTools.resolve(lift_global(ex.args[1])),
                         ex.args[2].value)
    end
    return ex
end
function make_globals(ex::Expr) 
    if ex.head == :call
        return Expr(ex.head, 
                    lift_global(ex.args[1]),
                    map(make_globals, ex.args[2 : end])...)
    elseif ex.head == :(::)
        return Expr(ex.head, ex.args[1], 
                    lift_global(ex.args[2]))
    elseif ex.head == :.
        return lift_global(ex)
    else
        return Expr(ex.head, map(make_globals, ex.args)...)
    end
end

make_patterm(s::Number) = PatLiteral(s)
make_patterm(s::Symbol) = PatVar(s)
function make_patterm(ex::Expr)
    if ex.head == :call
        return PatTerm(:call, [PatLiteral(ex.args[1]), map(make_patterm, ex.args[2 : end])...])
    elseif ex.head == :(::)
        @assert(ex.args[1] isa Symbol)
        return PatTypeAssertion(PatVar(ex.args[1]), ex.args[2])
    end
end

create_patterm(e) = e
create_patterm(e::Int) = PatLiteral(e)
function create_patterm(expr::Expr)
    resolved = make_globals(expr)
    resolved = walk(CodeInfoTools.resolve, resolved)
    return make_patterm(resolved)
end

function _methodtheory(ex::Expr)
    @assert(@capture(ex, begin body__ end))
    new = map(body) do sub
        if @capture(sub, lhs_ => rhs_)
            return Expr(:call, :push!, :arr,
                        RewriteRule(create_patterm(lhs), create_patterm(rhs)))
        elseif @capture(sub, lhs_ |> rhs_)
            return Expr(:call, :push!, :arr,
                        DynamicRule(create_patterm(lhs), rhs))
        end
    end
    return quote
        arr = Rule[]
        $(new...)
        arr
    end
end

macro methodtheory(ex)
    new = _methodtheory(ex)
    new = postwalk(rmlines ∘ unblock, new)
    esc(new)
end
