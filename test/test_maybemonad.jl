module MaybeMonadTest

using HolyMonads
using HolyMonads.MaybeMonad
using Test

@testset "MaybeMonad" begin
    @test monadtype(Maybe) <: Union{Some, Nothing}
    @test MonadClass(Some(1)) === Maybe
    @test MonadClass(nothing) === Maybe
    @test Maybe.unit(1) == Some(1)
    @test Maybe.fmap(x -> x + 1, Some(1)) == Some(2)
    @test Maybe.mbind(x -> Some(x + 1), Some(1)) == Some(2)
    @test Maybe.mbind(x -> Some(x + 1), nothing) === nothing

    result = @do Maybe begin
        a ← Some(1)
        b ← Some(2)
        return a + b
    end
    @test result == Some(3)

    result′ = Maybe.@do begin
        a ← Some(1)
        b ← Some(2)
        return a + b
    end
    @test result′ == Some(3)

    result2 = @maybe begin
        a ← Some(1)
        b ← nothing
        return a + b
    end
    @test result2 === nothing

    result3 = @maybe() do
        a ← nothing
        b ← Some(2)
        return a + b
    end
    @test result3 === nothing
end

end  # module
