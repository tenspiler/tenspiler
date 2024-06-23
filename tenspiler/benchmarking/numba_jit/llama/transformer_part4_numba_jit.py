
####### import statements ########
import numpy as np
from numba import jit, cuda

@jit(nopython=True)
def transformer_part4_numba_jit (input1, input2, hidden_dim):
    # output = []
    output = np.empty(hidden_dim)
    for i in range(hidden_dim):
        output[i] = input1[i] * input2[i]
        # output.append(input1[i] * input2[i])
    return output

####### more import statements for benchmarking ########
import numpy as np
import time
import h5py

####### setup for benchmarking ########
rng = np.random.default_rng(1)

weights_path = './vicuna_weight.h5'

weights = []
w_input = []

with h5py.File(weights_path, 'r') as weight_file:
    for layer_name in weight_file:
        w = np.squeeze(np.array(weight_file[layer_name])).astype(np.float32)
        if "model" in layer_name and "embed_tokens" not in layer_name and "layernorm" not in layer_name:
            weights.append(w)
            w_input.append(rng.random(w.shape, dtype = np.float32))

####### runner. need to manually update for each file ########  
inp1 = weights[-1].flatten()
inp2 = w_input[-1].flatten()
hidden_dim = len(inp1)



transformer_part4_numba_jit(inp1, inp2, hidden_dim)

runs = 10
times = []
for _ in range(runs):
    total_time = 0
    for i in range(len(weights)):
        inp1 = weights[i].flatten()
        inp2 = w_input[i].flatten()
        hidden_dim = len(inp1)

        

        start_time = time.perf_counter()
        transformer_part4_numba_jit(inp1, inp2, hidden_dim)
        end_time = time.perf_counter()
        total_time += (end_time - start_time) * 1000

    times.append(total_time)

times = np.array(times)   

print("transformer_part4_numba_jit")
print(f"{np.average(times)} {np.std(times)}") 
print(f"{np.average(times)} {np.std(times)}") 
