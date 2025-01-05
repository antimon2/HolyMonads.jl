module ListMonad

import ..HolyMonads
using Base: Callable

export List, @list

struct ListClass{T} <: HolyMonads.MonadPlusClass end
const _ListClassBottom = ListClass{Union{}}
const List = _ListClassBottom()
(::_ListClassBottom)(::Type{T}) where T = ListClass{T}()

const ListType{T} = AbstractVector{T}

HolyMonads.monadtype(::_ListClassBottom) = ListType
HolyMonads.monadtype(::ListClass{T}) where T = ListType{T}
HolyMonads.MonadClass(::Type{<:ListType}) = List
HolyMonads.MonadClass(::Type{<:ListType{T}}) where T = List(T)

# unit
HolyMonads.unit(::ListClass, value::T) where T = T[value]
HolyMonads.unit(::ListClass, value::AbstractArray{T}) where T = HolyMonads.mjoin(List(T), [value])

# mjoin
function HolyMonads.mjoin(::_ListClassBottom, m)
    @assert m isa AbstractArray{<:AbstractArray}
    T = eltype(eltype(m))
    HolyMonads.mjoin(List(T), m)
end
function HolyMonads.mjoin(::ListClass{T}, m) where T
    isempty(m) && return HolyMonads.mzero(List(T))
    # T.(Iterators.flatten(m))
    result = T[]
    for value in m
        append!(result, value)
    end
    isempty(result) && return HolyMonads.mzero(List(T))
    result
end

# fmap
function HolyMonads.fmap(f::Callable, ::ListClass, m)
    ET = eltype(m)
    T = Core.Compiler.return_type(f, Tuple{ET})
    HolyMonads.unit(List(T), map(f, vec(m)))
end

# mbind
HolyMonads.mbind(f::Callable, L::ListClass, m) = HolyMonads.mjoin(L, HolyMonads.fmap(f, List, m)::AbstractArray)

HolyMonads.mzero(::_ListClassBottom) = Any[]
HolyMonads.mzero(::ListClass{T}) where T = T[]
HolyMonads.mplus(::_ListClassBottom, a, b) = HolyMonads.mjoin(List, [a, b])
HolyMonads.mplus(::ListClass{T}, a, b) where T = HolyMonads.mjoin(List(T), [a, b])

macro list(ex)
    if Base.is_expr(ex, :(->))
        # Do block syntax
        HolyMonads._monad_do(List, ex.args[2])
    else
        HolyMonads._monad_do(List, ex)
    end
end

macro list(ex1, ex2)
    if Base.is_expr(ex1, :(->))
        # Do block syntax
        MonadClass = esc(:(List($ex2)))
        HolyMonads._monad_do(MonadClass, ex1.args[2])
    else
        MonadClass = esc(:(List($ex1)))
        HolyMonads._monad_do(MonadClass, ex2)
    end
end

end  # module
