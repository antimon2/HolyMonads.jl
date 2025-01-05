module HolyMonadsTest

using Test

ids = ["types"] ∪ (!isempty(ARGS) ? ARGS : [
    m[:id]
    for m in (match(r"^test_(?<id>.+)\.jl$", filename) for filename in readdir(@__DIR__))
    if m !== nothing
])
@testset for id in ids
    include("test_$id.jl")
end

end  # module
