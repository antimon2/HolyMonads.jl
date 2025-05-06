module HolyMonads

using Base: Callable

export MonadClass, MonadPlusClass, monadtype, unit, mjoin, fmap, mbind, mzero, mplus, @do, liftM

# supertype of MonadClass-trait
"""
    MonadClass

Abstract type for monad classes.
"""
abstract type MonadClass end

# supertype of MonadPlus-trait
"""
    MonadPlusClass

Abstract type for monad classes with `mzero` and `mplus` operations.
"""
abstract type MonadPlusClass <: MonadClass end

# MonadClass APIs

# type constructor
"""
    monadtype(::Type{MT}) where {MT <: MonadClass}
    monadtype(::MT) where {MT <: MonadClass}
    (M::MT).monadtype

Returns the corresponding monadic context type for specified monad class.

# Example

```julia-repl
julia> using HolyMonads

juila> using HolyMonads.MaybeMonad

julia> monadtype(Maybe) === Maybe.monadtype === MaybeMonad.MaybeType
true
```
"""
monadtype(::Type{MT}) where {MT <: MonadClass} = Union{}  # must be implemented with subtype of `MonadClass`
@inline monadtype(::MT) where {MT <: MonadClass} = monadtype(MT)

# type classifier
"""
    MonadClass(::Type{T}) where {T}
    MonadClass(::T) where {T}

Returns the corresponding monad class for specified monad type.

# Example

```julia-repl
julia> using HolyMonads

juila> using HolyMonads.MaybeMonad

julia> MonadClass(Some(1)) === MonadClass(Nothing) === Maybe
true
```
"""
MonadClass(::Type{T}) where {T} = error(lazy"$T is NOT assigned to any `MonadClass` type")  # must be implemented with subtype of `MonadClass`
@inline MonadClass(::T) where {T} = MonadClass(T)

"""
    unit(::MT, value) where {MT <: MonadClass}
    (M::MonadClass).unit(value)

Returns the monadic context of the specified value.  
(unit :: MonadClass M: x -> M x)  
(a.k.a. `return` or `pure`)

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.MaybeMonad

julia> unit(Maybe, 1) === Maybe.unit(1) === Some(1)
true
```
"""
unit(::MT, value) where {MT <: MonadClass} = monadtype(MT)(value)

"""
    mjoin(M::MonadClass, value)
    (M::MonadClass).mjoin(value)

Flattens the nested monadic context.  The argument `value` must be a monadic context.
(mjoin :: MonadClass M: M (M x) -> M x)

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.MaybeMonad

julia> mjoin(Maybe, Some(Some(1))) === Maybe.mjoin(Some(Some(1))) === Some(1)
true
```
"""
mjoin(t) = mjoin(MonadClass(t), t)
mjoin(M::MonadClass, t) = mbind(identity, M, t::monadtype(M))::monadtype(M)

"""
    fmap(f::Callable, M::MonadClass, t)
    (M::MonadClass).fmap(f, t)

Returns the monadic context of the result of applying `f` to the value in the monadic context `t`.  
You can use Julia's `do` syntax to pass the function `f` as a block.
(fmap :: MonadClass M: (x -> y) -> M x -> M y)
(a.k.a. `flatmap`)

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.MaybeMonad

julia> fmap(Maybe, Some(1)) do x
           x + 1
       end === Maybe.fmap(x -> x + 1, Some(1)) === Some(2)
true
```
"""
fmap(f::Callable, t) = fmap(f, MonadClass(t), t)
fmap(f::Callable, M::MonadClass, t) = mbind(M, t::monadtype(M)) do x
    unit(M, f(x))
end

"""
    mbind(f::Callable, M::MonadClass, t)
    (M::MT).mbind(f, t)

Returns the monadic context of the result of applying `f` to the value in the monadic context `t`.
You can use Julia's `do` syntax to pass the function `f` as a block.
(mbind :: MonadClass M: (x -> M y) -> M x -> M y)
(a.k.a. `bind`)

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.MaybeMonad

julia> mbind(Maybe, Some(1)) do x
           unit(Maybe, x + 1)
       end === Maybe.mbind(x -> Maybe.unit(x + 1), Some(1)) === Some(2)
true
```
"""
mbind(f::Callable, t) = mbind(f, MonadClass(t), t)
mbind(f::Callable, M::MonadClass, t) = mjoin(M, fmap(f, M, t::monadtype(M)))

# MonadPlus APIs
"""
    mzero(M::MonadPlusClass)
    (M::MonadPlusClass).mzero

Returns the monadic context of the zero element.
(mzero :: MonadPlusClass M: M x)

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.MaybeMonad

julia> mzero(Maybe) === Maybe.mzero === nothing
true
```
"""
function mzero end

"""
    mplus(M::MonadPlusClass, a, b)
    (M::MonadPlusClass).mplus(a, b)

Returns the monadic context of the result of combining `a` and `b`.
(mplus :: MonadPlusClass M: M x -> M x -> M x)

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.MaybeMonad

julia> mplus(Maybe, Some(1), Some(2)) === Maybe.mplus(Some(1), Some(2)) === Some(1)
true
```
"""
function mplus end

# do syntax
"""
    @do Monad block
    Monad.@do block

do notation for monads. a.k.a. computation expressions.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.MaybeMonad

julia> result = Maybe.@do begin
           a ← Some(1)
           b ← Some(2)
           return a + b
       end
Some(3)
```
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

"""
    liftM(f::Callable, M::MonadClass, args...)
    (M::MonadClass).liftM(f, args...)

Lifts a function `f` to a monadic context.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.MaybeMonad

julia> liftM(-, Maybe, Some(1)) === Maybe.liftM(-, Some(1)) === Some(-1)
true

julia> Maybe.liftM(+, Some(1), Some(2), Some(3))
Some(6)
```

---

    liftM(op, M::MonadClass)
    (M::MonadClass).liftM(op)

Returns a lifted operator of `op` to a monadic context.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.MaybeMonad

julia> let ⊕ = Maybe.liftM(+)
           Some(1) ⊕ Some(2) ⊕ Some(3)
       end
Some(6)
```
"""
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

# override `getproperty` to support `A_Monad.[monadtype, unit, mjoin, fmap, mbind, @do, liftM]`
function Base.getproperty(M::MonadClass, name::Symbol)
    if name === :monadtype
        return HolyMonads.monadtype(M)
    end
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
Base.propertynames(M::MonadClass) = 
    ((@invoke Base.propertynames(M::Any))..., :monadtype, :unit, :mjoin, :fmap, :mbind, Symbol("@do"), :liftM)

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

# to support `@doc A_Monad.[unit, mjoin, fmap, mbind, @do, liftM, monadtype, mzero, mplus]`
Base.Docs.Binding(::MonadClass, name::Symbol) = Base.Docs.Binding(HolyMonads, name)

end
