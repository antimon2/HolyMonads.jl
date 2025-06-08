module MonadIteratorTest

using HolyMonads
using HolyMonads.MonadIterators
using HolyMonads.MonadIterators: MonadIterator
using HolyMonads.IdentityMonad
using HolyMonads.MaybeMonad
using HolyMonads.EitherMonad
using HolyMonads.ListMonad
using Test

@testset "IdentityMonad" begin
    mi = miterator(Identity, 1)
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Identity), Int}
    result_arr = collect(mi)
    @test result_arr == [1]

    mi = miterator(Identity, [1])
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Identity), Vector{Int}}
    result_arr = collect(mi)
    @test result_arr == [[1]]
end

@testset "MaybeMonad" begin
    mi = miterator(Some(1))
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Maybe), typeof(Some(1))}
    result_arr = collect(mi)
    @test result_arr == [1]

    mi = miterator(nothing)
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Maybe), Nothing}
    result_arr = collect(mi)
    @test isempty(result_arr)
end

@testset "EitherMonad" begin
    mi = miterator(Right(1))
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Either), typeof(Right(1))}
    result_arr = collect(mi)
    @test result_arr == [1]

    mi = miterator(Left("Error"))
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Either), typeof(Left("Error"))}
    result_arr = collect(mi)
    @test isempty(result_arr)
end

@testset "ListMonad" begin
    mi = miterator([1, 2, 3])
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(List(Int)), Vector{Int}}
    result_arr = collect(mi)
    @test result_arr == [1, 2, 3]

    mi = miterator(Any[])
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(List(Any)), Vector{Any}}
    result_arr = collect(mi)
    @test result_arr == []
end

end  # module
