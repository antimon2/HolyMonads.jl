module EitherMonadTest

using HolyMonads
using HolyMonads.EitherMonad
using Test

parseeither(T, x) = try
    Right(parse(T, x))
catch err
    Left(err)
end

@testset "EitherMonad" begin
    @test Either.monadtype <: HolyMonads.EitherMonad.EitherType
    @test MonadClass(Right(1)) === Either
    @test MonadClass(Left(0)) === Either

    @test Either.unit(1) == Right(1)
    @test Right(2) == Right(2)
    @test Left(3) == Left(3)

    result_fmap1 = Either.fmap(x -> parse(Int, x), Right("123"))
    @test result_fmap1 == Right(123)
    @test typeof(fromright(result_fmap1, nothing)) === Int

    result_fmap1′ = fmap(x -> parse(Int, x), Right("124"))
    @test result_fmap1′ == Right(124)
    @test typeof(fromright(result_fmap1′, nothing)) === Int

    result_fmap2 = Either.fmap(x -> parse(Int, x), Right("ERROR"))
    @test result_fmap2 isa Left{ArgumentError}
    @test typeof(fromleft(result_fmap2, nothing)) == ArgumentError

    result_fmap3 = Either.fmap(x -> parse(Int, x), Left("NoExecution"))
    @test result_fmap3 == Left("NoExecution")
    @test typeof(fromleft(result_fmap3, nothing)) == String

    @test Either.mbind(x -> parseeither(Int, x), Right("123")) == Right(123)
    @test mbind(x -> parseeither(Int, x), Right("124")) == Right(124)
    @test Either.mbind(x -> parseeither(Int, x), Right("ERROR")) isa Left{ArgumentError}
    @test Either.mbind(x -> parseeither(Int, x), Left("NoExecution")) == Left("NoExecution")

    result_do1 = @do Either begin
        a ← Right(1)
        b ← parseeither(Int, "2")
        return a + b
    end
    @test result_do1 == Right(3)

    result_do1′ = Either.@do begin
        a ← Right(1)
        b ← parseeither(Int, "2")
        return a + b
    end
    @test result_do1′ == Right(3)

    result_do2 = @do Either begin
        a ← Right(1)
        b ← parseeither(Int, "NaN")
        return a + b
    end
    @test result_do2 isa Left{ArgumentError}

    result_do3 = @do Either begin
        a ← Left("NoExecution")
        b ← parseeither(Int, "2")
        return a + b
    end
    @test result_do3 == Left("NoExecution")

    result_do4 = @either begin
        a ← parseeither(Int, "1")
        b ← parseeither(Int, "2")
        return a + b
    end
    @test result_do4 == Right(3)

    result_do5 = @either() do
        a ← parseeither(Int, "1")
        b ← parseeither(Int, "2")
        return a + b
    end
    @test result_do5 == Right(3)

    @testset "utilities" begin
        @test fromleft(Left(:ok), :NG) == :ok
        @test fromleft(Right(:NG), :ok) == :ok
        @test fromright(Right(:ok), :NG) == :ok
        @test fromright(Left(:NG), :ok) == :ok

        @test isleft(Left(:ok))
        @test !isleft(Right(:NG))
        @test isright(Right(:ok))
        @test !isright(Left(:NG))

        @test matchleft(x -> 2x, Left(1)) == 2
        @test matchleft(x -> 2x, Right(1)) === nothing
        @test matchright(x -> 2x, Right(1)) == 2
        @test matchright(x -> 2x, Left(1)) === nothing

        eithers = [Right(1), Left(2), Right(3), Left(4)]
        @test lefts(eithers) == [2, 4]
        @test rights(eithers) == [1, 3]
        @test partitioneither(eithers) == ([2, 4], [1, 3])
    end
end

end  # module
