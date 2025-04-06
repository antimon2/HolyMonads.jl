module HolyMonads

# import Base: mbind, :(==)
using Base: Callable

export MonadClass, MonadPlusClass, monadtype, unit, mjoin, fmap, mbind, mzero, mplus, @do, liftM

# supertype of MonadClass-trait
abstract type MonadClass end

# supertype of MonadPlus-trait
abstract type MonadPlusClass <: MonadClass end

# MonadClass APIs

# type constructor
monadtype(::Type{MT}) where {MT <: MonadClass} = Union{}  # must be implemented with subtype of `MonadClass`
@inline monadtype(::MT) where {MT <: MonadClass} = monadtype(MT)
# type classifier
MonadClass(::Type{T}) where {T} = error(lazy"$T is NOT assigned to any `MonadClass` type")  # must be implemented with subtype of `MonadClass`
@inline MonadClass(::T) where {T} = MonadClass(T)

# MonadClass M: x -> M x  # `unit` (or `return`)
unit(::MT, value) where {MT <: MonadClass} = monadtype(MT)(value)

# MonadClass M: M (M x) -> M x  # `join`
mjoin(t) = mjoin(MonadClass(t), t)
mjoin(M::MonadClass, t) = mbind(identity, M, t::monadtype(M))::monadtype(M)

# MonadClass M: (x -> y) -> M x -> M y  # `fmap`
fmap(f::Callable, t) = fmap(f, MonadClass(t), t)
fmap(f::Callable, M::MonadClass, t) = mbind(M, t::monadtype(M)) do x
    unit(M, f(x))
end

# MonadClass M: M x -> (x -> M y) -> M y  # `bind`
mbind(f::Callable, t) = mbind(f, MonadClass(t), t)
mbind(f::Callable, M::MonadClass, t) = mjoin(M, fmap(f, M, t::monadtype(M)))

# MonadPlus APIs
# MonadPlus M: M x  # `mzero`
function mzero end
# MonadPlus M: M x -> M x -> M x  # `mplus`
function mplus end

# do syntax
"""
    @do MonadClass block

do notation for monads. a.k.a. computation expressions.
"""
macro var"do"(M, ex)
    _monad_do(esc(M), ex)
end

function _monad_do(M, ex)
    org_lines = Base.is_expr(ex, :block) ? ex.args : Any[ex]
    lines = _desugar(M, Any[], org_lines...)
    Expr(:let, Expr(:block), Expr(:block, lines...))
end

_desugar(_M, lines::Vector{Any}) = lines
_desugar(M, lines::Vector{Any}, line, remain_lines...) = _desugar(M, push!(lines, line), remain_lines...)
function _desugar(M, lines::Vector{Any}, line::Expr, remain_lines...)
    _Self = @__MODULE__  # == HolyMonads
    if line.head === :call && line.args[1] === :(←)
        # mbind
        body = _desugar(M, Any[], remain_lines...)
        result = :($_Self.mbind($M, $(esc(line.args[3]))) do $(esc(line.args[2]))
            $(body...)
        end)
        push!(lines, result)
    elseif line.head === :return
        # unit
        new_line = :($_Self.unit($M, $(esc(line.args[1]))))
        _desugar(M, push!(lines, new_line), remain_lines...)
    else
        # TODO: support other expressions
        _desugar(M, push!(lines, line), remain_lines...)
    end
end

liftM(f::Callable, M::MonadClass) = (a1, args...) -> liftM(f, M, a1, args...)
liftM(f::Callable, M::MonadClass, t) = fmap(f, M, t)
function liftM(f::Callable, M::MonadClass, t1, t2)
    @do M begin
        x ← t1
        y ← t2
        return f(x, y)
    end
end
function liftM(f::Callable, M::MonadClass, args::Vararg{T, N}) where {T, N}
    function _rec(f, M, args, N, i, largs=())
        if i > N
            return unit(M, f(largs...))
        end
        mbind(M, args[i]) do x
            _rec(f, M, args, N, i+1, (largs..., x))
        end
    end
    _rec(f, M, args, N, 1)
end

# Identity MonadClass
include("IdentityMonad.jl")

# Maybe MonadClass with `Some{T}` and `Nothing`
include("MaybeMonad.jl")

# List MonadClass with `Vector{T}`
include("ListMonad.jl")

# Either MonadClass
include("EitherMonad.jl")

# for `«Monad».«api»` notations
@static if isdefined(Base, :Fix) # VERSION ≥ v"1.12.0-DEV.981"

const FixM1{F, MT <: MonadClass} = Base.Fix{1, F, MT}
FixM1(f::F, M::MT) where {F, MT <: MonadClass} = Base.Fix{1}(f, M)
const FixM2{F, MT <: MonadClass} = Base.Fix{2, F, MT}
FixM2(f::F, M::MT) where {F, MT <: MonadClass} = Base.Fix{2}(f, M)
const FixM3{F, MT <: MonadClass} = Base.Fix{3, F, MT}
FixM3(f::F, M::MT) where {F, MT <: MonadClass} = Base.Fix{3}(f, M)

else

struct FixM1{F, MT <: MonadClass} <: Function
    f::F
    M::MT
end
(f::FixM1)(args...) = f.f(f.M, args...)

struct FixM2{F, MT <: MonadClass} <: Function
    f::F
    M::MT
end
(f::FixM2)(v, args...) = f.f(v, f.M, args...)

struct FixM3{F, MT <: MonadClass} <: Function
    f::F
    M::MT
end
(f::FixM3)(a1, a2, args...) = f.f(a1, a2, f.M, args...)

end

# override `getproperty` to support `A_Monad.[unit, mjoin, fmap, mbind, @do, liftM]`
function Base.getproperty(M::MonadClass, name::Symbol)
    if name in [:unit, :mjoin]
        _fn = getfield(HolyMonads, name)
        return FixM1(_fn, M)
    end
    if name in [:fmap, :mbind, :liftM]
        _fn = getfield(HolyMonads, name)
        return FixM2(_fn, M)
    end
    if name === Symbol("@do")
        return FixM3(HolyMonads.var"@do", M)
    end
    # return getfield(M, name)
    return @invoke getproperty(M::Any, name)
end
Base.propertynames(M::MonadClass) = ((@invoke Base.propertynames(M::Any))..., :unit, :mjoin, :fmap, :mbind, Symbol("@do"), :liftM)

# override `getproperty` to support `A_MonadPlus.[mzero, mplus]`
function Base.getproperty(M::MonadPlusClass, name::Symbol)
    if name === :mzero
        return HolyMonads.mzero(M)
    end
    if name === :mplus
        # return (args...) -> HolyMonads.mplus(M, args...)
        return FixM1(HolyMonads.mplus, M)
    end
    return @invoke getproperty(M::MonadClass, name)
end
Base.propertynames(M::MonadPlusClass) = ((@invoke Base.propertynames(M::MonadClass))..., :mzero, :mplus)

end
