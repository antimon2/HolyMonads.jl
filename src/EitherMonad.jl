module EitherMonad

import ..HolyMonads
using Base: Callable

export Either, Left, Right, @either, fromleft, fromright, isleft, isright, matchleft, matchright, lefts, rights, partitioneither

struct EitherClass <: HolyMonads.MonadClass end
const Either = EitherClass()

abstract type EitherType end
struct Left{L<:Any} <: EitherType
    value::L
end

struct Right{R<:Any} <: EitherType
    value::R
end

HolyMonads.monadtype(::Type{EitherClass}) = EitherType
HolyMonads.MonadClass(::Type{<:EitherType}) = Either

# unit (or instantiate)
HolyMonads.unit(::EitherClass, value::R) where R = Right{R}(value)
(::EitherClass)(value::R) where R = Right{R}(value)

# mjoin
HolyMonads.mjoin(::EitherClass, m::EitherType) = m.value::EitherType
HolyMonads.mjoin(::EitherClass, m::Left) = m

# fmap
function HolyMonads.fmap(f::Callable, ::EitherClass, e::EitherType)
    if isleft(e)
        return e
    end
    try
        Right(f(e.value))
    catch err
        Left(err)
    end
end

# # mbind  # use default implementation

macro either(ex)
    if Base.is_expr(ex, :(->))
        # Do block syntax
        HolyMonads._monad_do(Either, ex.args[2])
    else
        HolyMonads._monad_do(Either, ex)
    end
end

# utility functions
fromleft(::EitherType, default=nothing) = default
fromleft(e::Left, _default) = e.value
fromright(::EitherType, default=nothing) = default
fromright(e::Right, _default) = e.value

isleft(::EitherType) = false
isleft(::Left) = true
isright(::EitherType) = false
isright(::Right) = true

matchleft(::Callable, ::EitherType) = nothing
matchleft(f::Callable, e::Left) = f(e.value)
matchright(::Callable, ::EitherType) = nothing
matchright(f::Callable, e::Right) = f(e.value)

lefts(eithers::AbstractArray{<:EitherType}) = [e.value for e in eithers if isleft(e)]
rights(eithers::AbstractArray{<:EitherType}) = [e.value for e in eithers if isright(e)]
partitioneither(eithers::AbstractArray{<:EitherType}) = (lefts(eithers), rights(eithers))

end  # module
