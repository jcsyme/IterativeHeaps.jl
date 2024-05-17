"""
Use heaps that supprt cache arrays for iteration, including paralleliation using
    SharedArrays.
"""
module IterativeHeaps

greet() = print("Iterative Heaps")

using Distributed
using SharedArrays


import Base:
    @propagate_inbounds
    get
    isempty
    iterate
    length
    size


export AbstractKHeap,
       FibonacciHeap,
       FibonacciNode,
       get_value,
       heap_data_type,
       heap_index_is_deactivated,
       heap_index_is_in,
       heap_modify!,
       heap_pop!,
       heap_push!,
       initialize_shared_array,
       initialize_vector,
       KaryHeap6,
       KaryHeap6Shared


##  LOAD CODE

include("InitializeVectors.jl")
include("FibonacciHeaps.jl")
include("KaryHeaps.jl")

end # module IterativeHeaps
