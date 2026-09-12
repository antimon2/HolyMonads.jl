module MonadIterators

import ..HolyMonads: HolyMonads, MonadClass
# using Base: iterate

export miterator, @for

"""
    miterator(m::MT)
    miterator(M::MonadClass, m::MT)

return an iterator for the monadic value `m` of type `MT`.
"""
function miterator end

struct MonadIterator{MC <: MonadClass, MT}
    m::MT

    function MonadIterators.miterator(M::MC, m::MT) where {MC <: MonadClass, MT}
        _MT = HolyMonads.monadtype(M)
        @assert MT <: _MT lazy"Monad type mismatch: expected $(_MT), got $(MT)"
        new{MC, MT}(m)
    end
end

miterator(m) = miterator(HolyMonads.MonadClass(m), m)

Base.IteratorSize(::MonadIterator{MC, MT}) where {MC, MT} = Base.SizeUnknown()
Base.IteratorEltype(::MonadIterator{MC, MT}) where {MC, MT} = Base.EltypeUnknown()

function Base.iterate(mi::MonadIterator{MC, MT}) where {MC <: MonadClass, MT}
    HolyMonads.ispure(MC(), mi.m) || return nothing
    (HolyMonads.unpure(MC(), mi.m), nothing)
end
Base.iterate(::MonadIterator, ::Nothing) = nothing

# @for (like a do syntax)
macro var"for"(ex)
    _monad_for_wo_monadclass(ex)
end
macro var"for"(M, ex)
    _monad_for(M, ex)
end

function _monad_for_wo_monadclass(ex)
    org_lines = Base.is_expr(ex, :block) ? ex.args : Any[ex]
    lines = _desugar_wo_monadclass(Any[], org_lines...)
    esc(Expr(:let, Expr(:block), Expr(:block, lines...)))
end

_desugar_wo_monadclass(lines::Vector{Any}) = lines
_desugar_wo_monadclass(lines::Vector{Any}, line, remain_lines...) =
    _desugar_wo_monadclass(push!(lines, line), remain_lines...)
function _desugar_wo_monadclass(lines::Vector{Any}, line::Expr, remain_lines...)
    _Self = @__MODULE__  # == HolyMonads.MonadIterators
    if line.head === :call && line.args[1] === :(←)
        # for
        body = Expr(:block, _desugar_wo_monadclass(Any[], remain_lines...)...)
        result = Expr(:for, :($(line.args[2]) = $_Self.miterator($(line.args[3]))), body)
        push!(lines, result)
    else
        _desugar_wo_monadclass(push!(lines, line), remain_lines...)
    end
end

function _monad_for(M, ex)
    org_lines = Base.is_expr(ex, :block) ? ex.args : Any[ex]
    lines = _desugar(M, Any[], org_lines...)
    esc(Expr(:let, Expr(:block), Expr(:block, lines...)))
end

_desugar(_M, lines::Vector{Any}) = lines
_desugar(M, lines::Vector{Any}, line, remain_lines...) = _desugar(M, push!(lines, line), remain_lines...)
function _desugar(M, lines::Vector{Any}, line::Expr, remain_lines...)
    _Self = @__MODULE__  # == HolyMonads.MonadIterators
    if line.head === :call && line.args[1] === :(←)
        # for
        body = Expr(:block, _desugar(M, Any[], remain_lines...)...)
        result = Expr(:for, :($(line.args[2]) = $_Self.miterator($M, $(line.args[3]))), body)
        push!(lines, result)
    else
        _desugar(M, push!(lines, line), remain_lines...)
    end
end

end  # module MonadIterators
