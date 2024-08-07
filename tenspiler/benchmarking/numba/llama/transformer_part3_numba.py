
####### import statements ########
import numpy as np
import math
from numba import jit, cuda

@cuda.jit()
def transformer_part3_numba (input, hidden_dim, res):
    # output = []
    for i in range(hidden_dim):
        res[i] = 1 / (1+math.exp(-input[i])) * input[i]
        # output.append(curr)
    # return output

####### more import statements for benchmarking ########
import numpy as np
import time
import h5py

####### setup for benchmarking ########
rng = np.random.default_rng(1)

weights_path = './vicuna_weight.h5'

weights = []

with h5py.File(weights_path, 'r') as weight_file:
    for layer_name in weight_file:
        w = np.squeeze(np.array(weight_file[layer_name])).astype(np.float32)
        if "model" in layer_name and "embed_tokens" not in layer_name and "layernorm" not in layer_name:
            weights.append(w)

####### runner. need to manually update for each file ########  
inp = weights[-1].flatten()
hidden_dim = len(inp)
res = np.array([0 for _ in range(hidden_dim)], dtype = np.float32)

threadsperblock = 32
blockspergrid = (inp.size + (threadsperblock - 1)) // threadsperblock

transformer_part3_numba[blockspergrid, threadsperblock](inp, hidden_dim, res)

runs = 10
times = []
for _ in range(runs):
    total_time = 0
    for i in range(len(weights)):
        inp = weights[i].flatten()
        hidden_dim = len(inp)
        res = np.array([0 for _ in range(hidden_dim)], dtype = np.float32)

        threadsperblock = 32
        blockspergrid = (inp.size + (threadsperblock - 1)) // threadsperblock

        start_time = time.perf_counter()
        transformer_part3_numba[blockspergrid, threadsperblock](inp, hidden_dim, res)
        end_time = time.perf_counter()
        total_time += (end_time - start_time) * 1000

    times.append(total_time)

times = np.array(times)   

print("transformer_part3_numba")
print(f"{np.average(times)} {np.std(times)}") 
print(f"{np.average(times)} {np.std(times)}") 
