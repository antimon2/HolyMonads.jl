"""
    HolyMonads.EitherMonad

A module including `Either` monad and related definitions.
"""
module EitherMonad

import ..HolyMonads
using Base: Callable

export Either, Left, Right, @either, fromleft, fromright, isleft, isright, matchleft, matchright, lefts, rights, partitioneither

struct EitherClass <: HolyMonads.MonadClass end
"""
    Either

Either MonadClass.
"""
const Either = EitherClass()

"""
    EitherType

Either context type (abstract type). `Left` and `Right` are subtypes of this type.

* `Left(value)` typically represents an error, exception, or alternative (non-successful) outcome.
* `Right(value)` typically represents a successful result or a valid computation.

See also [`Left`](@ref) and [`Right`](@ref).
"""
abstract type EitherType end

"""
    Left{L}

Typically represents an error, exception, or alternative (non-successful) outcome.
See also [`EitherType`](@ref) and [`Right`](@ref).
"""
struct Left{L<:Any} <: EitherType
    value::L
end

"""
    Right{R}

Typically represents a successful result or a valid computation.
See also [`EitherType`](@ref) and [`Left`](@ref).
"""
struct Right{R<:Any} <: EitherType
    value::R
end

HolyMonads.monadtype(::Type{EitherClass}) = EitherType
HolyMonads.MonadClass(::Type{<:EitherType}) = Either

# unit (or instantiate)
HolyMonads.unit(::EitherClass, value::R) where R = Right{R}(value)
(::EitherClass)(value::R) where R = Right{R}(value)

# mjoin
HolyMonads.mjoin(::EitherClass, m::EitherType) = m.value::EitherType
HolyMonads.mjoin(::EitherClass, m::Left) = m

# fmap
function HolyMonads.fmap(f::Callable, ::EitherClass, e::EitherType)
    if isleft(e)
        return e
    end
    try
        Right(f(e.value))
    catch err
        Left(err)
    end
end

# # mbind  # use default implementation

"""
    @either begin ～ end
    @either() do ～ end

Alias for `@do Either begin ～ end`.
"""
macro either(ex)
    if Base.is_expr(ex, :(->))
        # Do block syntax
        HolyMonads._monad_do(Either, ex.args[2])
    else
        HolyMonads._monad_do(Either, ex)
    end
end

# utility functions
"""
    fromleft(e::EitherType, default=nothing)

Extracts the value from a `Left` instance or returns a default value if the instance is not `Left`.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.EitherMonad

julia> fromleft(Left("An Error"))
"An Error"

julia> fromleft(Right(:ok))
#> nothing
```
"""
fromleft(::EitherType, default=nothing) = default
fromleft(e::Left, _default) = e.value
"""
    fromright(e::EitherType, default=nothing)

Extracts the value from a `Right` instance or returns a default value if the instance is not `Right`.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.EitherMonad

julia> fromleft(Right(:ok))
:ok

julia> fromleft(Left("An Error"))
#> nothing
```
"""
fromright(::EitherType, default=nothing) = default
fromright(e::Right, _default) = e.value

"""
    isleft(e::EitherType)

Checks if the instance is a `Left` instance.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.EitherMonad

julia> isleft(Left("An Error"))
true

julia> isleft(Right(:ok))
false
```
"""
isleft(::EitherType) = false
isleft(::Left) = true
"""
    isright(e::EitherType)

Checks if the instance is a `Right` instance.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.EitherMonad

julia> isright(Right(:ok))
true

julia> isright(Left("An Error"))
false
```
"""
isright(::EitherType) = false
isright(::Right) = true

"""
    matchleft(f::Callable, e::EitherType)

Applies the function `f` to the value of a `Left` instance. If the instance is not `Left`, it returns `nothing`.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.EitherMonad

julia> matchleft(x -> 2x, Left(1))
2

julia> matchleft(x -> 2x, Right(1))
nothing
```
"""
matchleft(::Callable, ::EitherType) = nothing
matchleft(f::Callable, e::Left) = f(e.value)

"""
    matchright(f::Callable, e::EitherType)

Applies the function `f` to the value of a `Right` instance. If the instance is not `Right`, it returns `nothing`.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.EitherMonad

julia> matchright(x -> 2x, Right(1))
2

julia> matchright(x -> 2x, Left(1))
nothing
```
"""
matchright(::Callable, ::EitherType) = nothing
matchright(f::Callable, e::Right) = f(e.value)

"""
    lefts(eithers::AbstractArray{<:EitherType})

Returns an array of values from `Left` instances in the input array.
If the instance is not `Left`, it is ignored.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.EitherMonad

julia> eithers = [Right(1), Left(2), Right(3), Left(4)];

julia> lefts(eithers)
2-element Vector{Int64}:
 2
 4
```
"""
lefts(eithers::AbstractArray{<:EitherType}) = [e.value for e in eithers if isleft(e)]
"""
    rights(eithers::AbstractArray{<:EitherType})

Returns an array of values from `Right` instances in the input array.
If the instance is not `Right`, it is ignored.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.EitherMonad

julia> eithers = [Right(1), Left(2), Right(3), Left(4)];

julia> rights(eithers)
2-element Vector{Int64}:
 1
 3
```
"""
rights(eithers::AbstractArray{<:EitherType}) = [e.value for e in eithers if isright(e)]
"""
    partitioneither(eithers::AbstractArray{<:EitherType})

Returns a tuple of two arrays: the first contains values from `Left` instances, and the second contains values from `Right` instances.

# Example

```julia-repl
julia> using HolyMonads

julia> using HolyMonads.EitherMonad

julia> eithers = [Right(1), Left(2), Right(3), Left(4)];

julia> partitioneither(eithers)
([2, 4], [1, 3])
```
"""
partitioneither(eithers::AbstractArray{<:EitherType}) = (lefts(eithers), rights(eithers))

end  # module
