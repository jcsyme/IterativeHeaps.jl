"""
Implementation of 2-way heap derived from iGraph
"""
module RandomQueues

export get
export queue_pop!
export RandomQueue


import Base:
    @propagate_inbounds
    isempty
    iterate
    length
    size



####################
#    STRUCTURES    #
####################

"""
Construct a random heap (queue).


##  Constructs and Initialization

```
RandomQueue{T<:Real}(
    max_size::Int64;
    data::Union{Vector{T}, Nothing} = nothing,
    index::Union{Vector{Int64}, Nothing} = nothing,
    index_lookup::Union{Vector{Int64}, Nothing} = nothing,
) <: AbstractKHeap{T}
```


##  Initialization Arguments

- `max_size`: maximum heap size, 1 <= max_size


##  Keyword Arguments

-  `data`: optional vector to use for heap operations. If passed, does not have
    to instantiate a new vector
- `index`: An integer index associated to each item in the heap; this vector is
    always modified in tandem with `data`. Values in this vector are between 
    1 and size
- `index_lookup`:  A reverse index that allows O(1) lookup of the position of a 
    given value within the `index` member. NOTE: the following text is from 
        iGraph
        * `index2[i] == 0` means that `i` is not in `index` at all, while 
        * `index2[i] == 1` means that `i` is in `index` but it was _deactivated_
    The semantics of deactivation is up to the user of the data structure to 
    decide. Other than these two special values, `index2[i] == j` means that 
    `index[j-2] == i` and `data[j - 2]` is the corresponding item in the heap
"""
struct RandomQueue{T<:Real}
    data::Union{Vector{T}, Nothing} # The items themselves in the heap
    index::Union{Vector{Int64}, Nothing} # integer index storing the order in which original values were popped
    size::Vector{Int64} # size of the heap

    function RandomQueue{T}(
        data::Vector{T};
        index::Union{Vector{Int64}, Nothing} = nothing,
    ) where {T}

        # initialize heap vectors (allows for vectors to be passed)
        max_size = length(data)
        index = initialize_vector(index, max_size, Int64)
        size = Vector{Int64}([max_size])

        return new{T}( 
            data,
            index,
            max_size,
            size,
        )
    end
end



############################################
#    SOME BASE FUNCTION IMPLEMENTATIONS    #
############################################


function Base.isempty(
    heap::RandomQueue
)
    out = (heap.size[1] == 0)
    return out
end



function Base.iterate(
    iter::RandomQueue,
    state::Tuple = (iter, 1),
)
    #iterator, count = state
    (state[2] > iter.size[1]) && (return nothing)
    element = iter.data[state[2]]

    return (element, (iter, state[2] + 1))
end



function Base.length(heap::RandomQueue)
    return heap.size[1]
end






###################
#    FUNCTIONS    #
###################

"""
Get the data element associated with the index `ind`

## Constructs

```
get(
    heap::AbstractKHeap,
    ind::Int64,
    noval::Any = nothing,
)
```


##  Function Arguments

- `heap`: AbstractKHeap to retrieve value from
- `ind`: index for which to retrieve element
- `noval`: (OPTIONAL) return value to use if item is not present. If 
    unspecified, returns `nothing`


##  Keyword Arguments

"""
function get(
    heap::RandomQueue,
    ind::Int64,
    noval::Any = nothing;
    check_index::Bool = true,
)
    !heap_index_is_in(heap, ind) && (return noval)

    pos_extract = heap.index_lookup[ind] - 2
    elem = heap.data[pos_extract]

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
    heap::AbstractKHeap{T},
) where {T}
    return T
end



"""
Check if index `ind` is in heap `h`. NOTE: Excludes deactivated indices.

## Constructs

```
heap_index_is_in(
    h::AbstractKHeap,
    ind::Int64;
    check_index::Bool = false,
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
    h::RandomQueue,
    ind::Int64;
)::Bool

    out = (ind < h.max_size + 1) & (ind > 0)

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

- `queue`: RandomQueue to pop minimum element from


##  Keyword Arguments

"""
@inline function queue_pop!(
    queue::RandomQueue{T};
) where {T}

    @inbounds begin
        (queue.size[1] == queue.max_size) && (return nothing)

        elem = heap.data[1]
        ind = heap.index[1]

        # swap and pop--shift the first element/ind to back and remove
        heap_swap_unsafe!(heap, 1, heap.size[1])
        heap.data[heap.size[1]] = zero(T) 
        heap.index[heap.size[1]] = 0

        heap.size[1] -= 1

        # update the lookup index
        heap.index_lookup[ind] = 0
    end

    percolate_down!(heap, 1)
   
    return (ind, elem)
end



"""
Initialize a vector

##  Constructs

```
initialize_vector(
    vec::Union{Vector{T}, Nothing},
    size::Int64,
    U::DataType = Float64;
    fill_func::Function = zero,
) where {T<:Real}
```

##  Function Arguments

- `vec`: Vector object to initialize. If nothing, returns a new vector size
    `size` with element types `U`
- `size`: size of the vector
- `U`: (OPTIONAL) element type for the Vector


##  Keyword Arguments

- `fill_func`: `zero` to fill with zeros of `typemax` to set using maximum
    value for type `T`
"""
function initialize_vector(
    vec::Union{Vector{T}, Nothing},
    size::Int64,
    U::DataType = Float64;
    fill_func::Function = zero,
) where {T<:Real}

    # if nothing, return a vector of zeros
    if isa(vec, Nothing)
        vec = zeros(U, size)
        (fill_func == zero) && (return vec)

        fill!(vec, fill_func(U))
        return vec
    end
 
    # otherwise, verify shape
    (size != length(vec)) && resize!(vec, size)
    fill!(vec, fill_func(T))

    return vec
end



"""
Index of generic child to `index_node` in AbstractKHeap. Returns the ith child 
    (0-indexed)

##  Constructs

```
node_child(
    index_node::Int64, 
    i::Int64,
    k::Int64,
)
```


##  Function Arguments

- `index_node`: index of the node for which a child should be retrieved
- `i`: ith child; for left-most, use 1; right most is heap.k (does not check 
    for i <= k)


##  Keyword Arguments

- `k`: size of k-ary heap
"""
@inline function node_child(
    index_node::Int64, 
    i::Int64,
    k::Int64,
)
    return k*(index_node - 1) + i + 1
end



"""
Index of left child to `index_node` in BinaryHeap
"""
function node_child_left(index_node::Int64)
    return 2*index_node
end



"""
Index of right child to `index_node` in BinaryHeap
"""
function node_child_right(index_node::Int64)
    return 2*index_node + 1
end



"""
Index of parent to `index_node` in AbstractKHeap
"""
@inline function node_parent(
    index_node::Int64,
    k::Int64,
)
    (index_node <= 1) && return 1
    #out = floor(Int64, (index_node + k - 2)/k)
    out = div(index_node + k - 2, k)

    return out
end



"""
After popping an element, the ordering has to be re-evaluated, and the root may
    have to percolate down.

##  Constructs

```
percolate_down!(
    heap::AbstractKHeap,
    ind_parent::Int64,
)
```


##  Function Arguments

- `heap`: heap to perform down percolation on
- `ind_parent`: heap index (position in heap) parent to check


##  Keyword Arguments

- `check_index`: verify that the index is not already in the heap?

"""
@inline @propagate_inbounds function percolate_down!(
    heap::BinaryHeap,
    ind_parent::Int64;
    check_index::Bool = false,
)
    if check_index
        #!heap_index_is_in(heap, ind_parent) && (return nothing)
        (ind_parent > heap.size[1]) && (return nothing)
    end

    # skip if ind_parent has no children
    ind_cl = node_child_left(ind_parent)
    (ind_cl > heap.size[1]) && (return nothing)
    
    # following code only applies if the right child can be accessed
    # otherwise, popping the first element could mean that the left branch
    # is now less than its parent
    ind_cr = node_child_right(ind_parent)
    ind_cr_invalid = (ind_cr > heap.size[1])

    cond_1 = ind_cr_invalid
    cond_1 |= !cond_1 ? (heap.data[ind_cl] <= heap.data[ind_cr]) : false
    
    if cond_1
        # sink to left if necesary
        if heap.data[ind_parent] > heap.data[ind_cl]
            heap_swap_unsafe!(heap, ind_parent, ind_cl)
            percolate_down!(heap, ind_cl)
        end
    elseif !ind_cr_invalid
        if heap.data[ind_parent] > heap.data[ind_cr]
            # sink to right
            heap_swap_unsafe!(heap, ind_parent, ind_cr)
            percolate_down!(heap, ind_cr)
        end
    end
end


@inline @propagate_inbounds function percolate_down!(
    heap::AbstractKHeap,
    ind_parent::Int64;
    check_index::Bool = false,
)

    check_index && ((ind_parent > heap.size[1]) && (return nothing))

    # skip if ind_parent has no children
    ind_cl = node_child(ind_parent, 1, heap.k)
    (ind_cl > heap.size[1]) && (return nothing)
    
    ind_cr_max = min(
        heap.size[1], 
        node_child(ind_parent, heap.k, heap.k)
    )
    
    # get index in children of minimum element
    i_min = (ind_cl == ind_cr_max) ? ind_cl : 0   
    @inbounds begin
        if i_min == 0 
            min_val = Inf
            for i in ind_cl:ind_cr_max
                (heap.data[i] < min_val) && (min_val = heap.data[i]; i_min = i)
            end
        end

        if heap.data[ind_parent] > heap.data[i_min]
            heap_swap_unsafe!(heap, ind_parent, i_min)
            percolate_down!(heap, i_min)
        end
    end
end



"""
Elevate an element through the k heap tree (min constitute root)
"""
@inline @propagate_inbounds function percolate_up!(
    heap::AbstractKHeap,
    index::Int64,
)

    ind_parent = node_parent(index, heap.k, )
    @inbounds begin
        ((index == 1) | (heap.data[index] > heap.data[ind_parent])) && (return nothing)
    end
    #
    heap_swap_unsafe!(heap, index, ind_parent)
    percolate_up!(heap, ind_parent)
end


# end module
end