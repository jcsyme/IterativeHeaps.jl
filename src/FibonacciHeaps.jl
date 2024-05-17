"""
Relies primarily on:

(a) Wayne's CS Princeton material (https://www.cs.princeton.edu/~wayne/cs423/fibonacci/FibonacciHeapAlgorithm.html) and
(b) Daniel Borowski https://github.com/danielborowski/fibonacci-heap-python/blob/master/fib-heap.py 


"""
#=
export cascading_cut!
export concatenate_to_child_list!
export concatenate_to_root_list
export concatenate_to_root_list!
export consolidate!
export cut!
export FibonacciHeap
export FibonacciNode
export get_child
export get_degree
export get_key
export get_left
export get_mark
export get_min_key
export get_min_node
export get_min_value
export get_node_attr
export get_parent
export get_right
export get_root_list
export get_value
export heap_link
export heap_link!
export heap_pop!
export heap_push!
export pair
export remove_from_child_list!
export remove_from_root_list
export remove_from_root_list!
export set_child!
export set_degree!
export set_left!
export set_min_node!
export set_parent!
export set_right!



import Base:
    iterate
    length
    size
=#






##############################
###                        ###
###    BEGIN STRUCTURES    ###
###                        ###
##############################



##############################
#    START WITH HEAP NODE    #
##############################

"""
The FibonacciHeapNode stores information for a double-linked tree (left/right 
    and parent/child) to support a FibonacciHeap. Stores a key and a value. 

##  Constructs

```
FibonacciNode{U<:Integer, T<:Real}(key::U, value::T)
```


##  Initialization Arguments

- `key`: key of type `U` to initialize
- `value`: value of type `T`
"""
mutable struct FibonacciNode{U<:Integer, T<:Real}
    child::Union{FibonacciNode, Nothing}
    degree::Int64
    key::U
    left::Union{FibonacciNode, Nothing}
    mark::Bool
    parent::Union{FibonacciNode, Nothing}
    right::Union{FibonacciNode, Nothing}
    value::T
    
    
    function FibonacciNode(
        key::U,
        value::T,
        #data::Union{Vector{T}, Nothing} = nothing,
        #index::Union{Vector{Int64}, Nothing} = nothing,
        #index_lookup::Union{Vector{Int64}, Nothing} = nothing,
    ) where {U<:Integer, T<:Real}
        
        child = nothing
        degree = 0
        left = nothing
        mark = false
        parent = nothing
        right = nothing

        return new{U, T}(
            child,
            degree,
            key,
            left,
            mark,
            parent,
            right,
            value,
        )
    end
end



# a type shortcut
FibNodeOrNoth{U, T} = Union{FibonacciNode{U, T}, Nothing}



# some Base iterator implementations
function Base.iterate(
    iter::FibonacciNode,
    state::Tuple = (iter, iter, false, 1)
)
    element, element_0, flag, count = state
    
    isa(element, Nothing) && (return nothing)
    
    if element == element_0
        flag && (return nothing)
        flag = true
    end

    return (element, (element.right, element_0, flag, count + 1))
end

function Base.length(node::FibonacciNode)
    n = 0
    for i in node
        n += 1
    end
    return n
end






############################
#    MOVE TO BUILD HEAP    #
############################

"""
The FibonacciHeap is...
"""
mutable struct FibonacciHeap{U<:Integer, T<:Real}
    max_size::Int64 # Maximum number of items in the heap
    min_node::FibNodeOrNoth
    root_list::FibNodeOrNoth
    size::Int64 # size of the heap
    
    function FibonacciHeap{U, T}(
        max_size::Int64;
    ) where {U, T}

        (max_size < 1) && error("Error initializing FibonacciHeap: invalid max_size = $(max_size) (must be geq 1)")
      
        # initialize some mutable components
        min_node = nothing
        root_list = nothing
        size = 0
        
        return new{U, T}(
            max_size,
            min_node,
            root_list,
            size,
        )
    end
end



# update some characteristic functions
function Base.size(heap::FibonacciHeap)
    return heap.size
end





#############################
###                       ###
###    BEGIN FUNCTIONS    ###
###                       ###
#############################


##  NODE AND HEAP RETRIEVAL OPERATIONS (i.e., get())




"""
Get the `child` attribute of a `node`

```
get_child(node::FibNodeOrNoth)
```
"""
get_child(node::Nothing) = nothing
get_child(node::FibonacciNode) = node.child



"""
Get the `degree` attribute of a `node`

```
get_degree(node::FibonacciNode)
```
"""
get_degree(node::Nothing) = nothing
get_degree(node::FibNodeOrNoth) = node.degree



"""
Get the key of a `node`

```
get_key(node::FibonacciNode)
```
"""
get_key(node::Nothing) = nothing
get_key(node::FibonacciNode) = node.key



"""
Get the `left` attribute of a `node`

```
get_left(node::FibonacciNode)
```
"""
get_left(node::Nothing) = nothing
get_left(node::FibonacciNode) = node.left



"""
Get the `mark` attribute of a `node`

```
get_mark(node::FibonacciNode)
```
"""
get_mark(node::Nothing) = nothing
get_mark(node::FibonacciNode) = node.mark



"""
Get the minimum key from the heap

```
get_min_key(heap::FibonacciHeap)
```
"""
function get_min_key(
    heap::FibonacciHeap
)
    key = get_key(heap.min_node)

    return key
end



"""
Get the node storing the minimum value in the heap

```
get_min_node(heap::FibonacciHeap)
```
"""
get_min_node(heap::FibonacciHeap) = heap.min_node



"""
Get the minimum value from the heap

```
get_min_value(heap::FibonacciHeap)
```
"""
function get_min_value(
    heap::FibonacciHeap
)
    val = get_value(heap.min_node)

    return val
end



"""
Get the `parent` attribute of a `node`

```
get_parent(node::FibonacciNode)
```
"""
get_parent(node::Nothing) = nothing
get_parent(node::FibonacciNode) = node.parent



"""
Get the `right` attribute of a `node`

```
get_right(node::FibonacciNode)
```
"""
get_right(node::Nothing) = nothing
get_right(node::FibonacciNode) = node.right



"""
Get the value of a `node`

```
get_value(node::FibonacciNode)
```
"""
get_value(node::Nothing) = nothing
get_value(node::FibonacciNode) = node.value



##  NODE SET OPERATIONS (i.e., set!())

"""
Set the `value` of the child to a FibonacciHeapNode `node`

```
set_child!(
    node::FibNodeOrNoth,
    value::FibNodeOrNoth,
)
```
"""
function set_child!(
    node::Nothing,
    value::FibNodeOrNoth,
)
    return nothing
end
function set_child!(
    node::FibonacciNode,
    value::FibNodeOrNoth,
)
    node.child = value
end



"""
Set the `degree` of node for a FibonacciHeapNode `node`

```
set_degree!(
    node::FibNodeOrNoth,
    degree::Int64
)
```
"""
function set_degree!(
    node::Nothing,
    degree::FibNodeOrNoth,
)
    return nothing
end
function set_degree!(
    node::FibonacciNode,
    degree::Int64,
)
    node.degree = degree
end



"""
Set the `value` of the node left of a FibonacciHeapNode `node`

```
set_left!(
    node::FibNodeOrNoth,
    value::FibNodeOrNoth,
)
```
"""
function set_left!(
    node::Nothing,
    value::FibNodeOrNoth,
)
    return nothing
end
function set_left!(
    node::FibonacciNode,
    value::FibNodeOrNoth,
)
    node.left = value
end



"""
Set the `mark` of a FibonacciHeapNode `node`

```
set_mark!(
    node::FibNodeOrNoth,
    value::Bool
)
```
"""
function set_mark!(
    node::Nothing,
    value::Bool,
)
    return nothing
end
function set_mark!(
    node::FibonacciNode,
    value::Bool,
)
    node.mark = value
end



"""
Set the minimum node in a FibonacciHeap

```
set_min_node!(
    heap::FibonacciHeap,
    node::FibNodeOrNoth,
)
```
"""
function set_min_node!(
    heap::FibonacciHeap,
    node::FibNodeOrNoth,
)
    heap.min_node = node
end



"""
Set the `value` of the parent node of a FibonacciHeapNode `node`

```
set_parent!(
    node::FibNodeOrNoth,
    value::FibNodeOrNoth,
)
```
"""
function set_parent!(
    node::Nothing,
    value::FibNodeOrNoth,
)
    return nothing
end
function set_parent!(
    node::FibonacciNode,
    value::FibNodeOrNoth,
)
    node.parent = value
end



"""
Set the `value` of the node right of a FibonacciHeapNode `node`

```
set_right!(
    node::FibNodeOrNoth,
    value::FibNodeOrNoth,
)
```
"""
function set_right!(
    node::Nothing,
    value::FibNodeOrNoth,
)
    return nothing
end
function set_right!(
    node::FibonacciNode,
    value::FibNodeOrNoth,
)
    node.right = value
end



"""
Set the `root_list` in a FibonacciHeap

```
set_root_list!(
    heap::FibonacciHeap,
    root_list::FibNodeOrNoth,
)
```
"""
function set_root_list!(
    heap::FibonacciHeap,
    root_list::FibNodeOrNoth,
)
    heap.root_list = root_list
end




############################
###                      ###
###    CORE FUNCTIONS    ###
###                      ###
############################



"""
Cascading cut of parent node

##  Constructs

```
cascading_cut!(
    heap::FibonacciHeap,
    node::FibNodeOrNoth,
)
```

##  Function Arguments

- `heap`: Fibonacci Heap to insert element into
- `node`: parent node to cut down
"""
@inline function cascading_cut!(
    heap::FibonacciHeap,
    node::FibNodeOrNoth,
)
    parent = node.parent
    isa(parent, Nothing) && (return nothing)

    if !node.mark
        set_mark!(node, true)
    else
        cut!(heap, parent, node)
        cascading_cut!(heap, parent)
    end
end



"""
Cut a node from its parent

##  Constructs

```
cut!(
    heap::FibonacciHeap,
    parent::FibNodeOrNoth,
    child::FibNodeOrNoth,
)
```

##  Function Arguments

- `heap`: Fibonacci Heap to insert element into
- `parent`: parent node to cut child from 
- `child`: child node to cut
"""
@inline function cut!(
    heap::FibonacciHeap,
    parent::FibNodeOrNoth,
    child::FibNodeOrNoth,
)

    remove_from_child_list!(parent, child)
    set_degree!(parent, parent.degree - 1)

    concatenate_to_root_list!(heap, child)
    set_parent!(child, nothing)
    set_mark!(child, false)
end



"""
Consolidate a Fibonacci Heap

##  Constructs

```
consolidate!(heap::FibonacciHeap)
```

##  Function Arguments

- `heap`: Fibonacci Heap to insert element into

"""
@inline function consolidate!(
    heap::FibonacciHeap,
)
    # use a dictionary since it stores pointers
    dict_tree = Dict{Int64, FibNodeOrNoth}(
        (x, nothing) for x in 1:round(Int64, log(size(heap))*2)
    )

    # update root list
    isa(heap.root_list, Nothing) && (return nothing)
    
    # can't operate directly on iteration b/c it modifies the list in place
    nodes = [x for x in heap.root_list]
    for (ind, node) in enumerate(nodes)

        d = node.degree
        node_deg_cur = get(dict_tree, d, nothing)

        while !isa(node_deg_cur, Nothing)
            # swap
            if node.value > node_deg_cur.value
                node, node_deg_cur = node_deg_cur, node
            end
            
            heap_link!(node_deg_cur, node, heap)
            dict_tree[d] = nothing

            d += 1
            node_deg_cur = get(dict_tree, d, nothing)

        end

        dict_tree[d] = node
    end

    
    # find a new minimum node; root list is already updated
    #value = get_min_value(heap)
    #value = isa(value, Nothing) ? Inf : value

    # clear the minimum node 
    set_min_node!(heap, nothing)
    value = Inf

    for (d, node) in dict_tree
        isa(node, Nothing) && continue
        
        if node.value < value
            value = node.value
            set_min_node!(heap, node)
        end
    end 

end



"""
Concatenate to node to a child list

##  Constructs

```
concatenate_to_child_list(
    parent::FibNodeOrNoth,
    node::FibNodeOrNoth,
)::FibNodeOrNoth
```

Returns a FibonacciHeapNode node or nothing.


##  Function Arguments

- `parent`: parent FibonacciHeapNode to modify
- `node`: node to concenate to list as child
"""
function concatenate_to_child_list!(
    parent::Nothing,
    node::FibNodeOrNoth,
)
    return nothing#set_child!(parent, node)
end

function concatenate_to_child_list!(
    parent::FibonacciNode,
    node::Nothing,
)
    return nothing#set_child!(parent, node)
end

function concatenate_to_child_list!(
    parent::FibonacciNode,
    node::FibonacciNode,
)
    if isa(parent.child, Nothing)
        set_child!(parent, node)
        return nothing
    end

    set_right!(node, parent.child.right)
    set_left!(node, parent.child)
    set_left!(parent.child.right, node)
    set_right!(parent.child, node)
    
end



"""
Concatenate root lists.

##  Constructs

```
concatenate_to_root_list(
    root_list::FibNodeOrNoth,
    node::FibNodeOrNoth,
)::FibNodeOrNoth
```

```
concatenate_to_root_list!(
    heap::FibonacciHeap,
    node::FibNodeOrNoth,
)
```

Returns a FibonacciHeapNode node or nothing. If running inline, updates the
    heap's root list.


##  Function Arguments

- `heap`: FibonacciHeap to update
- `root`: root_list FibonacciHeapNode to modify
- `node`: node to concenate to list
"""
function concatenate_to_root_list(
    root_list::Nothing,
    node::FibNodeOrNoth,
)
    return node
end

@inline function concatenate_to_root_list(
    root_list::FibonacciNode,
    node::FibNodeOrNoth,
)
    
    set_right!(node, root_list.right)
    set_left!(node, root_list)
    set_left!(root_list.right, node)
    set_right!(root_list, node)
    
    return root_list
end

@inline function concatenate_to_root_list!(
    heap::FibonacciHeap,
    node::FibNodeOrNoth,
)
    # update root list
    heap.root_list = concatenate_to_root_list(
        heap.root_list, 
        node
    )
end






"""
Link heaps--link root and update child list. Returns root_list

##  Constructs

```
heap_link(
    node_a::FibNodeOrNoth,
    node_b::FibNodeOrNoth,
)
```

```
heap_link!(
    node_a::FibNodeOrNoth,
    node_b::FibNodeOrNoth,
    heap::FibonacciHeap,
)
```

##  Function Arguments

- `node_a`: node to link (first)
- `node_b`: node to link (second)
- `root_list`: root list to modify
- `heap`: FibonacciHeap with root list to modify
"""
@inline function heap_link(
    node_a::FibNodeOrNoth,
    node_b::FibNodeOrNoth,
    root_list::FibNodeOrNoth,
)
    root_list = remove_from_root_list(node_a, root_list)
    set_left!(node_a, node_a)
    set_right!(node_a, node_a) 

    concatenate_to_child_list!(node_b, node_a)
    node_b.degree += 1
    set_parent!(node_a, node_b)
    set_mark!(node_a, false)

    return root_list
end


@inline function heap_link!(
    node_a::FibNodeOrNoth,
    node_b::FibNodeOrNoth,
    heap::FibonacciHeap,
)
    heap.root_list = heap_link(node_a, node_b, heap.root_list)
end



"""
Retrieve the minimum element from the heap and consolidate

##  Constructs

```
heap_pop!(heap::FibonacciHeap)
```

##  Function Arguments

- `heap`: Fibonacci Heap to insert element into
"""
@inline function heap_pop!(
    heap::FibonacciHeap,
)   
    min_node = heap.min_node
    isa(min_node, Nothing) && (return nothing)

    # check if the minimum node has children; if so, push to the root list
    min_child = min_node.child
    if !isa(min_child, Nothing)
        for child in min_child
            concatenate_to_root_list!(heap, child)
            set_parent!(child, nothing)
        end
    end

    # drop from the root list 
    remove_from_root_list!(heap, min_node)


    ##  get new minimum node
    if min_node == min_node.right
        heap.min_node = nothing
        heap.root_list = nothing
        #set_min_node!(heap, nothing)
        #set_root_list!(heap, nothing)
    else
        heap.min_node = min_node.right
        #set_min_node!(heap, get_right(min_node))
        @time consolidate!(heap)
    end

    heap.size -= 1
    out = pair(min_node)

    return out
end



"""
Insert a new node into the root list

##  Constructs

```
heap_push!(
    heap::FibonacciHeap{U, T},
    key::U,
    value::T,
)
```

##  Function Arguments

- `heap`: Fibonacci Heap to insert element into
- `key`: key to store
- `value`: value associated with the key
"""
@inline function heap_push!(
    heap::FibonacciHeap{U, T},
    key::U,
    value::T,
) where {U, T}
    # initialize node
    node = FibonacciNode(key, value)
    set_left!(node, node)
    set_right!(node, node)

    # update root list
    concatenate_to_root_list!(heap, node)
   
    # check minimum node
    update_min = isa(heap.min_node, Nothing)
    update_min |= !update_min ? (value < heap.min_node.value) : false
    update_min && set_min_node!(heap, node)

    heap.size += 1

    return node
end



"""
Retrieve the key, value pair from a heap node

```
pair(node::FibNodeOrNoth)
```
"""
function pair(
    node::FibNodeOrNoth
)
    isa(pair, Nothing) && (return nothing)

    key = node.key
    value = node.value

    return (key, value)
end



"""
Remove a node from a child list

##  Constructs

```
remove_from_child_list(
    node::FibNodeOrNoth,
)::FibNodeOrNoth
```

Removes a node from a child list


##  Function Arguments

- `parent`: parent node to remove node from
- `node`: node to from child list
"""
function remove_from_child_list!(
    parent::FibNodeOrNoth,
    node::Nothing,
)
    return nothing
end

function remove_from_child_list!(
    parent::Nothing,
    node::FibonacciNode,
)
    return nothing
end

@inline function remove_from_child_list!(
    parent::FibonacciNode,
    node::FibonacciNode,
)

    child = parent.child
    if child == child.right
        set_child!(parent, nothing)
    elseif child == node
        set_child!(parent, node.right)
        set_parent!(node.right, parent)
    end

    set_right!(node.left, node.right)
    set_left!(node.right, node.left)
end



"""
Remove a node from the root list

##  Constructs

```
remove_from_root_list!(
    node::FibNodeOrNoth,
    root_list::FibNodeOrNoth
)::FibNodeOrNoth
```

Removes a node from the root list


##  Function Arguments

- `node`: node to from child list
- `root_list`: root list node to drop from
"""
function remove_from_root_list(
    node::Nothing,
    root_list::FibNodeOrNoth,
)
    return root_list
end

function remove_from_root_list(
    node::FibonacciNode,
    root_list::Nothing,
)
    return nothing
end

@inline function remove_from_root_list(
    node::FibonacciNode,
    root_list::FibonacciNode,
)
    (node == root_list) && (root_list = node.right)
    
    set_right!(node.left, node.right)
    set_left!(node.right, node.left)
   
    return root_list
end

# heap methods
function remove_from_root_list!(
    heap::FibonacciHeap,
    node::Nothing,
)
    return nothing
end

@inline function remove_from_root_list!(
    heap::FibonacciHeap,
    node::FibonacciNode,
)
    heap.root_list = remove_from_root_list(node, heap.root_list)
end





# end module