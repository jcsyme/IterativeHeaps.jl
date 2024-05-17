
"""
Initialize a vector or Matrix. NOTE: if passing a matrix, then the operation
    is unsafe; it cannot be resized.

    This
    
##  Constructs

```
initialize_shared_array(
    arr::Union{SharedArray{T}, SharedMatrix{T}},
    len::Int64;
    fill_func::Function = zero,
) where T<:Real
```

```
initialize_shared_array(
    arr::Nothing,
    len::Int64,
    U::DataType;
    fill_func::Function = zero,
)
```


##  Function Arguments

- `vec`: Vector object to initialize. If nothing, returns a new vector size
    `len` with element types `U`
- `len`: length of the vector
- `U`: (only required if arr is Nothing) element type for the Vector


##  Keyword Arguments

- `fill_func`: 
    * `one` to fill with ones
    * `typemax` to set using maximum value for type `T`
    * `zero` to fill with zeros

"""
function initialize_shared_array(
    arr::Union{SharedArray{T}, SharedMatrix{T}},
    len::Int64,
    U::DataType = T; 
    fill_func::Function = zero,
) where T<:Real
    
    sz = size(arr)
    
    # throw an error if there's a mismatch
    (len != sz[1]) && error("Invalid size of vec in initialize_vector(); nrow(vec) == $(sz[1]), not the specified size $(len)")

    # fill! doesn't work on SharedArray
    val = fill_func(eltype(arr), )
    
    if myid() > 1
        for k in 1:sz[1]
            arr[k, arr.pidx] = val
        end
    else
        # if initializing on coordinator, fill everything
        for k1 in 1:sz[1], k2 in 1:sz[2]
            arr[k1, k2] = val
        end
    end

    return arr
end



function initialize_shared_array(
    arr::Nothing,
    len::Int64,
    U::DataType;
    fill_func::Function = zero,
)
    
    nw = nworkers()

    # if not running distributed, or if calling on a worker, return a vector
    if (nw == 1) | (myid() > 1)

        out = initialize_vector(
            arr, 
            len, 
            U; 
            fill_func = fill_func,
        )

        return out
    end

    arr = SharedArray{U}(len, nw; pids = workers())

    # fill! doesn't work on SharedArray
    val = fill_func(eltype(arr), )
    for i in 1:len
        for j in 1:nw
            arr[i, j] = val
        end
    end

    return arr
end



"""
Initialize a vector or Matrix. NOTE: if passing a matrix, then the operation
    is unsafe; it cannot be resized.

    This
    
##  Constructs

```
initialize_vector(
    vec::Union{Vector{T}, Nothing},
    size::Int64,
    U::DataType = Float64;
    fill_func::Function = zero,
) where {T<:Real}
```

```
initialize_vector(
    vec::Nothing,
    len::Int64,
    U::DataType = Float64;
    coerce_vector::Bool = false,
    fill_func::Function = zero,
) where T<:Real
```


##  Function Arguments

- `vec`: Vector object to initialize. If nothing, returns a new vector size
    `len` with element types `U`
- `len`: length of the vector
- `U`: (only required if vec is Nothing) element type for the Vector


##  Keyword Arguments

- `coerce_vector`; set to true to force the input is coerced to a vector
- `fill_func`: 
    * `one` to fill with ones
    * `typemax` to set using maximum value for type `T`
    * `zero` to fill with zeros
"""
function initialize_vector(
    vec::Nothing,
    len::Int64,
    U::DataType = Float64;
    coerce_vector::Bool = false,
    fill_func::Function = zero,
)

    vec = zeros(U, len)
    (fill_func == zero) && (return vec)

    fill!(vec, fill_func(U))
    return vec
end


function initialize_vector(
    vec::Vector{T},
    len::Int64,
    U::DataType = T;
    coerce_vector::Bool = false,
    fill_func::Function = zero,
) where T<:Real

    (len != length(vec)) && resize!(vec, len)
    fill!(vec, fill_func(eltype(vec)))

    return vec
end



function initialize_vector(
    vec::Matrix{T},
    len::Int64,
    U::DataType = T;
    coerce_vector::Bool = false,
    fill_func::Function = zero,
) where T<:Real

    # convert matrix or subarray to vector?
    (!isa(vec, Vector) & coerce_vector) && (vec = vec[:, 1])
    sz = size(vec)

    # throw an error if there's a mismatch
    (len != size(vec)[1]) && error("Invalid size of vec in initialize_vector(); nrow(vec) == $(sz[1]), not the specified size $(sz)")
    
    (sz[2] != 1) && error("Invalid size of vec in initialize_vector(); ncol(vec) != 1. If a matrix is passed, it must have only one column.")
    
    fill!(vec, fill_func(eltype(vec)))

    return vec
end



function initialize_vector(
    vec::SubArray{T},
    len::Int64,
    U::DataType = T;
    coerce_vector::Bool = false,
    fill_func::Function = zero,
) where T<:Real

    sz = size(vec)

    # throw an error if there's a mismatch
    (len != sz[1]) && error("Invalid size of vec in initialize_vector(); nrow(vec) == $(sz[1]), not the specified size $(sz)")
    
    if length(sz) > 1
        (sz[2] != 1) && error("Invalid size of vec in initialize_vector(); ncol(vec) != 1. If a matrix is passed, it must have only one column.")
    end

    # THIS WILL BREAK, BUT THAT'S OK--NEED TO FIX BEHAVIOR
    fill!(vec, fill_func(eltype(vec)))

    return vec
end
