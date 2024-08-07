# Quick-start guide
1. Build the provided Docker container with
    ```
    docker build -t tenspiler .
    ```
2. Run the container and spawn a shell
    ```
    docker run --rm -v $(pwd):/code/tenspiler -it tenspiler /bin/bash
    ```
    **Note**: For any `python` command in the Docker environment, please prefix with `poetry run` (as included in all provided commands).

3. There are three phases in Tenspiler: synthesis, verification, and code generation. To make everything works, we can perform a quick test by generating **NumPy** code for the **mag_array** benchmark. The source code of this benchmark can be found at `tenspiler/c2taco/cpp/for_synthesis/darknet/mag_array.cc`, and the expected executable NumPy code is as follows:
    ```python
    import numpy as np

    def mag_array_np(a, n):
        return np.sum((a[:n]) * (a[:n]))


    def mag_array_np_glued(a, n):
        a = np.array(a).astype(np.int32)
        return mag_array_np(a, n)

    ```
    To run Tenspiler end to end for this benchmark, we can execute
    ```
    poetry run python tenspiler/generated_code/numpy/generate_numpy_benchmarks.py mag_array
    ```
    The generated NumPy code can be found at `tenspiler/generated_code/numpy/darknet/mag_array_np.py`.

4. We can evaluate the performance of the generated NumPy code on a subset of ImageNet dataset, located at `tenspiler/data/`. We compare against running C++ code compiled with `-O3` flag.
    ```
    poetry run python tenspiler/benchmarking/numpy_speedup_exec.py mag_array
    ```
    This will print the C++ and NumPy runtimes, and both the end-to-end and kernel speedups offered by NumPy. End-to-end includes the overhead of loading the dataset, while kernel speedup only includes the computation time.


# Overview: What does the artifact comprise?

In this artifact, we include the source code of Tenspiler, the files to obtain results we stated in the paper, and sampled datasets used for evaluation (and script to obtain the full dataset).
We provide a **Dockerfile** for easy setup of the environment.

Below, we describe each component of our artifact:
- Source Code:
    - `/code/tenspiler/`: The root folder of Tenspiler.
    - `/code/tenspiler/tenspiler/(blend|llama|c2taco)cpp/for_synthesis/`: The source code of our benchmarks.
    - `/code/tenspiler/tenspiler/codegen/`: The code generation scripts from TensIR to each of the 6 supported backends.
    - `/code/tenspiler/tenspiler/plots/`: Evaluation data, plots, and plotting scripts used in the paper.
- Evaluation scripts:
    - `/code/tenspiler/tenspiler/generated_code/`: The scripts that run all three phases of Tenspiler for each benchmark, as described above.
    - `/code/tenspiler/tenspiler/benchmarking/`: The scripts to obtain speedup of each benchmark on the backends.
    - `/code/tenspiler/(data/|vicuna_weight.h5|vicuna_weight7b.h5)`: Sampled datasets used for evaluation. See [the performance evaluation section](#performance-evaluation) for more details.

# Functional badge

## Generating Code per Backend
As stated in our paper section 6.1.2, Tenspiler can target 6 different backends for the benchmarks. Note that not all 69 benchmarks are included since some are private. To translate all benchmarks to executable code for each backend, run
```
poetry run python tenspiler/generated_code/<backend>/generate_<backend>_benchmarks.py ALL
```
which writes the translated code to `./tenspiler/generated_code/<backend>/(blend|llama|darknet|...)/<benchmark name>`.

To test a single benchmark, run
```
poetry run python tenspiler/generated_code/<backend>/generate_<backend>_benchmarks.py <benchmark-name>
```

## Backend Descriptions
### Backend names
Tenspiler supports 6 backends: NumPy, MLX, PyTorch, TensorFlow, Gemmini, and Gaudi.

### Benchmarks
#### blend
color_burn_8 (no gemmini support), color_dodge_8 (no gemmini support), darken_blend_8_8 (no gemmini support), dissolve_blend_8 (no gemmini support), lighten_blend_8 (no gemmini support), linear_burn_8, linear_dodge_8, multiply_blend_8 (no gemmini support), normal_blend_8, normal_blend_f, overlay_blend_8 (no gemmini support), screen_blend_8

#### llama
matmul (no gaudi TPC-C support), rmsnorm_part1 (no gaudi TPC-C support), rmsnorm_part2 (no gemmini support) (no gaudi TPC-C support), softmax_part1 (no gemmini support) (no gaudi TPC-C support), softmax_part2 (no gemmini support) (no gaudi TPC-C support), softmax_part3 (no gaudi TPC-C support), softmax_part4 (no gemmini support) (no gaudi TPC-C support), transformer_part1 (no gemmini support) (no gaudi TPC-C support), transformer_part2 (no gemmini support) (no gaudi TPC-C support), transformer_part3 (no gemmini support) (no gaudi TPC-C support), transformer_part4 (no gemmini support) (no gaudi TPC-C support)

#### darknet
mag_array, matrix_add_matrix, mse_array, mult_add_into_cpu, ol_l2_cpu1, ol_l2_cpu2, scale_array, scale_matrix, sum_array, translate_array (no gemmini support)

#### utdsp
fir_small, lmsfir1, lmsfir2

## Performance Evaluation
In figures 9 and 10 in the paper, we show the performance of translated code compared to C++ baseline. In this artifact, we include scripts to replicate the results.

In the paper, we evaluated the performance of the translated code using either 10k images from ImageNet or the model weights from vicuna-33B and 7B. It takes multiple days to run the evalutes on the full datasets. For the purpose of this artifact, we include a scaled down version of the datasets. To retrieve the full datasets, the ImageNet images can be found at `/code/tenspiler/data_full`, and vicuna weights 33B and 7B can be obtained by runing in `poetry run python tenspiler/benchmarking/retrieving_data/vicuna_weights_processing.py`. Running with full dataset, especially 33B vicuna, requires more memory; our experimentation setup has 512GB available.

If you decide to use the full datasets, rename the 10k images folder `data_full` to `data`, and the vicuna 33B and 7B weights as `vicuna_weight.h5` and `vicuna_weight7b.h5`, respectively. Everything should be placed in the `/code/tenspiler/` directory.


**Notes**:
- For this artifact, we have included evaluations only for **NumPy**, **TensorFlow**, and **PyTorch** backends (on CPUs). In the paper, we evaluated TensorFlow and PyTorch using GPU, which aren't supported by Docker for linux distributions.
- We don't include MLX, Gemmini, and Gaudi because of lack of Docker support.
- We have verified the generated MLX, Gaudi and Gemmini code by executing them on hardwares and verified with Gaudi and Gemmini experts.

# Reusable badge

Our implementation is open-source, and it's easy to add another backend as described in section 6.1.2 in our paper. To add support for a new backend, add a code-generation script to the `tenspiler/codegen/` directory.

At a high level, the codegen script parses the TensIR expressions and syntactically maps them to the target backend's APIs. For example, for MLX code generation, we can write the following pattern-matching rules.

```python
def mlx_codegen(expr: Expr) -> str:
    if isinstance(expr, Var):
        return expr.name()
    elif isinstance(expr, Call):
        if expr.name() == VEC_ELEMWISE_ADD:
            return f"{mlx_codegen(expr.arguments()[0])} + {mlx_codegen(expr.arguments()[0])}"
        elif expr.name() == MATRIX_VEC_MUL:
            return f"mx.matmul({mlx_codegen(expr.arguments()[0])}, {mlx_codegen(expr.arguments()[0])})"
        ...
```

This will translate the source function to the APIs of the target backend. However, to generate executable code, additional code such as import statements might be needed, which can be included as a part of the codegen script. See `tenspiler/codegen/numpy_codegen.py` for an example.
