"""
Implementation of a simple queue
"""


####################
#    STRUCTURES    #
####################

"""
Construct a simple queue.


##  Constructs and Initialization

```
SimpleQueue{T<:Real}(
    max_size::Int64;
    index::Union{Vector{T}, Nothing}
)
```


##  Initialization Arguments

- `max_size`: maximum heap size, 1 <= max_size


##  Keyword Arguments

- `force_unsafe_index_init`: force the index vector to initialize with the 
    assumption that it is of size `max_size` and has no zeros
- `index`: optional vector to specify as index.
"""
struct SimpleQueue{T<:Real}
    index::Union{Vector{T}, Nothing}
    len::Vector{Int64} # size of the heap
    max_size::Int64
    missing_val::T

    function SimpleQueue{T}(
        max_size::Int64;
        force_unsafe_index_init::Bool = false,
        index::Union{Vector{T}, Nothing} = nothing,
        missing_val::T = zero(T),
    ) where {T}

        # initialize the queue index
        if isa(index, Vector)

            if force_unsafe_index_init
                (length(index) != max_size) && error("Error initializing SimpleQueue: vector index must have length $(max_size)")
                len = max_size
            else
                min_val = findall((x -> (x != missing_val), index))
                len = length(min_val)
                index = [index[min_val]; missing_val*ones(T, max_size - len)]
                
            end
        else
            index = initialize_vector(index, max_size, T)
            len = 0
        end

        len = Vector{Int64}([len])


        return new{T}( 
            index,
            len,
            max_size,
            missing_val,
        )
    end
end



############################################
#    SOME BASE FUNCTION IMPLEMENTATIONS    #
############################################


function Base.isempty(
    heap::SimpleQueue{T}
) where {T}
    out = (heap.len[1] == 0)
    return out
end



function Base.iterate(
    iter::SimpleQueue{T},
    state::Tuple = (iter, 1),
)  where {T}
    #iterator, count = state
    (state[2] > iter.size[1]) && (return nothing)
    element = iter.index[state[2]]

    return (element, (iter, state[2] + 1))
end



function Base.length(
    heap::SimpleQueue{T}
) where {T}
    return heap.len[1]
end






###################
#    FUNCTIONS    #
###################

"""Fill a queue with random order. If setting `n`, fills up to `n` elements;
    otherwise, fills the entire queue.

# Constructs

```
fill_and_randomize_queue!(
    queue::SimpleQueue{T},
    n::Int64,
)
```

```
fill_and_randomize_queue!(
    queue::SimpleQueue{T},
)
```

Fill 
"""
function fill_and_randomize_queue!(
    queue::SimpleQueue{T},
    n::Int64,
) where {T}
    reset!(queue)
    heap_push!(
        queue,
        shuffle(1:max(min(queue.max_size, n), 0))
    )
    
    return nothing
end

function fill_and_randomize_queue!(
    queue::SimpleQueue{T},
) where {T}
    fill_and_randomize_queue!(
        queue,
        queue.max_size,
    )
    
    return nothing
end



"""
Get the data element associated with the index `ind`

## Constructs

```
get(
    heap::SimpleQueue{T},
    ind::Int64,
)
```


##  Function Arguments

- `heap`: AbstractKHeap to retrieve value from
- `ind`: index for which to retrieve element


##  Keyword Arguments

"""
function Base.get(
    heap::SimpleQueue{T},
    ind::Int64;
    noval::Union{Real, Nothing} = nothing,
) where {T}
    # return no value?
    !heap_index_is_in(heap, ind) && (return noval)

    # return element
    elem = heap.index[ind]

    return elem
end



"""
Retrieve the data type of the heap

## Constructs

```
heap_data_type(
    heap::BinaryHeap{T},
)
```
"""
function heap_data_type(
    heap::SimpleQueue{T},
) where {T}
    return T
end



"""
Check if index `ind` is in heap `h`. NOTE: Excludes deactivated indices.

## Constructs

```
heap_index_is_in(
    h::SimpleQueue{T},
    ind::Int64;
)::Bool
```

## Function Arguments

- `h`: heap to check
- `ind`: index to check for


## Keyword Arguments

- `check_index`: default is `false`. Set to `true` to verify the index is a 
    valid option based on the heap size

"""
function heap_index_is_in(
    h::SimpleQueue{T},
    ind::Int64;
)::Bool where {T}

    out = (ind < h.len[1] + 1) & (ind > 0)

    return out
end



"""
Remove the minimum element from the heap

##  Constructs

```
heap_pop!(
    heap::AbstractKHeap
)
```


##  Function Arguments

- `queue`: SimpleQueue to pop minimum element from


##  Keyword Arguments

"""
@inline function heap_pop!(
    heap::SimpleQueue{T};
) where {T}

    (heap.len[1] == 0) && (return nothing)

    @inbounds begin

        elem = heap.index[1]

        n = heap.len[1]
        heap.index[1:(n - 1)] .= heap.index[2:n]

        # drop the size 
        heap.len[1] -= 1
        heap.index[n] = 0
        
    end

   
    return elem
end



"""
Push a new element to the simple queue

##  Constructs

```
heap_push!(
    heap::SimpleQueue{T},
    val::T;
)
```

```
function heap_push!(
    heap::SimpleQueue{T},
    vals::Vector{T};
)
```


##  Function Arguments

- `heap`: SimpleQueue to push to
- `val`: value to push to queue
- `vals`: ordered vector of values to push

##  Keyword Arguments

"""
@inline function heap_push!(
    heap::SimpleQueue{T},
    val::T;
) where {T}

    (heap.len[1] == heap.max_size) && (return nothing)

    @inbounds begin

        heap.len[1] += 1
        n = heap.len[1]

        heap.index[n] = val
    end

   
    return nothing
end

@inline function heap_push!(
    heap::SimpleQueue{T},
    vals::Vector{T};
) where {T}

    (heap.len[1] == heap.max_size) && (return nothing)

    n_push = heap.max_size - heap.len[1]
    n_push = min(n_push, length(vals))

    @inbounds begin

        n = heap.len[1] + 1
        heap.len[1] += n_push
        sz = heap.len[1]

        heap.index[n:sz] .= vals[1:n_push]
    end

   
    return nothing
end



"""Reset a queue by filling with missing_vals and dropping length
    to 0.
"""
function reset!(
    queue::SimpleQueue{T},
) where {T}
    
    fill!(queue.index, queue.missing_val)
    queue.len[1] = 0
end

