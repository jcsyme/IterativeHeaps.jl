using Random



#=
vec = unique(Int64.(round.(Random.rand(2000).*5000)));
vec_dists = zeros(Int64, length(vec));
vec_parents = zeros(Int64, length(vec));
vec_heap_data = zeros(Int64, length(vec));
vec_heap_index = zeros(Int64, length(vec));
vec_heap_index_lookup = zeros(Int64, length(vec));


@time heap = KaryHeap{Int64}(
    length(vec),
    4;
    data = vec_heap_data,
    index = vec_heap_index,
    index_lookup = vec_heap_index_lookup,
);


function tst(
    heap::KaryHeap,
    vec::Vector,
)
    for (i, el) in enumerate(vec)
        heap_push!(heap, el, i)
    end
    
    while !isempty(heap)
        (j, elem) = heap_pop!(heap)
    end
end





# some parallel stuff

x = remotecall_fetch(
    () -> (
        #heap = Main.KaryHeaps.KaryHeap3{Int64}(
        #    2458,
        #    4;
        #    data = dict_sarrays[:heap_data][:, dict_sarrays[:heap_data].pidx],
        #);
        #heap_push!(
        #    heap,
        #    5,
        #    15;
        #);
        
        
        vec = Int64.(round.(Random.rand(1500).*1000000));
        
        @time begin
            heap = KaryHeapShared{Int64}(
                2458,
                4,
                dict_sarrays[:heap_data],
                dict_sarrays[:heap_index],
                dict_sarrays[:heap_index_lookup],
                dict_sarrays[:size],
            );
            
            for (i, el) in enumerate(vec)
                heap_push!(heap, el, i);
            end;

            while !isempty(heap)
                (j, elem) = heap_pop!(heap);
            end;
            
        end
        
        #size_shared[size_shared.pidx] -= 1
        #size(dict_sarrays[:heap_data])
        #v = dict_sarrays[:heap_data];#[:, dict_sarrays[:heap_data].pidx];
        #=
        KaryHeaps.initialize_vector(
            dict_sarrays[:heap_data][:, dict_sarrays[:heap_data].pidx],
            2458;
            fill_func = one,
        )
        =#
        #data = KaryHeaps.initialize_vector(v, 2458; fill_func = typemax )
        #isempty(heap)
    ),
    9
)
x
=#