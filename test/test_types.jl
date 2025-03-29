module TypesTest

using HolyMonads
import HolyMonads: MonadClass, monadtype, unit, mjoin, fmap, mbind, mzero, mplus
using Base: Callable
using Test

struct DummyMonadClass <: MonadClass end
const DummyMonad = DummyMonadClass()
monadtype(::Type{DummyMonadClass}) = Any

unit(::DummyMonadClass, value) = value
mjoin(::DummyMonadClass, m) = m
fmap(f::Callable, ::DummyMonadClass, m) = (f, m)
mbind(f::Callable, ::DummyMonadClass, m) = (f, m)

struct DummyMonadPlusClass <: MonadPlusClass end
const DummyMonadPlus = DummyMonadPlusClass()
monadtype(::Type{DummyMonadPlusClass}) = Any

mzero(::DummyMonadPlusClass) = :nothing
mplus(::DummyMonadPlusClass, a, b) = (a, b)

@testset "types" begin
    # CAUTION: `DummyMonad` does not obey monad laws
    @test monadtype(DummyMonad) === Any
    @test_throws ErrorException MonadClass(DummyMonad)
    @test DummyMonad.unit isa Function
    @test unit(DummyMonad, :ok) === DummyMonad.unit(:ok) === :ok
    @test mjoin(DummyMonad, :ok) === DummyMonad.mjoin(:ok) === :ok
    @test fmap(+, DummyMonad, 1) === DummyMonad.fmap(+, 1) === (+, 1)
    @test mbind(+, DummyMonad, 1) === DummyMonad.mbind(+, 1) === (+, 1)
    @test liftM(+, DummyMonad, 1) === (+, 1)

    # CAUTION: `DummyMonadPlus` does not obey monad laws
    @test monadtype(DummyMonadPlus) === Any
    @test_throws ErrorException MonadClass(DummyMonadPlus)
    @test mzero(DummyMonadPlus) === DummyMonadPlus.mzero === :nothing
    @test mplus(DummyMonadPlus, :ok, :good) === DummyMonadPlus.mplus(:ok, :good) === (:ok, :good)
end

end  # module
