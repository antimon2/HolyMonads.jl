# HolyMonads.jl

Implementation of Monads and `do` notation in Julia, utilizing Holy's trait mechanism.

[![Build Status](https://github.com/antimon2/HolyMonads.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/antimon2/HolyMonads.jl/actions/workflows/CI.yml?query=branch%3Amain) [![DeepWiki](https://img.shields.io/badge/DeepWiki-antimon2%2FHolyMonads.jl-blue.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAyCAYAAAAnWDnqAAAAAXNSR0IArs4c6QAAA05JREFUaEPtmUtyEzEQhtWTQyQLHNak2AB7ZnyXZMEjXMGeK/AIi+QuHrMnbChYY7MIh8g01fJoopFb0uhhEqqcbWTp06/uv1saEDv4O3n3dV60RfP947Mm9/SQc0ICFQgzfc4CYZoTPAswgSJCCUJUnAAoRHOAUOcATwbmVLWdGoH//PB8mnKqScAhsD0kYP3j/Yt5LPQe2KvcXmGvRHcDnpxfL2zOYJ1mFwrryWTz0advv1Ut4CJgf5uhDuDj5eUcAUoahrdY/56ebRWeraTjMt/00Sh3UDtjgHtQNHwcRGOC98BJEAEymycmYcWwOprTgcB6VZ5JK5TAJ+fXGLBm3FDAmn6oPPjR4rKCAoJCal2eAiQp2x0vxTPB3ALO2CRkwmDy5WohzBDwSEFKRwPbknEggCPB/imwrycgxX2NzoMCHhPkDwqYMr9tRcP5qNrMZHkVnOjRMWwLCcr8ohBVb1OMjxLwGCvjTikrsBOiA6fNyCrm8V1rP93iVPpwaE+gO0SsWmPiXB+jikdf6SizrT5qKasx5j8ABbHpFTx+vFXp9EnYQmLx02h1QTTrl6eDqxLnGjporxl3NL3agEvXdT0WmEost648sQOYAeJS9Q7bfUVoMGnjo4AZdUMQku50McDcMWcBPvr0SzbTAFDfvJqwLzgxwATnCgnp4wDl6Aa+Ax283gghmj+vj7feE2KBBRMW3FzOpLOADl0Isb5587h/U4gGvkt5v60Z1VLG8BhYjbzRwyQZemwAd6cCR5/XFWLYZRIMpX39AR0tjaGGiGzLVyhse5C9RKC6ai42ppWPKiBagOvaYk8lO7DajerabOZP46Lby5wKjw1HCRx7p9sVMOWGzb/vA1hwiWc6jm3MvQDTogQkiqIhJV0nBQBTU+3okKCFDy9WwferkHjtxib7t3xIUQtHxnIwtx4mpg26/HfwVNVDb4oI9RHmx5WGelRVlrtiw43zboCLaxv46AZeB3IlTkwouebTr1y2NjSpHz68WNFjHvupy3q8TFn3Hos2IAk4Ju5dCo8B3wP7VPr/FGaKiG+T+v+TQqIrOqMTL1VdWV1DdmcbO8KXBz6esmYWYKPwDL5b5FA1a0hwapHiom0r/cKaoqr+27/XcrS5UwSMbQAAAABJRU5ErkJggg==)](https://deepwiki.com/antimon2/HolyMonads.jl)
<!-- DeepWiki badge generated by https://deepwiki.ryoppippi.com/ -->

## Installation

To install the release version, simply run on the Julia Pkg REPL-mode:

```julia
pkg> add HolyMonads
```

If you want to use the latest development version:

```julia
pkg> dev https://github.com/antimon2/HolyMonads.jl
```

## Usage

### Preset Monad Sample: `Maybe`

```julia
using HolyMonads
using HolyMonads.MaybeMonad

unit_3 = Maybe.unit(3)  # same as `unit(Maybe, 3)`
#> Some(3)
@assert unit_3 isa MaybeMonad.MaybeType
@assert nothing isa MaybeMonad.MaybeType
Maybe.fmap(x -> x + 1, unit_3)  # same as `fmap(x -> x + 1, Maybe, unit_3)`
#> Some(4)
@assert isnothing(Maybe.fmap(x -> x + 1, nothing))

Maybe.@do begin  # same as `@do Maybe begin ～`
    x ← unit_3
    y ← Some(4)
    return x + y
end
#> Some(7)

Maybe.@do begin
    x ← unit_3
    y ← nothing  # Will short-circuit
    return x + y
end
#> nothing
```

Wherer `Some` and `nothing` are built-in types/values in Julia and can be directly used as the context of a Maybe monad. The `@do` macro will automatically short-circuit when it encounters `nothing`. The `←` operator (\leftarrow + <kbd>Tab</kbd>) can only be used inside the `@do` notation.

See also: [Maybe Monad (by DeepWiki)](https://deepwiki.com/antimon2/HolyMonads.jl/6-maybe-monad)

#### Other Preset Monads

* [Identity Monad (by DeepWiki)](https://deepwiki.com/antimon2/HolyMonads.jl/5-identity-monad)
* [List Monad (by DeepWiki)](https://deepwiki.com/antimon2/HolyMonads.jl/7-list-monad)
* [Either Monad (by DeepWiki)](https://deepwiki.com/antimon2/HolyMonads.jl/8-either-monad)

### Custom Monads

You can define your own custom monads.  
For example, here is how you can define a monad called `MyMonad`.

#### 1. Define a monad class

Define a singleton type that is a subtype of `MonadClass` (or `MonadPlusClass`).

```julia
using HolyMonads

struct MyMonadClass <: MonadClass end
const MyMonad = MyMonadClass()
```

_This becomes a trait type in the Holy Trait system, functioning similarly to type classes in other languages._

#### 2. Define the monadic context (monad type)

You may use an existing type or define a new one. Here we define a new type:

```julia
struct MyMonadType{T}
    value::T
end
```

#### 3. Associate the monad class with the monadic context

```julia
monadtype(::Type{MyMonadClass}) = MyMonadType
MonadClass(::Type{<:MyMonadType}) = MyMonad
```

* `monadtype()` takes a monad class type and returns the corresponding monadic context type.
* `MonadClass()` takes a monadic context type and returns the corresponding monad class.

#### 4. Implement `unit()` (optional)

The default implementation of `HolyMonads.unit()` is as follows, so redefining it is unnecessary if this default behavior is sufficient:

```julia
# HolyMonads.unit(::MT, value) where {MT <: MonadClass} = monadtype(MT)(value)
HolyMonads.unit(::MyMonadClass, value) = MyMonadType(value)
```

You may override it or add method specializations as needed.

#### 5. Implement `mbind()` (and/or `mjoin()`, `fmap()`)

By default, `mjoin()` and `fmap()` are implemented using `mbind()`. Therefore, if you provide a correct implementation of `mbind()`, you get `mjoin()` and `fmap()` for free.

```julia
HolyMonads.mbind(f::Base.Callable, ::MyMonadClass, m::MyMonadType) = f(m.value)::MyMonadType
```

Alternatively, `mbind()` is also defined by default using `mjoin()` and `fmap()`.
So, if you correctly implement `mjoin()` and `fmap()`, `mbind()` will be automatically available (example omitted).

Depending on the monad, you may want to implement all three — `mbind()`, `mjoin()`, and `fmap()` — in the most efficient way.

These functions should satisfy the [Monad laws](https://en.wikipedia.org/wiki/Monad_(functional_programming)#Definition).

#### 6. Implement `mzero()`, `mplus()` (optional)

These are only necessary if your monad is an instance of `MonadPlusClass` (examples omitted). They are not required for plain `MonadClass`.

## Related packages

* [Monads.jl](https://github.com/ulysses4ever/Monads.jl): Simple Monad implementation in Julia, without trait system. (Maybe not maintained ?)
    * HolyMonads.jl is inspired by this package (not a fork). 
* [TypeClasses.jl](https://github.com/JuliaFunctional/TypeClasses.jl?tab=readme-ov-file): A package aimed at enabling functional programming features by reusing standard APIs. Also provides a simple monad interface.
* [DataTypesBasic.jl](https://github.com/JuliaFunctional/DataTypesBasic.jl): A package that defines basic data types commonly used in monads, such as `Option` (a.k.a. `Maybe`) and `Either`.
* [Monadic.jl](https://github.com/JuliaFunctional/Monadic.jl): Provides macro-based syntax similar to `do` notation. Can be used in combination with DataTypesBasic.jl.
