module MonadIterators

import ..HolyMonads: HolyMonads, MonadClass
# using Base: iterate

export miterator

function miterator end

struct MonadIterator{MC <: MonadClass, MT}
    m::MT

    function MonadIterators.miterator(M::MC, m::MT) where {MC <: MonadClass, MT}
        _MT = HolyMonads.monadtype(M)
        @assert MT <: _MT lazy"Monad type mismatch: expected $(_MT), got $(MT)"
        new{MC, MT}(m)
    end
end

miterator(m) = miterator(HolyMonads.MonadClass(m), m)

Base.IteratorSize(::MonadIterator{MC, MT}) where {MC, MT} = Base.SizeUnknown()
Base.IteratorEltype(::MonadIterator{MC, MT}) where {MC, MT} = Base.EltypeUnknown()

function Base.iterate(mi::MonadIterator{MC, MT}) where {MC <: MonadClass, MT}
    HolyMonads.ispure(MC(), mi.m) || return nothing
    (HolyMonads.unpure(MC(), mi.m), nothing)
end
Base.iterate(::MonadIterator, ::Nothing) = nothing

end  # module MonadIterators
