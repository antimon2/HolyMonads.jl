module MaybeMonad

import ..HolyMonads
using Base: Callable

export Maybe, @maybe

struct MaybeClass <: HolyMonads.MonadPlusClass end
const Maybe = MaybeClass()
const MaybeType{T} = Union{Some{T}, Nothing}

HolyMonads.monadtype(::Type{MaybeClass}) = MaybeType
HolyMonads.MonadClass(::Type{<:MaybeType}) = Maybe

# unit/mzero/mplus
HolyMonads.unit(::MaybeClass, value) = Some(value)
HolyMonads.mzero(::MaybeClass) = nothing
HolyMonads.mplus(::MaybeClass, a::MaybeType, _b) = a
HolyMonads.mplus(::MaybeClass, ::Nothing, b::MaybeType) = b

# mbind
HolyMonads.mbind(f::Callable, ::MaybeClass, m) = f(m)  # for useful reason
HolyMonads.mbind(f::Callable, ::MaybeClass, m::Some) = f(something(m))
HolyMonads.mbind(::Callable, ::MaybeClass, ::Nothing) = HolyMonads.mzero(Maybe)  # === nothing

"""
    @maybe
"""
macro maybe(ex)
    if Base.is_expr(ex, :(->))
        # Do block syntax
        HolyMonads._monad_do(Maybe, ex.args[2])
    else
        HolyMonads._monad_do(Maybe, ex)
    end
end

end  # module
