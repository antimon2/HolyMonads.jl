module IdentityMonad

import ..HolyMonads
using Base: Callable

export Identity, @identity

# Identity MonadClass
struct IdentityClass <: HolyMonads.MonadClass end
const Identity = IdentityClass()

HolyMonads.monadtype(::Type{IdentityClass}) = Any

# unit
HolyMonads.unit(::IdentityClass, x) = x
(::IdentityClass)(x) = x  # special notation

# mbind
HolyMonads.mbind(f::Callable, ::IdentityClass, m) = f(m)

macro identity(ex)
    if Base.is_expr(ex, :(->))
        # Do block syntax
        HolyMonads._monad_do(Identity, ex.args[2])
    else
        HolyMonads._monad_do(Identity, ex)
    end
end

end