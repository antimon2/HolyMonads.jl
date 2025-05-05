module MonadLawsTest

using HolyMonads
import HolyMonads: monadtype, MonadClass, unit, mjoin, fmap, mbind, mzero, mplus
using Base: Callable
using Test

struct SimpleMonadClass <: MonadPlusClass end
const SimpleMonad = SimpleMonadClass()
struct SimpleWrapper
    value::Number
end  # Simple Wrapper Type
Base.getindex(m::SimpleWrapper) = m.value  # extract value by `m[]` notation

monadtype(::Type{SimpleMonadClass}) = SimpleWrapper
MonadClass(::Type{<:SimpleWrapper}) = SimpleMonad

# unit(::Type{SimpleMonad}, value) = SimpleWrapper(value)  # default implementation
mbind(f::Callable, ::SimpleMonadClass, m) = f(m[])
mzero(::SimpleMonadClass) = SimpleWrapper(0.0)
mplus(::SimpleMonadClass, a, b) = @do SimpleMonad begin
    x ← a
    y ← b
    return (x + y)
end

@testset "monad-laws" begin
    @test SimpleMonad.monadtype <: SimpleWrapper
    @test MonadClass(typeof(SimpleWrapper(1))) === SimpleMonad
    unit_1 = SimpleMonad.unit(1)
    @test unit_1 == unit(SimpleMonad, 1) == SimpleWrapper(1)
    
    # law 1. `return x >>= f` == `f x`
    unit_2 = SimpleMonad.unit(2)
    let x=1, f=x->SimpleMonad.unit(2x)
        result = SimpleMonad.mbind(f, SimpleMonad.unit(x))
        expected = f(x)
        @test result == expected == unit_2
    end

    # law 2. `m >>= return` == `m`
    @test SimpleMonad.mbind(SimpleMonad.unit, unit_1) == unit_1
    @test SimpleMonad.mbind(SimpleMonad.unit, unit_2) == unit_2

    # law 3. `(m >>= f) >>= g` == `m >>= (\x -> f x >>= g)`
    let f=x->SimpleMonad.unit(x + 1), g=x->SimpleMonad.unit(x * 2)
        result1 = SimpleMonad.mbind(g, SimpleMonad.mbind(f, unit_1))
        result2 = SimpleMonad.mbind(x->SimpleMonad.mbind(g, f(x)), unit_1)
        @test result1 == result2 == SimpleMonad.unit(4)
    end

    # mzero / mplus
    unit_3 = SimpleMonad.unit(3)
    @test mzero(SimpleMonad) == SimpleMonad.mzero == SimpleWrapper(0.0)
    @test mplus(SimpleMonad, unit_1, unit_2) == SimpleMonad.mplus(unit_2, unit_1) == unit_3

    # liftM
    @test liftM(-, SimpleMonad, unit_1) == SimpleMonad.unit(-1)
    @test liftM(+, SimpleMonad, unit_1, unit_2) == SimpleMonad.unit(3)
    let ⊕=liftM(+, SimpleMonad)
        @test unit_1 ⊕ unit_2 == SimpleMonad.unit(3)
    end
    @test liftM(+, SimpleMonad, unit_1, unit_1, unit_1, unit_1, unit_1) == SimpleMonad.unit(5)
end

end  # module
