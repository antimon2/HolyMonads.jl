"""
    HolyMonads.IdentityMonad

A module including `Identity` monad and related definitions.
"""
module IdentityMonad

import ..HolyMonads
using Base: Callable

export Identity, @identity

# Identity MonadClass
struct IdentityClass <: HolyMonads.MonadClass end
"""
    Identity

Identity MonadClass.
"""
const Identity = IdentityClass()

HolyMonads.monadtype(::Type{IdentityClass}) = Any

# unit
HolyMonads.unit(::IdentityClass, x) = x
(::IdentityClass)(x) = x  # special notation

# mbind
HolyMonads.mbind(f::Callable, ::IdentityClass, m) = f(m)

"""
    @identity begin ～ end
    @identity() do ～ end

Alias for `@do Identity begin ～ end`.
"""
macro identity(ex)
    if Base.is_expr(ex, :(->))
        # Do block syntax
        HolyMonads._monad_do(Identity, ex.args[2])
    else
        HolyMonads._monad_do(Identity, ex)
    end
end

end