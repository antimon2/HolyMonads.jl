module ListMonadTest

using HolyMonads
using HolyMonads.ListMonad
using Test

@testset "ListMonad" begin
    @test monadtype(List) <: AbstractVector
    @test MonadClass(typeof([1, 2])) === List(Int)

    @test List.unit(1) == [1]
    @test List(Int).unit(1) == [1]
    @test List(Float64).unit(1) == [1.0]
    @test List.unit([1, 2]) == [1, 2]
    @test List(Int).unit([1, 2]) == [1, 2]
    @test List(Float64).unit([1, 2]) == [1.0, 2.0]
    @test List(Int).mzero == Int[]
    @test List.mzero == []

    result_fmap1 = List(Int).fmap(x -> x + 1, [1, 2, 3])
    @test result_fmap1 == [2, 3, 4]
    @test eltype(result_fmap1) == Int

    result_fmap2 = List.fmap(x -> 2x, [1, 2, 3])
    @test result_fmap2 == [2, 4, 6]
    @test eltype(result_fmap2) == Int

    result_fmap3 = List.fmap(x -> x/2, [1, 2, 3])
    @test result_fmap3 == [0.5, 1.0, 1.5]
    @test eltype(result_fmap3) == Float64

    @test List(Int).mbind(x -> [x, x + 1], [1, 2, 3]) == [1, 2, 2, 3, 3, 4]
    @test List.mbind(x -> [x, 2x], [1, 2, 3]) == [1, 2, 2, 4, 3, 6]

    result_do1 = @do List(Int) begin
        a ← [1, 2]
        b ← [3, 4]
        return a + b
    end
    result_do1_expected = [4, 5, 5, 6]
    @test result_do1 == result_do1_expected

    result_do2 = @do List begin
        a ← [1, 2]
        b ← [3, 4]
        return a + b
    end
    result_do2_expected = [4, 5, 5, 6]
    @test result_do2 == result_do2_expected

    result_do3 = @list Int begin
        a ← [1, 2]
        b ← [3, 4]
        return a * b
    end
    result_do3_expected = [3, 4, 6, 8]
    @test result_do3 == result_do3_expected

    result_do4 = @list Float64 begin
        a ← [1, 2]
        b ← [3, 4]
        return a / b
    end
    result_do4_expected = [1/3, 1/4, 2/3, 2/4]
    @test result_do4 == result_do4_expected

    result_do5 = @list(Int) do
        a ← [1, 2]
        b ← [3, 4]
        return a * b
    end
    result_do5_expected = [3, 4, 6, 8]
    @test result_do5 == result_do5_expected

    result_do6 = @list(Float64) do
        a ← [1, 2]
        b ← [3, 4]
        return a / b
    end
    result_do6_expected = [1/3, 1/4, 2/3, 2/4]
    @test result_do6 == result_do6_expected

    result_do7 = @list begin
        a ← [1, 2]
        b ← [3, 4]
        return a / b
    end
    result_do7_expected = [1/3, 1/4, 2/3, 2/4]
    @test result_do7 == result_do7_expected

    result_do8 = @list() do
        a ← [1, 2]
        b ← [3, 4]
        return a / b
    end
    result_do8_expected = [1/3, 1/4, 2/3, 2/4]
    @test result_do8 == result_do8_expected

    result_do9 = @list() do
        a ← [1, 2]
        b ← [3, 4]
        return (a, b)
    end
    result_do9_expected = [(1, 3), (1, 4), (2, 3), (2, 4)]
    @test result_do9 == result_do9_expected

    result_mplus1 = List(Int).mplus([1, 2], [3, 4])
    @test result_mplus1 == [1, 2, 3, 4]

    result_mplus2 = List.mplus([1, 2], [3, 4])
    @test result_mplus2 == [1, 2, 3, 4]

    result_liftM1 = liftM(x -> 2x + 1, List, [1, 2])
    @test result_liftM1 == [3, 5]

    result_liftM2 = liftM(+, List, [1, 2], [3, 4])
    @test result_liftM2 == [4, 5, 5, 6]

    result_liftM3 = liftM(+, List, [1, 2], [3, 4], [5, 6])
    @test result_liftM3 == [9, 10, 10, 11, 10, 11, 11, 12]
end

end  # module
