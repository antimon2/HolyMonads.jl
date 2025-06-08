module MonadIteratorTest

using HolyMonads
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

    mi = Identity.miterator([1])
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Identity), Vector{Int}}
    result_arr = collect(mi)
    @test result_arr == [[1]]

    result_varr = Any[]
    @for Identity begin
        a ← 1
        push!(result_varr, a)
        b ← 2
        push!(result_varr, b)
    end
    @test result_varr == [1, 2]

    result_varr = Any[]
    Identity.@for begin
        a ← 3
        push!(result_varr, a)
        b ← 4
        push!(result_varr, b)
    end
    @test result_varr == [3, 4]
end

@testset "MaybeMonad" begin
    mi = miterator(Some(1))
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Maybe), typeof(Some(1))}
    result_arr = collect(mi)
    @test result_arr == [1]

    mi = Maybe.miterator(Some(2))
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Maybe), typeof(Some(2))}
    result_arr = collect(mi)
    @test result_arr == [2]

    mi = miterator(nothing)
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Maybe), Nothing}
    result_arr = collect(mi)
    @test isempty(result_arr)

    result_varr = Any[]
    @for Maybe begin
        a ← Some(1)
        push!(result_varr, a)
        b ← Some(2)
        push!(result_varr, b)
    end
    @test result_varr == [1, 2]

    result_varr = Any[]
    Maybe.@for begin
        a ← nothing
        push!(result_varr, a)
        b ← Some(1)
        push!(result_varr, b)
    end
    @test result_varr == []

    result_varr = Any[]
    @for begin
        a ← Some(1)
        push!(result_varr, a)
        b ← nothing
        push!(result_varr, b)
    end
    @test result_varr == [1]
end

@testset "EitherMonad" begin
    mi = miterator(Right(1))
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Either), typeof(Right(1))}
    result_arr = collect(mi)
    @test result_arr == [1]

    mi = Either.miterator(Right(2))
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Either), typeof(Right(2))}
    result_arr = collect(mi)
    @test result_arr == [2]

    mi = miterator(Left("Error"))
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(Either), typeof(Left("Error"))}
    result_arr = collect(mi)
    @test isempty(result_arr)

    result_varr = Any[]
    @for Either begin
        a ← Right(1)
        push!(result_varr, a)
        b ← Right(2)
        push!(result_varr, b)
    end
    @test result_varr == [1, 2]

    result_varr = Any[]
    Either.@for begin
        a ← Left(:NG)
        push!(result_varr, a)
        b ← Right(1)
        push!(result_varr, b)
    end
    @test result_varr == []

    result_varr = Any[]
    @for begin
        a ← Right(1)
        push!(result_varr, a)
        b ← Left(:NG)
        push!(result_varr, b)
    end
    @test result_varr == [1]
end

@testset "ListMonad" begin
    mi = miterator([1, 2, 3])
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(List(Int)), Vector{Int}}
    result_arr = collect(mi)
    @test result_arr == [1, 2, 3]

    mi = List(Int).miterator(4:7)
    @test mi isa MonadIterator
    @test typeof(mi) <: MonadIterator{typeof(List(Int)), <:AbstractVector{Int}}
    result_arr = collect(mi)
    @test result_arr == [4, 5, 6, 7]

    mi = miterator(Any[])
    @test mi isa MonadIterator
    @test typeof(mi) === MonadIterator{typeof(List(Any)), Vector{Any}}
    result_arr = collect(mi)
    @test result_arr == []

    result_varr = Int[]
    @for List(Int) begin
        a ← [1, 2]
        push!(result_varr, a)
        b ← [3, 4]
        push!(result_varr, b)
    end
    @test result_varr == [1, 3, 4, 2, 3, 4]

    result_varr = Int[]
    List.@for begin
        a ← []
        push!(result_varr, a)
        b ← [3, 4]
        push!(result_varr, b)
    end
    @test result_varr == []

    result_varr = Int[]
    @for begin
        a ← [1, 2]
        push!(result_varr, a)
        b ← Int[]
        push!(result_varr, b)
    end
    @test result_varr == [1, 2]
end

end  # module
