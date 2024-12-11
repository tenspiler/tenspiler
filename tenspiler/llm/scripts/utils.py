import json
import os
import re
import subprocess
import textwrap
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Union, get_args

import google.generativeai as genai

from metalift.frontend.llvm import Driver
from metalift.ir import (
    Axiom,
    Bool,
    Call,
    Eq,
    Expr,
    FnDecl,
    FnDeclRecursive,
    Int,
    List,
    Lit,
    Object,
    Var,
    is_fn_decl_type,
)
from metalift.rosette_translator import generate_vars
from metalift.smt_util import toSMT
from metalift.synthesis_common import get_used_fn_names
from tenspiler.llm.analysis import (
    analyze_blend_double_loop,
    analyze_dissolve_blend_8,
    analyze_matmul,
    analyze_normal_blend_f,
    analyze_rmsnorm_part1,
    analyze_rmsnorm_part2,
    analyze_softmax_part1,
    analyze_softmax_part2,
    analyze_softmax_part3,
    analyze_softmax_part4,
    analyze_transformer_part1,
    analyze_transformer_part2,
    analyze_transformer_part3,
    analyze_transformer_part4,
)

INDENTATION = " " * 4
hf_token = os.getenv("HUGGING_FACE_API")
if not hf_token:
    raise ValueError("Please set the environment variable HUGGING_FACE_API")


TEMPLATE_SYS = "You are a helpful expert in programming languages."
TEMPLATE_ERR = "These generated programs are incorrect. Do not generate the same. Please generate another program."
TEMPLATE_ENCLOSE_CODE = "Please enclose your solution in a python code block"

llama_repo = "meta-llama/Meta-Llama-3-8B-Instruct"
mistral_repo = "mistralai/Mistral-Nemo-Instruct-2407"

SYNTHESIS_LOGS_DIR = Path("./synthesisLogs")


def get_fuzzer_feedback(
    inputs: list[dict[str, Any]],
    expected_outputs: list[Any],
    actual_or_errors: list[Any],
) -> str:
    test_cases_info = []
    for i in range(min(len(inputs), 3)):
        curr_info = textwrap.dedent(
            f"""
            # Test case {i}
            Inputs: {inputs[i]}
            Expected Output: {expected_outputs[i]}
            Generated Output: {actual_or_errors[i]}
            """
        )
        test_cases_info.append(curr_info)

    test_case_str = "\n\n".join(test_cases_info)
    return textwrap.dedent(
        f"""
        The translated program does not match the source program on the following inputs.

        {test_case_str}

        Please fix the current program to pass the above cases. Explain your fix.
        """
    )


def get_ps_text(dsl_code: str, source_code: str) -> str:
    return textwrap.dedent(
        f"""
        Your task is to rewrite the given `test` C++ Function. You need to use only the set of provided functions and constants to achieve this. The rewritten program should be semantically equivalent to the `test` function.

        #Instructions
        # 1. Do not use for/while loops for rewriting the function.
        # 2. The rewritten program should just be a single return statement of the form return provided_function(...)
        # 3. Inline all the expressions. Do not use intermediate variables. Return the function signature as well as the function body in python.

        #defined functions
        ```python
        {dsl_code}
        ```

        ```cpp
        //test function
        {source_code}
        ```
        """
    )


# regex to extract the code from the completions
def extract(s) -> list[str]:
    extracted_result = [
        x.group(1)
        for x in re.finditer(
            r"```(?:Python|python|assembly|cpp|c|c\+\+)?(.*?)```", s, re.DOTALL
        )
    ]
    if len(extracted_result) == 0:
        return [s]
    return extracted_result


def extract_all_python_functions(s: str) -> list[str]:
    # TODO(sahil): use this instead of the extract function in all models.
    extracted_result = [
        x.group(1)
        for x in re.finditer(
            r"```(?:Python|python|assembly|cpp|c|c\+\+)?(.*?)```", s, re.DOTALL
        )
    ]
    return extracted_result


# TODO(jie): add type
def extract_and_save(choices, output_file: Path) -> str:
    final_content: list[str] = []
    for choice in choices:
        if isinstance(choice, str):
            # For testing purpose
            content = choice
        else:
            content = choice.message.content
        final_content.append("\n\n".join(extract(content)))

    with open(output_file, "w") as f:
        json.dump(final_content, f)
    return final_content


# TODO(jie): add type
def get_ps_choice_and_save_prompt(
    *,
    client,
    source_code: str,
    dsl_code: str,
    output_file: Path,
    prev_incorrect_sols: set[str],
):
    ps_template_text = get_ps_text(dsl_code, source_code)
    # call the completions endpoint to get the completions for the prompt
    messages = [
        {"role": "system", "content": TEMPLATE_SYS},
        {"role": "user", "content": ps_template_text},
    ]
    if len(prev_incorrect_sols) > 0:
        messages.append(
            {"role": "assistant", "content": "\n\n".join(prev_incorrect_sols)}
        )
        messages.append({"role": "user", "content": TEMPLATE_ERR_EXEC})

    with open(output_file, "w") as f:
        json.dump(messages, f)

    call_start_time = time.time()

    # # Claude
    # message = client.messages.create(
    #     model="claude-3-5-sonnet-20240620",
    #     max_tokens=1000,
    #     temperature=0.0,
    #     system=TEMPLATE_SYS,
    #     messages=messages,
    # )

    # GPT-4
    outputs = client.chat.completions.create(
        model="gpt-4o",  # model to use
        messages=messages,
        n=1,
        temperature=0.7,
    )

    # inference_client = InferenceClient(
    #     mistral_repo,
    #     token=hf_token,
    #     headers={"X-use-cache": "false"}
    # )
    # outputs = inference_client.chat_completion(
    # 	messages=messages,
    # 	max_tokens=500,
    # 	temperature=1,
    # )
    call_end_time = time.time()
    print(f"ps call took {call_end_time - call_start_time}s")
    for choice in outputs.choices:
        print(choice.message.content)
    return [
        choice.message.content for choice in outputs.choices
    ], call_end_time - call_start_time
    # return [message.content[0].text], call_end_time - call_start_time


######
# Some helper classes and functions for inv
######
@dataclass
class SingleLoopInfo:
    loop_var: Object
    read_vars: list[Object]
    modified_vars: list[Object]


@dataclass
class DoubleLoopInfo:
    outer_loop_var: Object
    inner_loop_var: Object
    outer_loop_read_vars: list[Object]
    inner_loop_read_vars: list[Object]
    outer_loop_modified_vars: list[Object]
    inner_loop_modified_vars: list[Object]


blend_double_loops = DoubleLoopInfo(
    outer_loop_var=Int("row"),
    inner_loop_var=Int("col"),
    outer_loop_read_vars=[
        List(List[Int], "base"),
        List(List[Int], "active"),
    ],
    inner_loop_read_vars=[
        List(List[Int], "base"),
        List(List[Int], "active"),
        Int("row"),
    ],
    outer_loop_modified_vars=[List(List[Int], "out")],
    inner_loop_modified_vars=[List(List[Int], "out"), List(Int, "row_vec")],
)

_output_var_map = {
    "normal_blend_f": List(Int, "out"),
    "normal_blend_8": List(Int, "out"),
    "darken_blend_8": List(List[Int], "out"),
    "multiply_blend_8": List(List[Int], "out"),
    "linear_burn_8": List(List[Int], "out"),
    "color_burn_8": List(List[Int], "out"),
    "lighten_blend_8": List(List[Int], "out"),
    "screen_blend_8": List(List[Int], "out"),
    "linear_dodge_8": List(List[Int], "out"),
    "color_dodge_8": List(List[Int], "out"),
    "overlay_blend_8": List(List[Int], "out"),
    "dissolve_blend_8": List(List[Int], "out"),
    "softmax_part1": Int("max_val"),
    "softmax_part2": List(Int, "output"),
    "softmax_part3": Int("sum"),
    "softmax_part4": List(Int, "output"),
    "rmsnorm_part1": Int("ss"),
    "rmsnorm_part2": List(Int, "output"),
    "matmul": List(Int, "output"),
    "transformer_part1": List(Int, "attention"),
    "transformer_part2": List(Int, "xb"),
    "transformer_part3": List(Int, "output"),
    "transformer_part4": List(Int, "output"),
    "fdtd_2d_part2": List(List[Int], "out"),
}

_loop_info_map = {
    "fdtd_2d_part2": DoubleLoopInfo(
        outer_loop_var=Int("i"),
        inner_loop_var=Int("j"),
        outer_loop_read_vars=[
            Int("nx"),
            Int("ny"),
            List(List[Int], "ex"),
            List(List[Int], "ey"),
        ],
        inner_loop_read_vars=[
            Int("nx"),
            Int("ny"),
            List(List[Int], "ex"),
            List(List[Int], "ey"),
            Int("i"),
        ],
        outer_loop_modified_vars=[List(List[Int], "out")],
        inner_loop_modified_vars=[List(List[Int], "out"), List(Int, "row_vec")],
    ),
    "normal_blend_f": SingleLoopInfo(
        loop_var=Int("i"),
        modified_vars=[List(Int, "out")],
        read_vars=[List(Int, "base"), List(Int, "active"), Int("opacity")],
    ),
    "normal_blend_8": SingleLoopInfo(
        loop_var=Int("i"),
        modified_vars=[List(Int, "out")],
        read_vars=[List(Int, "base"), List(Int, "active"), Int("opacity")],
    ),
    "darken_blend_8": blend_double_loops,
    "multiply_blend_8": blend_double_loops,
    "linear_burn_8": blend_double_loops,
    "color_burn_8": blend_double_loops,
    "lighten_blend_8": blend_double_loops,
    "screen_blend_8": blend_double_loops,
    "linear_dodge_8": blend_double_loops,
    "color_dodge_8": blend_double_loops,
    "overlay_blend_8": blend_double_loops,
    "dissolve_blend_8": DoubleLoopInfo(
        outer_loop_var=Int("row"),
        inner_loop_var=Int("col"),
        outer_loop_read_vars=[
            List(List[Int], "base"),
            List(List[Int], "active"),
            Int("opacity"),
            Int("rand_cons"),
        ],
        inner_loop_read_vars=[
            List(List[Int], "base"),
            List(List[Int], "active"),
            Int("opacity"),
            Int("rand_cons"),
            Int("row"),
        ],
        outer_loop_modified_vars=[List(List[Int], "out")],
        inner_loop_modified_vars=[List(List[Int], "out"), List(Int, "row_vec")],
    ),
    "softmax_part1": SingleLoopInfo(
        loop_var=Int("i"),
        modified_vars=[Int("max_val")],
        read_vars=[List(Int, "input"), Int("max_pos")],
    ),
    "softmax_part2": SingleLoopInfo(
        loop_var=Int("i"),
        modified_vars=[Int("output")],
        read_vars=[List(Int, "input"), Int("max_pos"), Int("max_val")],
    ),
    "softmax_part3": SingleLoopInfo(
        loop_var=Int("i"),
        modified_vars=[Int("sum")],
        read_vars=[List(Int, "output"), Int("max_pos")],
    ),
    "softmax_part4": SingleLoopInfo(
        loop_var=Int("i"),
        modified_vars=[List(Int, "output")],
        read_vars=[
            List(Int, "unnormalized_output"),
            Int("max_pos"),
            Int("sum"),
        ],
    ),
    "rmsnorm_part1": SingleLoopInfo(
        loop_var=Int("i"),
        read_vars=[List(Int, "input"), List(Int, "weight")],
        modified_vars=[Int("ss")],
    ),
    "rmsnorm_part2": SingleLoopInfo(
        loop_var=Int("i"),
        read_vars=[List(Int, "input"), List(Int, "weight"), Int("ss")],
        modified_vars=[List(Int, "output")],
    ),
    "matmul": DoubleLoopInfo(
        outer_loop_var=Int("row"),
        inner_loop_var=Int("col"),
        outer_loop_read_vars=[List(Int, "weight"), List(Int, "input")],
        inner_loop_read_vars=[
            List(Int, "weight"),
            List(Int, "input"),
            List(Int, "output"),
            Int("row"),
        ],
        outer_loop_modified_vars=[List(Int, "output")],
        inner_loop_modified_vars=[List(Int, "output"), Int("curr")],
    ),
    "transformer_part1": DoubleLoopInfo(
        outer_loop_var=Int("timestep"),
        inner_loop_var=Int("i"),
        outer_loop_read_vars=[
            Int("token_position"),
            Int("head"),
            Int("head_size"),
            List(Int, "q"),
            List(List[Int], "key_cache_layer"),
        ],
        inner_loop_read_vars=[
            Int("token_position"),
            Int("head"),
            Int("head_size"),
            List(Int, "q"),
            List(List[Int], "key_cache_layer"),
            Int("timestep"),
        ],
        outer_loop_modified_vars=[List(Int, "attention")],
        inner_loop_modified_vars=[List(Int, "attention"), Int("score")],
    ),
    "transformer_part2": DoubleLoopInfo(
        outer_loop_var=Int("i"),
        inner_loop_var=Int("timestep"),
        outer_loop_read_vars=[
            Int("token_position"),
            Int("head"),
            Int("head_size"),
            List(List[Int], "key_cache_layer"),
            List(Int, "attention"),
        ],
        inner_loop_read_vars=[
            Int("token_position"),
            Int("head"),
            Int("head_size"),
            List(List[Int], "key_cache_layer"),
            List(Int, "attention"),
        ],
        outer_loop_modified_vars=[List(Int, "xb")],
        inner_loop_modified_vars=[List(Int, "xb"), Int("curr")],
    ),
    "transformer_part3": SingleLoopInfo(
        loop_var=Int("i"),
        read_vars=[List(Int, "input"), Int("hidden_dim")],
        modified_vars=[List(Int, "output")],
    ),
    "transformer_part4": SingleLoopInfo(
        loop_var=Int("i"),
        read_vars=[
            List(Int, "input1"),
            List(Int, "input2"),
            Int("hidden_dim"),
        ],
        modified_vars=[List(Int, "output")],
    ),
}


def generate_invariant_template(loop_info: SingleLoopInfo | DoubleLoopInfo) -> str:
    if isinstance(loop_info, SingleLoopInfo):
        arguments = get_args_for_invariants(loop_info)
        args_with_types = ", ".join(
            [
                f"{arg}: {arg.type.to_python_type_str(get_args(arg.type))}"
                for arg in arguments
            ]
        )
        loop_var = loop_info.loop_var.src.name()
        modified_vars_cond = " and ".join(
            [
                f"{var} == operation over defined functions"
                for var in loop_info.modified_vars
            ]
        )
        return textwrap.dedent(
            f"""
            def invariant({args_with_types}) -> bool:
                return expression over loop index variable {loop_var} and {modified_vars_cond}
            """
        )
    else:
        outer_inv_args, inner_inv_args = get_args_for_invariants(loop_info)
        outer_inv_args_with_types = ", ".join(
            [
                f"{arg}: {arg.type.to_python_type_str(get_args(arg.type))}"
                for arg in outer_inv_args
            ]
        )
        inner_inv_args_with_types = ", ".join(
            [
                f"{arg}: {arg.type.to_python_type_str(get_args(arg.type))}"
                for arg in inner_inv_args
            ]
        )
        outer_loop_var = loop_info.outer_loop_var.src.name()
        inner_loop_var = loop_info.inner_loop_var.src.name()
        outer_modified_vars_cond = " and ".join(
            [
                f"{var} == operation over defined functions"
                for var in loop_info.outer_loop_modified_vars
            ]
        )
        inner_modified_vars_cond = " and ".join(
            [
                f"{var} == operation over defined functions"
                for var in loop_info.inner_loop_modified_vars
            ]
        )
        inv1_template = f"""
        def invariant1({outer_inv_args_with_types}) -> bool:
            return expression over loop index variable `{outer_loop_var}` and {outer_modified_vars_cond}
        """
        inv2_template = f"""
        def invariant2({inner_inv_args_with_types}) -> bool:
            return expression over loop index variable `{outer_loop_var}` and `{inner_loop_var}` and {inner_modified_vars_cond}
        """
        return [textwrap.dedent(inv1_template), textwrap.dedent(inv2_template)]


def _get_ps_expr(ps_solution: str) -> str:
    extracted_ps_solution = extract(ps_solution)
    if len(extracted_ps_solution) == 1:
        extracted_ps_solution = extracted_ps_solution[0]
    elif len(extracted_ps_solution) == 0:
        extracted_ps_solution = ps_solution
    else:
        raise ValueError("More than one code block extracted from the ps code")
    expr = extracted_ps_solution.split("return")[1].replace("\n", "").strip()
    expr = re.sub(r"\s+", " ", expr)
    return expr


def _get_inv_source_code(ps_code: str, source_code: str) -> str:
    # Extract the 1 line post condition from the ps_code
    ps_expr = _get_ps_expr(ps_code)
    # find the return statement in the source code and replace with assert post-cond
    lines = source_code.split("\n")
    for idx, line in enumerate(lines):
        if "return" in line:
            # split the line into return and the expression
            return_stmt = line.split("return")
            # strip ";"
            return_var = return_stmt[-1].strip()
            return_var = return_var[:-1] if return_var[-1] == ";" else return_var
            # replace the return statement with the assert statement
            lines[idx] = f"assert {return_var} == {ps_expr}"
            break
    return "\n".join(lines)


def replace_in_call(expr: Expr, in_call: tuple[str, str]) -> Expr:
    caller_fn_name, callee_fn_name = in_call
    if (
        isinstance(expr, Call)
        or isinstance(expr, FnDecl)
        or isinstance(expr, FnDeclRecursive)
    ):
        new_args = []
        for arg in expr.arguments():
            if isinstance(arg, FnDecl) or isinstance(arg, FnDeclRecursive):
                if arg.name() == callee_fn_name and expr.name() == caller_fn_name:
                    new_args.append(Var(callee_fn_name, arg.type))
                else:
                    new_args.append(replace_in_call(arg, in_call))
            else:
                new_args.append(replace_in_call(arg, in_call))
        if isinstance(expr, Call):
            return Call(expr.name(), expr.type, *new_args)
        elif isinstance(expr, FnDecl):
            return FnDecl(
                expr.name(),
                expr.returnT(),
                replace_in_call(expr.body(), in_call),
                *new_args,
            )
        else:
            return FnDeclRecursive(
                expr.name(),
                expr.returnT(),
                replace_in_call(expr.body(), in_call),
                *new_args,
            )
    elif isinstance(expr, Var) or isinstance(expr, Lit):
        return expr
    else:
        return expr.map_args(lambda x: replace_in_call(x, in_call))


def replace_in_calls(expr: Expr, in_calls: list[tuple[str, str]]) -> Expr:
    for in_call in in_calls:
        expr = replace_in_call(expr, in_call)
    return expr


def get_args_for_invariants(
    loop_info: SingleLoopInfo | DoubleLoopInfo,
) -> Union[list[Object], tuple[list[Object], list[Object]]]:
    if isinstance(loop_info, SingleLoopInfo):
        return sorted(
            list(
                set(
                    [var.src for var in loop_info.read_vars]
                    + [var.src for var in loop_info.modified_vars]
                    + [loop_info.loop_var.src]
                )
            ),
            key=lambda x: x.name(),
        )
    else:
        outer_inv_args = sorted(
            list(
                set(
                    [var.src for var in loop_info.outer_loop_read_vars]
                    + [var.src for var in loop_info.outer_loop_modified_vars]
                    + [loop_info.outer_loop_var.src]
                )
            ),
            key=lambda x: x.name(),
        )
        inner_inv_args = sorted(
            list(
                set(
                    [var.src for var in loop_info.inner_loop_read_vars]
                    + [var.src for var in loop_info.inner_loop_modified_vars]
                    + [loop_info.inner_loop_var.src]
                )
            ),
            key=lambda x: x.name(),
        )
        return outer_inv_args, inner_inv_args


def process_ps_fn_decl(
    fn_decl: Union[FnDecl, FnDeclRecursive],
    output_var: Object,
) -> Union[FnDecl, FnDeclRecursive]:
    return fn_decl.__class__(
        f"{fn_decl.name()}_ps",
        Bool,
        Eq(output_var.src, fn_decl.body()),
        *fn_decl.arguments(),
        output_var.src,
    )


def analyze_benchmark(driver: Driver, benchmark_name: str) -> str:
    print(f"Analyzing benchmark {benchmark_name}")
    inv_args = get_args_for_invariants(benchmark_name)
    if benchmark_name in {
        "darken_blend_8",
        "multiply_blend_8",
        "linear_burn_8",
        "color_burn_8",
        "lighten_blend_8",
        "screen_blend_8",
        "linear_dodge_8",
        "color_dodge_8",
        "overlay_blend_8",
    }:
        return analyze_blend_double_loop(driver, benchmark_name, inv_args)
    elif benchmark_name == "dissolve_blend_8":
        return analyze_dissolve_blend_8(driver, inv_args)
    elif benchmark_name == "normal_blend_f":
        return analyze_normal_blend_f(driver, inv_args)
    elif benchmark_name == "normal_blend_8":
        return analyze_normal_blend_8(driver, inv_args)
    elif benchmark_name == "softmax_part1":
        return analyze_softmax_part1(driver, inv_args)
    elif benchmark_name == "softmax_part2":
        return analyze_softmax_part2(driver, inv_args)
    elif benchmark_name == "softmax_part3":
        return analyze_softmax_part3(driver, inv_args)
    elif benchmark_name == "softmax_part4":
        return analyze_softmax_part4(driver, inv_args)
    elif benchmark_name == "rmsnorm_part1":
        return analyze_rmsnorm_part1(driver, inv_args)
    elif benchmark_name == "rmsnorm_part2":
        return analyze_rmsnorm_part2(driver, inv_args)
    elif benchmark_name == "matmul":
        return analyze_matmul(driver, inv_args)
    elif benchmark_name == "transformer_part1":
        return analyze_transformer_part1(driver, inv_args)
    elif benchmark_name == "transformer_part2":
        return analyze_transformer_part2(driver, inv_args)
    elif benchmark_name == "transformer_part3":
        return analyze_transformer_part3(driver, inv_args)
    elif benchmark_name == "transformer_part4":
        return analyze_transformer_part4(driver, inv_args)
    else:
        raise ValueError(f"Unknown benchmark: {benchmark_name}")


def get_inv_and_ps(
    *,
    client,
    benchmark_name: str,
    source_code: str,
    dsl_code: str,
    output_file: Path,
    prev_incorrect_sols: set[str],
):
    inv_ps_template_text = f"""Your task is to rewrite the given `test` C++ Function. You need to use only the set of provided functions and constants to achieve this. The rewritten program should be semantically equivalent to the `test` function. In addition, your task is to prove that rewritten function is equivalent to the `test` function. We can prove this by finding a loop invariant using the defined functions. Write the loop invariant as a python boolean formula.
    #Instructions Rewriting
    # 1. Do not use for/while loops for rewriting the function.
    # 2. The rewritten program should just be a single return statement of the form return_var = provided_function(...)
    # 3. Inline all the expressions. Do not use intermediate variables.
    #Instructions Invariants:
    # 1. You need to use only the defined functions to write the loop invariant.
    # 2. Do not use for/while loops for rewriting the function.
    # 3. The rewritten program should just be a single return statement of the form return_var = provided_function(...)
    # 4. Inline all the expressions. Do not use intermediate variables.
    # 5. Generate separate loop invariants for each loop in the test function.
    # 6. invariant structure
    ```
    {generate_invariant_template(benchmark_name)}
    ```

    Example1:
    ```
    #defined functions
    def vec_elemwise_sub(x: list[int], y: list[int]) -> list[int]:
        return (
            []
            if len(x) < 1 or not len(x) == len(y)
            else [x[0] - y[0], *vec_elemwise_sub(x[1:], y[1:])]
        )
    def matrix_elemwise_sub(matrix_x,: list[list[int]], matrix_y: list[list[int]]) -> list[list[int]]:
        return (
            []
            if len(matrix_x) < 1 or not len(matrix_x) == len(matrix_y)
            else [
                vec_elemwise_sub(matrix_x[0], matrix_y[0]),
                *matrix_elemwise_sub(matrix_x[1:], matrix_y[1:]),
            ]
        )
    //test function
    vector<vector<uint8_t>> test(vector<vector<uint8_t>> base, vector<vector<uint8_t>> active)
    {{
        vector<vector<uint8_t>> out;
        uint8_t m = base.size();
        uint8_t n = base[0].size();
        for (uint8_t row = 0; row < m; row++) {{
            vector<uint8_t> row_vec;
            for (uint8_t col = 0; col < n; col++) {{
                uint8_t pixel = base[row][col] - active[row][col] ;
                row_vec.push_back(pixel);

            }}
            out.push_back(row_vec);
        }}
        return out
    }}
    def test(vector<vector<uint8_t>> base, vector<vector<uint8_t>> active)
        return out = matrix_elemwise_sub(base, active)
    def invariant1(row, outer_loop_vars):
        return row >= 0 and row <= m and out == matrix_elemwise_sub(base[:row], active[:row])
    def invariant2(row, col, inner_loop_vars, outer_loop_vars):
        return row >= 0 and row < m and col >= 0 and col <= n and row_vec == vec_elemwise_sub(base[row][:col], active[row][:col]) and out == matrix_elemwise_sub(base[:row], active[:row])
    ```

    Example2:
    ```
    #defined functions
    {dsl_code}

    //test function
    {source_code}
    ```
    """
    messages = [
        {"role": "system", "content": TEMPLATE_SYS},
        {"role": "user", "content": inv_ps_template_text},
    ]
    if len(prev_incorrect_sols) > 0:
        messages.append(
            {"role": "assistant", "content": "\n\n".join(prev_incorrect_sols)}
        )
        messages.append({"role": "user", "content": TEMPLATE_ERR})

    with open(output_file, "w") as f:
        json.dump(messages, f)

    call_start_time = time.time()
    # outputs = client.chat.completions.create(
    #     model="gpt-4",  # model to use
    #     messages=messages,
    #     n=10,
    #     temperature=0.7,
    # )
    outputs = inference_client.chat_completion(
        messages=messages,
        max_tokens=500,
        temperature=0.7,
    )
    call_end_time = time.time()
    print(f"inv ps call took {call_end_time - call_start_time}s")
    return outputs.choices, call_end_time - call_start_time


def process_dsl_fns_for_smt(
    dsl_fns: list[FnDecl | FnDeclRecursive], in_calls: list[tuple[str, str]]
) -> list[FnDecl | FnDeclRecursive]:
    final_dsl_fns: list[FnDecl | FnDeclRecursive] = []
    for fn_decl in dsl_fns:
        # Skip functions that are already in list-axioms.smt.
        # TODO(jie): this is a bit hacky. We could remove all these functions in list-axioms.smt, but then we need to make sure that they are added to perspective driver files.
        if fn_decl.name().startswith("integer"):
            continue
        if fn_decl.name() in {
            "vec_slice",
            "matrix_col_slice",
            "firsts",
            "rests",
            "matrix_transpose",
            "matrix_row_slice",
        }:
            continue

        # If we have functions in the grammar that takes in lambda functions,
        # but not used anywhere, then we don't include them. This is due to the fact that we inline all these lambda functions, and we can't do so if there is no actual definitions for them.
        all_fns_with_inline_fns = set(in_call[0] for in_call in in_calls)
        if (
            any(is_fn_decl_type(arg.type) for arg in fn_decl.arguments())
            and fn_decl.name() not in all_fns_with_inline_fns
        ):
            continue

        final_dsl_fns.append(fn_decl)
    return final_dsl_fns


def process_dsl_fns_for_rosette(
    dsl_fns: list[FnDecl | FnDeclRecursive],
) -> list[FnDecl | FnDeclRecursive]:
    final_dsl_fns: list[FnDecl | FnDeclRecursive] = []
    # write dsl code
    for fn_decl in dsl_fns:
        # Skip some functions that are already in utils.rkt
        # TODO(jie): this is a bit hacky. We could remove all these functions in utils.rkt, but then we need to make sure that they are added to perspective driver files.
        if fn_decl.name().startswith("integer"):
            continue
        if fn_decl.name() in {"firsts"}:
            continue
        if fn_decl.body() is None:
            continue
        final_dsl_fns.append(fn_decl)

    return final_dsl_fns


def process_synthesized_fn_decls(
    *,
    output_var: Object,
    benchmark_name: str,
    synthesized_fn_decls: list[FnDecl | FnDeclRecursive],
) -> None:
    for idx, fn_decl in enumerate(synthesized_fn_decls):
        # Change function names
        # Change single loop invariant names
        if fn_decl.name() == "invariant":
            fn_decl.set_name(f"{benchmark_name}_inv0")

        # Change double loop invariant names
        if fn_decl.name() == "invariant1":
            fn_decl.set_name(f"{benchmark_name}_inv0")
        if fn_decl.name() == "invariant2":
            fn_decl.set_name(f"{benchmark_name}_inv1")

        # Change ps function name
        if fn_decl.name() == benchmark_name:
            fn_decl = process_ps_fn_decl(fn_decl, output_var)
            synthesized_fn_decls[idx] = fn_decl


def verify_benchmark_rosette(
    *,
    driver: Driver,
    benchmark_name: str,
    synthesized_fn_decls: list[Union[FnDecl, FnDeclRecursive]],
    in_calls: list[tuple[str, str]],
    dsl_fns: list[FnDecl | FnDeclRecursive],
    vc: Expr,
    list_bound: int = 2,
    bitwidth: int = 6,
) -> bool:
    print(f"Generating verification file for benchmark {benchmark_name}")

    SYNTHESIS_LOGS_DIR.mkdir(exist_ok=True)

    # Copy over the utils.rkt and bounded.rkt files
    Path(SYNTHESIS_LOGS_DIR / "utils.rkt").write_text(
        Path("metalift/utils/utils.rkt").read_text()
    )
    Path(SYNTHESIS_LOGS_DIR / "bounded.rkt").write_text(
        Path("metalift/utils/bounded.rkt").read_text()
    )
    verify_file_name = SYNTHESIS_LOGS_DIR / f"verify_{benchmark_name}.rkt"
    f = open(verify_file_name, "w")
    print(
        "#lang rosette\n"
        + '(require "./bounded.rkt")\n'
        + '(require "./utils.rkt")\n'
        + "(require rosette/lib/angelic rosette/lib/match rosette/lib/synthax)\n"
        + "(require rosette/solver/smt/bitwuzla)\n"
        + '(current-solver (bitwuzla #:path "/Users/jieq/Desktop/bitwuzla/build/src/main/bitwuzla" #:options (hash \':seed 0)))\n'
        + "\n",
        # + "(require rosette/solver/smt/z3)\n"
        # + "(current-solver (z3 #:options (hash ':random-seed 0)))\n"
        # + "\n",
        file=f,
    )
    # write dsl code
    for fn_decl in process_dsl_fns_for_rosette(dsl_fns):
        fn_decl = replace_in_calls(fn_decl, in_calls)
        print("\n", fn_decl.to_rosette(), "\n", file=f)

    for fn_decl in synthesized_fn_decls:
        print("\n", replace_in_calls(fn_decl, in_calls).to_rosette(), "\n", file=f)

    # Write variables
    vars = set(driver.var_tracker.all())
    var_decls, _ = generate_vars(vars, list_bound)
    print(var_decls, file=f)

    # Write bitwidth
    print(f"(current-bitwidth {bitwidth})", file=f)

    print(f"(define vc (verify (assert {vc.to_rosette()})))\n", file=f)
    print("vc", file=f)

    f.close()

    # Run the verification
    print(f"Running verification for benchmark {benchmark_name}")
    verification_output = subprocess.run(
        ["racket", verify_file_name], check=True, capture_output=True
    )
    if verification_output.stdout.decode("utf-8").split("\n")[0] == "(unsat)":
        print("Verification successful")
        print("\n\n")
        return True
    else:
        print("Verification failed")
        print(verification_output.stdout.decode("utf-8"))
        print("\n\n")
        return False


def verify_benchmark_smt(
    *,
    driver: Driver,
    benchmark_name: str,
    synthesized_fn_decls: list[Union[FnDecl, FnDeclRecursive]],
    in_calls: list[tuple[str, str]],
    dsl_fns: list[FnDecl | FnDeclRecursive],
    vc: Expr,
    dsl_fn_name_to_axioms: dict[str, list[Axiom]],
) -> None:
    SYNTHESIS_LOGS_DIR.mkdir(exist_ok=True)
    verify_file = SYNTHESIS_LOGS_DIR / f"verify_{benchmark_name}.smt"
    final_dsl_fns = process_dsl_fns_for_smt(dsl_fns, in_calls)

    # Find axioms that are needed
    used_fn_names = get_used_fn_names(synthesized_fn_decls)
    axioms: list[Axiom] = []
    for fn_name in used_fn_names:
        axioms.extend(dsl_fn_name_to_axioms.get(fn_name, []))

    synthesized_fn_names = [fn_decl.name() for fn_decl in synthesized_fn_decls]
    target_lang_fn_names = [fn_decl.name() for fn_decl in final_dsl_fns]

    toSMT(
        target_lang=list(set([*final_dsl_fns, *axioms])),
        vars=set(driver.var_tracker.all()),
        inv_and_ps=synthesized_fn_decls,
        preds=[],
        vc=vc,
        out_file=verify_file,
        in_calls=in_calls,
        fn_calls=[*target_lang_fn_names, *synthesized_fn_names],
    )

    # Run external verification subprocess.
    verify_proc = subprocess.run(
        [
            "cvc5",
            "--lang=smt",
            "--produce-models",
            "--tlimit=100000",
            verify_file,
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )

    if verify_proc.returncode < 0:
        return False
    else:
        proc_output = verify_proc.stdout
        result_verify = proc_output.decode("utf-8").split("\n")[0]
        print(result_verify)
        return True


def run_gemini(dsl_code: str, source_code: str, solution: str, feedback: str):
    genai.configure(api_key="AIzaSyB42v-TKSmMJ28z63ez7WK3VNYuxKObLCU")

    generation_config = {
        "temperature": 0.7,
        "top_p": 0.95,
        "top_k": 64,
        "max_output_tokens": 8192,
        "response_mime_type": "text/plain",
    }

    model = genai.GenerativeModel(
        model_name="gemini-1.5-pro-exp-0827",  # "gemini-1.5-pro-exp-0827",
        generation_config=generation_config,
        # safety_settings = Adjust safety settings
        # See https://ai.google.dev/gemini-api/docs/safety-settings
    )

    chat_session = model.start_chat(history=[])

    gemini_template_text = f"""
    Your task is to rewrite the given `test` C++ Function. You need to use only the set of provided functions and constants to achieve this. The rewritten program should be semantically equivalent to the `test` function.
    #Instructions
    # 1. Do not use for/while loops for rewriting the function.
    # 2. The rewritten program should just be a single return statement of the form return provided_function(...)
    # 3. Inline all the expressions. Do not use intermediate variables. Return the Python function signature as well as the function body.
    #defined functions
    {dsl_code}
    ```
    ```
    //test function
    {source_code}
    ```
    """
    chat_session = model.start_chat(
        history=[
            {"role": "user", "parts": gemini_template_text},
            {"role": "model", "parts": solution},
            {"role": "user", "parts": feedback},
            # {"role": "model", "parts": sol2},
        ]
    )

    response = chat_session.send_message(gemini_template_text)

    response = extract(response.text)
    return response, gemini_template_text


# Define the replacement function
def replace_ite(ps_sol: str) -> str:
    def repl_func(match):
        cond = match.group(1).strip()
        a = match.group(2).strip()
        b = match.group(3).strip()
        return f"{a} if {cond} else {b}"

    ite_pattern = r"ite\(([^,]+),\s*([^,]+),\s*([^)]+)\)"
    return re.sub(ite_pattern, repl_func, ps_sol)
