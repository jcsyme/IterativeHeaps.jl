# IterativeHeaps.jl

Julia package for iterative heaps w/cache arrays, including parallel heaps using DistributedArrays(). These heaps allow for multiple heaps to occur at the same time across a number of nodes while accessing a shared storage structure (DArray), which is convenient for memory and speed management when iterating in parallel.

Heaps sort `(key, value)` pairs (with respect to the value) continuously as new values are pushed to the heap; they do this efficiently, allowing for certain algorithms to be implemented much more quickly than they would otherwisae. For example, a fast heap is critical to a quick implementation of Dijkstra's shortest path algorithm. 

Once pushed, users can efficienctly pop (sometimes referred to as dequeing) the next key/value pair associated with the next-lowest value. Heaps are particularly useful when values can be pushed an popped multiple times or when the values that are pushed are not known a priori (in which case sorting can be efficient).


## Introduction

`IterartiveHeaps.jl` provides three key heap types:

- **`KAryHeap`**: The `KAryHeap`is a generalization of the binary heap with ``k`` children (where z``k = 2`` is a binary heap); see [Wikipedia](https://en.wikipedia.org/wiki/D-ary_heap) for an explanation.
- **`FibonacciHeap`**: See [Princeton Computer Science (Wayne)](https://www.cs.princeton.edu/~wayne/cs423/fibonacci/FibonacciHeapAlgorithm.html) for a psuedocode implementation of the §.
- **`SimpleQueue`**: A simple queue does not implement sorting, instead allowing for integers to popped in the order they were pushed.


## Use

Heaps are generally defined with a maximum size in `IterativeHeaps.jl`. In general, heaps can be modified using the 

`heap_push!(heap, k, v)`

and

`heap_pop!(heap)`

operations. After pushing to heaps, heaps will dequeue in ascending order based on key values, returning the key and its associated value.



###  KaryHeap

The `KaryHeap` can be used to instantiate a heap where each parent has `k` children and a maximum heap size of `max_size`. Furthermore, heap arrays can be stored in an iterative context by passing the `data`, `index`, and/or `index_lookup` arguments. If included (recommended for iteration), these should be a vector of length `max_size`. If being used on computational nodes, they can be the column of a `DistrubatedArrays.DArray`. 

The type `T` is the type of data stored in heap values, i.e., in vector `data`; therefore, if passing a vector as an argument for `data`, it should have element types `T`.

```
KaryHeap{T}(
    max_size::Int64,
    k::Int64;
    data::VMOrNoth{T} = nothing,
    index::VMOrNoth{Int64} = nothing,
    index_lookup::VMOrNoth{Int64} = nothing,
)
```


###  BinaryHeap

The `BinaryHeap` is a shortcut for the `KaryHeap` where `k = 2`. Otherwise, instantiation arguments are the same.

```
KaryHeap{T}(
    max_size::Int64,
    k::Int64;
    data::VMOrNoth{T} = nothing,
    index::VMOrNoth{Int64} = nothing,
    index_lookup::VMOrNoth{Int64} = nothing,
)
```


###  FibonacciHeap

The [FibonacciHeap](https://en.wikipedia.org/wiki/Fibonacci_heap) is a special heap that resorts on each `pop!` operation. 

```
FibonacciHeap{U, T}(
    max_size::Int64;
)
```


## Data

The heaps do not require any data; instead, they are useful for many coding applications, where users can push a key/value pair to the heap (inline) and pop them in ascending order according to the value. 


## Project information

ADD HERE


## References/Bibliography

Kevin Wayne. 2024. Algorithm for Fibonacci Heap Operations
(from CLR text). https://www.cs.princeton.edu/~wayne/cs423/fibonacci/FibonacciHeapAlgorithm.html 

Daniel Borowski. fib-heap.py. https://github.com/danielborowski/fibonacci-heap-python/blob/master/fib-heap.py 

 

## Copyright and License

Copyright (C) <2024> RAND Corporation. This code is made available under the MIT license.

 

## Authors and Reference

James Syme, 2024.

@misc{GDA2024,
  author       = {Syme, James},
  title        = {IterativeHeaps.jl: Memory-efficient heaps for iteration and parallelization.},
  year         = 2024,
  url = {URLHERE}
}
