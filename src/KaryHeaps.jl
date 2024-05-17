"""
Implementation of k-ary heaps (k = 2 is a Binary Heap). Includes structures
    designed to support iterative heaping through the use of cache arrays,
    including SharedArrays for repeated calling of heaps (e.g., through 
    parallelized calling of Dijkstra's algorithm) on worker nodes.


# Key Constructs

- `BinaryHeap`
- `KaryHeap`
- `KaryHeapShared`

"""

#=
using Distributed
using SharedArrays

export AbstractKHeap
export BinaryHeap3
export get
export heap_data_type
export heap_index_is_deactivated
export heap_index_is_in
export heap_modify!
export heap_push!
export heap_swap_unsafe!
export initialize_shared_array
export initialize_vector
export KaryHeap
export KaryHeapShared
export node_child_left
export node_child_right
export node_parent
export percolate_down!
export percolate_up!

import Base:
    @propagate_inbounds
    isempty
    iterate
    length
    size
=#


####################
#    STRUCTURES    #
####################

# some types
abstract type AbstractKHeap{T} end
VMSOrNoth{T} = Union{Matrix{T}, SubArray{T}, Vector{T}, Nothing}
SAOrNoth{T} = Union{SharedArray{T}, Vector{T}, Nothing}

"""
Construct a generic k-ary heap that supports heaping indices (e.g., as indexed
    over an array). The KaryHeap pre-allocates space for data and indices to 
    reduce calls to push! and pull! + reduce memory footprints in iterations. 


##  Constructs and Initialization

```
KaryHeap{T<:Real}(
    max_size::Int64,
    k::Int64;
    data::Union{Vector{T}, Nothing} = nothing,
    index::Union{Vector{Int64}, Nothing} = nothing,
    index_lookup::Union{Vector{Int64}, Nothing} = nothing,
) <: AbstractKHeap{T}
```


##  Initialization Arguments

- `max_size`: maximum heap size, 1 <= max_size
- `k`: maximum number of leafs per parent node (i.e., `k`-ary)


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
struct KaryHeap{T<:Real} <: AbstractKHeap{T}
    data::VMSOrNoth{T} # The items themselves in the heap
    index::VMSOrNoth{Int64}# integer index associated with each item in the heap
    index_lookup::VMSOrNoth{Int64} # reverse index that allows fo O(1) lookup
    max_size::Int64 # Maximum number of items in the heap
    size::Vector{Int64} # size of the heap
    k::Int64 # "k" in k-ary heap

    function KaryHeap{T}(
        max_size::Int64,
        k::Int64;
        data::VMSOrNoth{T} = nothing,
        index::VMSOrNoth{Int64} = nothing,
        index_lookup::VMSOrNoth{Int64} = nothing,
    ) where {T}

        (max_size < 1) && error("Error initializing KaryHeap: invalid max_size = $(max_size) (must be geq 1)")
        
        # initialize heap vectors (allows for vectors to be passed)
        data = initialize_vector(data, max_size, T) # Vector{T}()
        index = initialize_vector(index, max_size, Int64) # Vector{Int64}() 
        index_lookup = initialize_vector(index_lookup, max_size, Int64)

        size = Vector{Int64}([0])

        return new{T}(
            data,
            index,
            index_lookup,
            max_size,
            size,
            k
        )
    end
end




"""
Construct a generic k-ary heap that supports heaping indices (e.g., as indexed
    over an array) on a SharedArray. The KaryHeapShared pre-allocates space for
    and reduce calls to push! and pull! to reduce memory footprints in 
    distributed iterations that rely on a heap.

The `KaryHeapShared` allows each worker node acccess to columns in 
    SharedArrays for data, index, and index_lookup storage.


##  Constructs and Initialization

```
KaryHeapShared{T<:Real}(
    max_size::Int64,
    k::Int64;
    data::SAOrNoth{T} = nothing,
    index::SAOrNoth{T} = nothing,
    index_lookup::SAOrNoth{T} = nothing,
) <: AbstractKHeap{T}
```


##  Initialization Arguments

- `max_size`: maximum heap size, 1 <= max_size
- `k`: maximum number of leafs per parent node (i.e., `k`-ary)


##  Keyword Arguments

- `data`: optional SharedArray to use for heap operations
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
struct KaryHeapShared{T<:Real} <: AbstractKHeap{T}
    data::SAOrNoth{T} # The items themselves in the heap
    index::SAOrNoth{Int64}# integer index associated with each item in the heap
    index_lookup::SAOrNoth{Int64} # reverse index that allows fo O(1) lookup
    max_size::Int64 # Maximum number of items in the heap
    size::SAOrNoth{Int64} # size of the heap
    k::Int64 # "k" in k-ary heap

    function KaryHeapShared{T}(
        max_size::Int64,
        k::Int64,
        data::SharedArray{T},
        index::SharedArray{Int64},
        index_lookup::SharedArray{Int64},
        size::SharedArray{Int64},
    ) where {T}

        (max_size < 1) && error("Error initializing KaryHeapShared: invalid max_size = $(max_size) (must be geq 1)")
        
        # initialize heap vectors (allows for vectors to be passed)
        data = initialize_shared_array(data, max_size, T)
        index = initialize_shared_array(index, max_size, Int64)
        index_lookup = initialize_shared_array(index_lookup, max_size, Int64)
        size = initialize_shared_array(size, 1, Int64)

        return new{T}(
            data,
            index,
            index_lookup,
            max_size,
            size,
            k
        )
    end
end



"""
Deried from igraph_2wheap_t (in igraph indheap.h). Store a 2-way heap indexed 
    from L -> R (min -> max) starting at 1. The minimum value is stored as the 
    root.


DESCRIPTIONS TAKEN FROM COMMENTS IN igraph indheap.h

- data: 
- index: An integer index associated to each item in the heap; this vector is
    always modified in tandem with `data`. Values in this vector are between 
    1 and size
- index2:  A _reverse_ index that allows O(1) lookup of the position of a given 
    value within the `index` member. Note that it uses two special values: 
        * `index2[i] == 0` means that `i` is not in `index` at all, while 
        * `index2[i] == 1` means that `i` is in `index` but it was _deactivated_
    The semantics of deactivation is up to the user of the data structure to 
    decide. Other than these two special values, `index2[i] == j` means that 
    `index[j-2] == i` and `data[j - 2]` is the corresponding item in the heap
"""
struct BinaryHeap3{T<:Real}
    data::VMSOrNoth{T} # The items themselves in the heap
    index::VMSOrNoth{Int64} # integer index associated with each item in the heap
    index_lookup::VMSOrNoth{Int64} # reverse index that allows fo O(1) lookup
    max_size::Int64 # Maximum number of items in the heap
    size::Vector{Int64} # size of the heap
    k::Int64 # "k" in k-ary heap
    
    """
    function BinaryHeap3{T}(
        max_size::Int64;
        data::Union{Vector{T}, Nothing} = nothing,
        index::Union{Vector{Int64}, Nothing} = nothing,
        index_lookup::Union{Vector{Int64}, Nothing} = nothing,
    ) where {T}

        (max_size < 1) && error("Error initializing Tw3oWayHeap: invalid max_size = $(max_size) (must be geq 1)")
        
        # initialize heap vectors (allows for vectors to be passed)
        data = initialize_vector(data, max_size) # Vector{T}()
        index = initialize_vector(index, max_size) # Vector{Int64}()# 
        index_lookup = initialize_vector(index_lookup, max_size)

        size = Vector{Int64}([0])
        k = 2

        return new{T}(
            data,
            index,
            index_lookup,
            max_size,
            size,
            k
        )
    end
    """

    function BinaryHeap3{T}(
        max_size::Int64;
        data::VMSOrNoth{T} = nothing,
        index::VMSOrNoth{Int64} = nothing,
        index_lookup::VMSOrNoth{Int64} = nothing,
    ) where {T<:Real}
        
        return KaryHeap{T}(
            max_size,
            2;
            data = data,
            index = index,
            index_lookup = index_lookup,
        )
    end
end



############################################
#    SOME BASE FUNCTION IMPLEMENTATIONS    #
############################################

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

- ``:

"""
function Base.get(
    heap::KaryHeap,
    ind::Int64,
    noval::Any = nothing;
    check_index::Bool = true,
)
    !heap_index_is_in(heap, ind; check_index = check_index, ) && (return noval)

    pos_extract = heap.index_lookup[ind] - 2
    elem = heap.data[pos_extract]

    return elem
end

function Base.get(
    heap::KaryHeapShared,
    ind::Int64,
    noval::Any = nothing;
    check_index::Bool = true,
)
    !heap_index_is_in(heap, ind; check_index = check_index, ) && (return noval)

    pos_extract = heap.index_lookup[ind, heap.index_lookup.pidx] - 2
    elem = heap.data[pos_extract, heap.data.pidx]

    return elem
end



function Base.isempty(
    heap::KaryHeap
)
    out = (heap.size[1] == 0)
    return out
end

function Base.isempty(
    heap::KaryHeapShared
)
    # check all sizes if calling from the coordinator
    (myid() == 1) && (return all(heap.size .== 0)) 
    
    out = (heap.size[heap.size.pidx] == 0)
    
    return out
end



function Base.iterate(
    iter::KaryHeap,
    state::Tuple = (iter, 1),
)
    #iterator, count = state
    (state[2] > iter.size[1]) && (return nothing)
    element = iter.data[state[2]]

    return (element, (iter, state[2] + 1))
end


function Base.iterate(
    iter::KaryHeapShared,
    state::Tuple = (iter, 1),
)
    (myid() == 1) && return nothing

    #iterator, count = state
    (state[2] > iter.size[iter.size.pidx]) && (return nothing)
    element = iter.data[state[2], iter.data.pidx]

    return (element, (iter, state[2] + 1))
end



function Base.length(heap::KaryHeap)
    return heap.size[1]
end

function Base.length(heap::KaryHeapShared)
    (myid() == 1) && return nothing
    return heap.size[heap.size.pidx]
end






###################
#    FUNCTIONS    #
###################





"""
Retrieve the data type of the heap

## Constructs

```
heap_data_type(
    heap::BinaryHeap3{T},
)
```
"""
function heap_data_type(
    heap::AbstractKHeap{T},
) where {T}
    return T
end



"""
Check if index `ind` is deactivated

## Constructs

```
heap_index_is_deactivated(
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
function heap_index_is_deactivated(
    h::KaryHeap,
    ind::Int64;
    check_index::Bool = false,
)::Bool
    
    if !check_index
        return (h.index_lookup[ind] == 1)
    end

    out = ((ind > h.size[1]) | (ind < 1)) ? false : (h.index_lookup[ind] == 1)

    return out
end

function heap_index_is_deactivated(
    h::KaryHeapShared,
    ind::Int64;
    check_index::Bool = false,
)::Bool
    
    if !check_index
        return (h.index_lookup[ind, h.index_lookup.pidx] == 1)
    end

    out = ((ind > h.size[h.size.pidx]) | (ind < 1)) ? false : (h.index_lookup[ind, h.index_lookup.pidx] == 1)

    return out
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
    h::KaryHeap,
    ind::Int64;
    check_index::Bool = false,
)::Bool
    if !check_index
        return (h.index_lookup[ind] > 1)
    end

    out = ((ind > h.max_size) | (ind < 1)) ? false : (h.index_lookup[ind] > 1)

    return out
end

function heap_index_is_in(
    h::KaryHeapShared,
    ind::Int64;
    check_index::Bool = false,
)::Bool
    if !check_index
        return (h.index_lookup[ind, h.heap_index_lookup.pidx] > 1)
    end

    out = ((ind > h.max_size) | (ind < 1)) ? false : (h.index_lookup[ind, h.index_lookup.pidx] > 1)

    return out
end



"""
Modify an existing key (e.g., decrease-key operation)

##  Constructs

```
heap_modify!(
    heap::AbstractKHeap{T},
    ind::Int64,
    value::T;
    check_index::Bool = false,
)
```


##  Function Arguments

- `heap`: AbstractKHeap to perform swap on
- `ind`: key to modify
- `value_new`: new value to assign to ind

##  Keyword Arguments

- `check_index`: verify that the index is not already in the heap?
- `push_on_missing`: if the index is missing, push it?
"""
@inline function heap_modify!(
    heap::KaryHeap{T},
    ind::Int64,
    value_new::T;
    check_index::Bool = true,
    push_on_missing::Bool = true,
) where {T}
    
    # if checking, don't allow pushing to the heap if a value has already been stored
    if push_on_missing & (heap.index_lookup[ind] == 0)
         heap_push!(
            heap, 
            value_new, 
            ind; 
            check_index = false,
        )
        return nothing
    end

    @inbounds index = heap.index_lookup[ind] - 2
    @inbounds heap.data[index] = value_new

    # shift up/down
    percolate_up!(heap, index)
    percolate_down!(heap, index)

    return nothing
end

@inline function heap_modify!(
    heap::KaryHeapShared{T},
    ind::Int64,
    value_new::T;
    check_index::Bool = true,
    push_on_missing::Bool = true,
) where {T}
    
    # if checking, don't allow pushing to the heap if a value has already been stored
    if push_on_missing & (heap.index_lookup[ind, heap.index_lookup.pidx] == 0)
         heap_push!(
            heap, 
            value_new, 
            ind; 
            check_index = false,
        )
        return nothing
    end

    @inbounds index = heap.index_lookup[ind, heap.index_lookup.pidx] - 2
    @inbounds heap.data[index, heap.data.pidx] = value_new

    # shift up/down
    percolate_up!(heap, index)
    percolate_down!(heap, index)

    return nothing
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

- `heap`: k-ary heap to pop minimum element from


##  Keyword Arguments

"""
@inline function heap_pop!(
    heap::KaryHeap{T};
) where {T}

    @inbounds begin
        (heap.size[1] == 0) && (return nothing)

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

@inline function heap_pop!(
    heap::KaryHeapShared{T};
) where {T}

    @inbounds begin
        (heap.size[heap.size.pidx] == 0) && (return nothing)

        elem = heap.data[1, heap.data.pidx]
        ind = heap.index[1, heap.index.pidx]

        # swap and pop--shift the first element/ind to back and remove

        sz = heap.size[heap.size.pidx]
        heap_swap_unsafe!(heap, 1, sz)
        heap.data[sz, heap.data.pidx] = zero(T) 
        heap.index[sz, heap.index.pidx] = 0

        heap.size[heap.size.pidx] -= 1

        # update the lookup index
        heap.index_lookup[ind, heap.index_lookup.pidx] = 0
    end

    percolate_down!(heap, 1)
   
    return (ind, elem)
end



"""
Add a key pair `ind => value` to the heap

##  Constructs

```
heap_push!(
    heap::AbstractKHeap{T},
    value::T,
    ind::Int64;
    check_index::Bool = false,
)
```


##  Function Arguments

- `heap`: AbstractKHeap to perform swap on
- `value`: value to push
- `index`: index, or key value, to push

##  Keyword Arguments

- `check_index`: verify that the index is not already in the heap?

"""
@inline function heap_push!(
    heap::KaryHeap{T},
    value::T,
    ind::Int64;
    check_index::Bool = false,
) where {T}
    
    # if checking, don't allow pushing to the heap if a value has already been stored
    if check_index
        (heap.index_lookup[ind] != 0) && (return nothing)
    end

    # update the size and vectors
    @inbounds begin
        heap.size[1] += 1

        heap.data[heap.size[1]] = value
        heap.index[heap.size[1]] = ind
        heap.index_lookup[ind] = heap.size[1] + 2
    end

    # shift node upwards in tree
    percolate_up!(heap, heap.size[1])

    return nothing
end

@inline function heap_push!(
    heap::KaryHeapShared{T},
    value::T,
    ind::Int64;
    check_index::Bool = false,
) where {T}
    
    # if checking, don't allow pushing to the heap if a value has already been stored
    if check_index
        (heap.index_lookup[ind, heap_index_lookup.pidx] != 0) && (return nothing)
    end

    # update the size and vectors
    @inbounds begin
        heap.size[heap.size.pidx] += 1
        sz = heap.size[heap.size.pidx]

        heap.data[sz, heap.data.pidx] = value
        heap.index[sz, heap.index.pidx] = ind
        heap.index_lookup[ind, heap.index_lookup.pidx] = sz + 2
    end

    # shift node upwards in tree
    percolate_up!(heap, heap.size[heap.size.pidx])

    return nothing
end



"""
Perform a swap on a heap. Uses igraph implementation with index_lookup and 
    adjusment of 2 to store special values of 0 and 1. If heap is a 
    KaryHeapShared, swaps are performed only on the workers' applicable column.

##  Constructs

```
heap_swap_unsafe!(
    heap::AbstractKHeap,
    i::Int64,
    j::Int64;
)
```

##  Function Arguments

- `heap`: AbstractKHeap to perform swap on
- `i`, `j`: indices to swap on Heap tree


##  Keyword Arguments

"""
@inline function heap_swap_unsafe!(
    heap::KaryHeap,
    i::Int64,
    j::Int64;
)
    @inbounds begin
        # before swapping index, update input indicies in lookup
        ind_i = heap.index[i]
        ind_j = heap.index[j]
        heap.index_lookup[ind_i] = j + 2
        heap.index_lookup[ind_j] = i + 2#j
        
        # swap data and indicies
        heap.data[i], heap.data[j] = heap.data[j], heap.data[i]
        heap.index[i], heap.index[j] = ind_j, ind_i;
    end
end

@inline function heap_swap_unsafe!(
    heap::KaryHeapShared,
    i::Int64,
    j::Int64;
)
    @inbounds begin
        kd = heap.data.pidx
        ki = heap.index.pidx
        kl = heap.index_lookup.pidx

        # before swapping index, update input indicies in lookup
        ind_i = heap.index[i, ki]
        ind_j = heap.index[j, ki]
        heap.index_lookup[ind_i, kl] = j + 2
        heap.index_lookup[ind_j, kl] = i + 2
        
        # swap data and indicies
        heap.data[i, kd], heap.data[j, kd] = heap.data[j, kd], heap.data[i, kd]
        heap.index[i, ki], heap.index[j, ki] = ind_j, ind_i;
    end
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
Index of left child to `index_node` in BinaryHeap3
"""
function node_child_left(index_node::Int64)
    return 2*index_node
end



"""
Index of right child to `index_node` in BinaryHeap3
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
    heap::BinaryHeap3,
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
    heap::KaryHeap,
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


@inline @propagate_inbounds function percolate_down!(
    heap::KaryHeapShared,
    ind_parent::Int64;
    check_index::Bool = false,
)

    sz = heap.size[heap.size.pidx]
    check_index && ((ind_parent > sz) && (return nothing))

    # skip if ind_parent has no children
    ind_cl = node_child(ind_parent, 1, heap.k)
    (ind_cl > sz) && (return nothing)
    
    ind_cr_max = min(
        sz, 
        node_child(ind_parent, heap.k, heap.k)
    )
    
    # get index in children of minimum element
    i_min = (ind_cl == ind_cr_max) ? ind_cl : 0   
    @inbounds begin
        kd = heap.data.pidx
        if i_min == 0 
            min_val = Inf
            for i in ind_cl:ind_cr_max
                (heap.data[i, kd] < min_val) && (min_val = heap.data[i, kd]; i_min = i)
            end
        end

        if heap.data[ind_parent, kd] > heap.data[i_min, kd]
            heap_swap_unsafe!(heap, ind_parent, i_min)
            percolate_down!(heap, i_min)
        end
    end
end



"""
Elevate an element through the k heap tree (min constitute root)
"""
@inline @propagate_inbounds function percolate_up!(
    heap::KaryHeap,
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

@inline @propagate_inbounds function percolate_up!(
    heap::KaryHeapShared,
    index::Int64,
)

    ind_parent = node_parent(index, heap.k, )
    @inbounds begin
        kd = heap.data.pidx
        ((index == 1) | (heap.data[index, kd] > heap.data[ind_parent, kd])) && (return nothing)
    end
    #
    heap_swap_unsafe!(heap, index, ind_parent)
    percolate_up!(heap, ind_parent)
end


# end module
#end