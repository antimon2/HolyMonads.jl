module IdentityMonadTest

using HolyMonads
using HolyMonads.IdentityMonad
using Test

@testset "IdentityMonad" begin
    @test monadtype(Identity) <: Any
    @test Identity.unit(1) == Identity(1) == 1
    @test Identity.mjoin(1) == 1
    @test Identity.fmap(x -> x + 1, 1) == 2
    @test Identity.mbind(x -> Identity(x + 1), 1) == 2
    result = @do Identity begin
        a ← 1
        b ← 2
        return a + b
    end
    @test result == 3

    result′ = Identity.@do begin
        a ← 1
        b ← 2
        return a + b
    end
    @test result′ == 3

    result2 = @identity begin
        a ← 1
        b ← 2
        return a + b
    end
    @test result2 == 3

    result3 = @identity() do
        a ← 1
        b ← 2
        return a + b
    end
    @test result3 == 3
end

end  # module
