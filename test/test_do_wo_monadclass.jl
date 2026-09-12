module DoWoMonadClassTest

using HolyMonads
using HolyMonads.MaybeMonad
using HolyMonads.EitherMonad
using Test

getmaybe(dic::AbstractDict, key) = haskey(dic, key) ? Maybe.unit(getindex(dic, key)) : Maybe.mzero

parseeither(T, x) = try
    Right(parse(T, x))
catch err
    Left(err)
end

@testset "DoWoMaybe" begin

    result = @do begin
        a ← Some(1)
        b ← Some(2)
        return a + b
    end
    @test result == Some(3)

    result2 = @do begin
        a ← nothing
        b ← Some(2)
        return a + b
    end
    @test result2 === nothing

    dic = Dict(:a => 3)
    result3 = @do begin
        a ← getmaybe(dic, :a)
        b ← Some(2)
        return a + b
    end
    @test result3 == Some(5)

    result4 = @do begin
        a ← getmaybe(dic, :not_exists)
        b ← Some(2)
        return a + b
    end
    @test result4 === nothing

    result5 = @do begin
        a ← Some(2)
        b ← getmaybe(dic, :not_exists)
        return a + b
    end
    @test result5 === nothing

end

@testset "DoWoList" begin

    result = @do begin
        a ← [1, 3]
        b ← [3, 4]
        return a + b
    end
    @test result == [4, 5, 6, 7]

    result = @do begin
        a ← []
        b ← [3, 4]
        return a + b
    end
    @test result == []

end

@testset "DoWoEither" begin

    result_do1 = @do begin
        a ← Right(1)
        b ← parseeither(Int, "2")
        return a + b
    end
    @test result_do1 == Right(3)

    result_do3 = @do begin
        a ← Left("NoExecution")
        b ← parseeither(Int, "2")
        return a + b
    end
    @test result_do3 == Left("NoExecution")

    result_do4 = @do begin
        a ← parseeither(Int, "1")
        b ← parseeither(Int, "2")
        return a + b
    end
    @test result_do4 == Right(3)

    result_do6 = @do begin
        a ← parseeither(Int, "NOTAINTEGERE")
        b ← parseeither(Int, "2")
        return a + b
    end
    @test isleft(result_do6)
    @test fromleft(result_do6, :NG) isa ArgumentError

end

end  # module
