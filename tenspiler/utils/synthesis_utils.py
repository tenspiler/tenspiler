from enum import Enum
from pathlib import Path
from typing import Callable

from metalift.frontend.llvm import Driver, InvGrammar
from metalift.ir import Axiom, Expr, FnDecl, FnDeclRecursive, Int
from metalift.smt_util import augment_arguments, replace_fn_name
from metalift.synthesis_common import SynthesisFailed, VerificationFailed
from metalift.vc_util import and_objects
from tenspiler.codegen.numpy_codegen import numpy_codegen
from tenspiler.codegen.utils import DataType
from tenspiler.constants import TENSPILER_FN_NAME_TO_AXIOMS, TENSPILER_FNS
from tenspiler.llm.parser import check_solution
from tenspiler.llm.scripts.models import LLMModel
from tenspiler.llm.scripts.prompts import get_inv_prompt, get_ps_prompt
from tenspiler.llm.scripts.utils import (
    TEMPLATE_ERR,
    is_single_loop,
    replace_in_calls,
    verify_benchmark_rosette,
    verify_benchmark_smt,
)
from tenspiler.tenspiler_common import (
    DISSOLVE_MATRIX_SELECTION_TWO_ARGS,
    DISSOLVE_SELECT_TWO_ARGS_ARG,
    DISSOLVE_SELECTION_TWO_ARGS,
    MATRIX_SELECTION_TWO_ARGS,
    SELECT_TWO_ARGS_ARG,
    SELECTION_TWO_ARGS,
    dissolve_matrix_selection_two_args_fn_decl,
    dissolve_selection_two_args_fn_decl,
)
from test_case import correct_sols

tpcc_benchmarks = {
    "normal_blend_f",
    "normal_blend_8",
    "dissolve_blend_8",
    "darken_blend_8",
    "multiply_blend_8",
    "linear_burn_8",
    "color_burn_8",
    "lighten_blend_8",
    "screen_blend_8",
    "linear_dodge_8",
    "color_dodge_8",
    "overlay_blend_8",
    "mag_array",
    "matrix_add_matrix",
    "mse_array",
    "mult_add_into_cpu",
    "ol_l2_cpu1",
    "ol_l2_cpu2",
    "scale_array",
    "scale_matrix",
    "sum_array",
    "translate_array",
    "fir_small",
    "lmsfir1",
    "lmsfir2",
}


def run_synthesis_with_bound(
    *,
    driver: Driver,
    data_type: DataType,
    benchmark_name: str,
    list_bound: int,
    max_rounds: int,
    has_relaxed: bool,
    no_verify: bool,
):
    try:
        print(f"Trying strict grammar with list bound {list_bound}...")
        # First use strict grammar
        basename = f"{benchmark_name}_strict_listbound{list_bound}_rounds{max_rounds}"
        driver.synthesize(
            filename=basename,
            list_bound=list_bound,
            relaxed_grammar=False,
            rounds_to_guess=max_rounds,
            no_verify=no_verify,
        )
    except SynthesisFailed as e:
        print(f"Strict grammar with list bound {list_bound} failed")
        if not has_relaxed:
            print("No relaxed grammar specified")
            raise e

        # Use relaxed grammar
        print("Trying relaxed grammar...")
        basename = f"{benchmark_name}_relaxed_listbound{list_bound}_rounds{max_rounds}"
        driver.synthesize(
            filename=basename,
            list_bound=list_bound,
            relaxed_grammar=True,
            rounds_to_guess=max_rounds,
        )

    ps_fn_decl = driver.get_actual_ps_fn_decl()

    curr_file_path = Path(__file__).resolve()
    tenspiler_dir = curr_file_path.parent.parent
    generated_code_dir = tenspiler_dir / "codegen" / "generated_code" / benchmark_name
    generated_code_dir.mkdir(parents=True, exist_ok=True)

    # Write numpy code
    np_code = numpy_codegen(ps_fn_decl, driver.synthesized_fns, data_type)
    with open(generated_code_dir / f"{benchmark_name}_numpy.py", "w") as f:
        f.write(np_code)

    # # Write tensorflow code
    # tf_code = tensorflow_codegen(ps_fn_decl, driver.synthesized_fns, data_type)
    # with open(generated_code_dir / f"{benchmark_name}_tensorflow.py", "w") as f:
    #     f.write(tf_code)

    # # Write pytorch code
    # pt_code = pytorch_codegen(ps_fn_decl, driver.synthesized_fns, data_type)
    # with open(generated_code_dir / f"{benchmark_name}_pytorch.py", "w") as f:
    #     f.write(pt_code)

    # if benchmark_name in tpcc_benchmarks:
    #     gaudi_base_dir = generated_code_dir / "gaudi"
    #     gaudi_base_dir.mkdir(parents=True, exist_ok=True)
    #     gaudi_hpp_glue_code, gaudi_cpp_glue_code, gaudi_kernel_code = gaudi_codegen(
    #         ps_fn_decl, driver.synthesized_fns, data_type
    #     )

    #     with open(gaudi_base_dir / f"{benchmark_name}_gaudi.hpp", "w") as f:
    #         f.write(gaudi_hpp_glue_code)
    #     with open(gaudi_base_dir / f"{benchmark_name}_gaudi.cpp", "w") as f:
    #         f.write(gaudi_cpp_glue_code)
    #     with open(gaudi_base_dir / f"{benchmark_name}_gaudi.c", "w") as f:
    #         f.write(gaudi_kernel_code)


def run_synthesis_algorithm(
    *,
    driver: Driver,
    data_type: DataType,
    benchmark_name: str,
    max_rounds: int = 10,
    has_relaxed: bool = False,
    list_bound_start: int = 2,
    no_verify: bool = True,
):
    print(f"Starting synthesis at list bound {list_bound_start}")
    list_bound_start = int(list_bound_start)
    list_bound = list_bound_start
    while True:
        try:
            run_synthesis_with_bound(
                driver=driver,
                data_type=data_type,
                benchmark_name=benchmark_name,
                list_bound=list_bound,
                max_rounds=max_rounds,
                has_relaxed=has_relaxed,
                no_verify=no_verify,
            )
            return
        except VerificationFailed:
            list_bound += 1
        except Exception as e:
            raise e


class VerificationMethod(Enum):
    NONE = "none"
    ROSETTE = "rosette"
    SMT = "smt"


def run_llm_synthesis_algorithm(
    *,
    driver: Driver,
    source_code: str,
    suite_name: str,
    benchmark_name: str,
    llm_model: LLMModel,
    max_num_ps_sols: int = 10,
    max_num_inv_sols: int = 10,
    dsl_fns: list[FnDecl | FnDeclRecursive] = TENSPILER_FNS,
    dsl_fn_name_to_axioms: dict[str, list[Axiom]] = TENSPILER_FN_NAME_TO_AXIOMS,
    verification_method: VerificationMethod = VerificationMethod.ROSETTE,
) -> None:
    """
    The flow of the function is as follows:
    1. Start with asking the model to rewrite the function.
    2. Check if solution passes the parser. If it does, proceed. Otherwise, give parser feedback and ask the model to fix the function. Repeat this step for `max_parser_tries` times.
    4. Return the solution. Otherwise, return None.

    we return a list with maximum length of `max_num_tries` and each element containing the following information:
    - solutions: A list of solutions that we tried to pass to parser. Each solution is in the form of (solution, feedback, time_taken) tuple.
    """
    # First we need to get DSL code
    dsl_code = "\n\n".join(fn.to_python() for fn in dsl_fns)

    # First we need to generate prompts
    ps_prompt = get_ps_prompt(dsl_code=dsl_code, source_code=source_code)

    # Get result from LLM
    ps_sols: list[str] = []
    found_sol = False
    for ps_sol_index in range(max_num_ps_sols):
        # First we get a new solution. If there are previous incorrect solutions, we show them to the model.
        print(f"===== Starting iteration {ps_sol_index} =====")
        inv_template_message = {"role": "user", "content": ps_prompt}

        if len(ps_sols) > 0:
            messages_for_new_sol = [
                inv_template_message,
                {"role": "assistant", "content": "\n".join(ps_sols)},
                {"role": "user", "content": TEMPLATE_ERR},
            ]
        else:
            messages_for_new_sol = [inv_template_message]
        # TODO(jie)
        # ps_sol = get_solution_from_llm(llm_model, messages_for_new_sol)
        ps_sol = correct_sols[benchmark_name]["ps"]
        ps_sols.append(ps_sol)

        # Check if the solution passes the parser. If it does, we can continue to the next step. Otherwise, we would like to generate another PS.
        lambda_exprs: dict[Expr, str] = {}
        arg_name_to_count: dict[str, int] = {}
        try:
            _, ps_fn_decls, ps_inv_calls = check_solution(
                solution=ps_sol,
                expected_num_funcs=1,
                dsl_code=dsl_code,
                lambda_exprs=lambda_exprs,
                arg_name_to_count=arg_name_to_count,
            )
            print("Passed the parser, continuing to invariant generation")
        except Exception as e:
            print("Failed to pass the parser", e)
            print("Skipping invariant generation")
            continue

        # Generate the invariant
        inv_prompt = get_inv_prompt(
            suite_name=suite_name, benchmark_name=benchmark_name, dsl_code=dsl_code
        )
        inv_sols: list[str] = []
        for inv_sol_index in range(max_num_inv_sols):
            print(f"----- Generating {inv_sol_index} invariant -----")
            inv_template_message = {"role": "user", "content": inv_prompt}

            if len(inv_sols) > 0:
                messages_for_new_sol = [
                    inv_template_message,
                    {"role": "assistant", "content": "\n".join(inv_sols)},
                    {"role": "user", "content": TEMPLATE_ERR},
                ]
            else:
                messages_for_new_sol = [inv_template_message]
            # TODO(jie)
            # inv_sol = get_solution_from_llm(llm_model, messages_for_new_sol)
            inv_sol = correct_sols[benchmark_name]["inv"]
            print("Generated new INV solution", inv_sol)
            inv_sols.append(inv_sol)

            try:
                _, inv_fn_decls, inv_in_calls = check_solution(
                    solution=inv_sol,
                    expected_num_funcs=1 if is_single_loop(benchmark_name) else 2,
                    dsl_code=dsl_code,
                    lambda_exprs=lambda_exprs,
                    arg_name_to_count=arg_name_to_count,
                )
                print("Passed the parser, continuing to verification")
            except Exception as e:
                print("Failed to pass the parser", e)
                continue

            synthesized_fn_decls = list(set([*ps_fn_decls, *inv_fn_decls]))
            in_calls = [*ps_inv_calls, *inv_in_calls]

            # This is a hack for dissolve_blend_8
            if benchmark_name == "dissolve_blend_8":
                # Process synthesized functions.
                for idx, fn_decl in enumerate(synthesized_fn_decls):
                    if "select_two_args_arg" in fn_decl.name():
                        new_args = [
                            *fn_decl.arguments(),
                            Int("opacity").src,
                            Int("rand_cons").src,
                        ]
                        fn_decl.set_arguments(new_args)

                    fn_decl = replace_fn_name(
                        expr=fn_decl,
                        new_fn_name=DISSOLVE_MATRIX_SELECTION_TWO_ARGS,
                        fn_name=MATRIX_SELECTION_TWO_ARGS,
                    )
                    fn_decl = replace_fn_name(
                        expr=fn_decl,
                        new_fn_name=DISSOLVE_SELECTION_TWO_ARGS,
                        fn_name=SELECTION_TWO_ARGS,
                    )
                    fn_decl = augment_arguments(
                        expr=fn_decl,
                        fn_name=DISSOLVE_MATRIX_SELECTION_TWO_ARGS,
                        new_args=[Int("opacity").src, Int("rand_cons").src],
                        start_index=2,
                    )
                    fn_decl = augment_arguments(
                        expr=fn_decl,
                        fn_name=DISSOLVE_SELECTION_TWO_ARGS,
                        new_args=[Int("opacity").src, Int("rand_cons").src],
                        start_index=2,
                    )

                    synthesized_fn_decls[idx] = fn_decl

                # Process in_calls.
                for idx, in_call in enumerate(in_calls):
                    new_in_call: list[str] = []
                    for i in range(len(in_call)):
                        if in_call[i] == MATRIX_SELECTION_TWO_ARGS:
                            new_in_call.append(DISSOLVE_MATRIX_SELECTION_TWO_ARGS)
                        elif in_call[i] == SELECTION_TWO_ARGS:
                            new_in_call.append(DISSOLVE_SELECTION_TWO_ARGS)
                        elif in_call[i] == SELECT_TWO_ARGS_ARG:
                            new_in_call.append(DISSOLVE_SELECT_TWO_ARGS_ARG)
                        else:
                            new_in_call.append(in_call[i])
                    in_calls[idx] = tuple(new_in_call)

                # Process DSL functions.
                for idx, fn_decl in enumerate(dsl_fns):
                    if fn_decl.name() == MATRIX_SELECTION_TWO_ARGS:
                        dsl_fns[idx] = dissolve_matrix_selection_two_args_fn_decl
                    elif fn_decl.name() == SELECTION_TWO_ARGS:
                        dsl_fns[idx] = dissolve_selection_two_args_fn_decl

            # Generate VC.
            # Write assertions
            vc = and_objects(*driver.asserts).src.simplify()
            vc = replace_in_calls(vc, in_calls)

            # Verify the solution
            if verification_method == VerificationMethod.SMT:
                verified = verify_benchmark_smt(
                    driver=driver,
                    benchmark_name=benchmark_name,
                    synthesized_fn_decls=synthesized_fn_decls,
                    in_calls=in_calls,
                    dsl_fns=dsl_fns,
                    vc=vc,
                    dsl_fn_name_to_axioms=dsl_fn_name_to_axioms,
                )
            elif verification_method == VerificationMethod.ROSETTE:
                verified = verify_benchmark_rosette(
                    driver=driver,
                    benchmark_name=benchmark_name,
                    synthesized_fn_decls=synthesized_fn_decls,
                    in_calls=in_calls,
                    dsl_fns=dsl_fns,
                    vc=vc,
                )
            elif verification_method == VerificationMethod.NONE:
                print("Skpping verification...")
            else:
                raise Exception(
                    f"Unsupported verification method {verification_method}"
                )

            if verified:
                print("Solution verified")
                found_sol = True
                break

        # If we have a correct solution, we can break out of the loop.
        if found_sol:
            break

    if not found_sol:
        raise Exception("No correct solution found")

    print("Found PS solution")
    print(ps_sol)


def llm_analyze(
    driver: Driver,
    llvm_filepath: str,
    loops_filepath: str,
    fn_name: str,
    target_lang_fn: Callable[[], list[FnDeclRecursive | FnDecl]],
    inv_in_scope_vars: dict[str, list[str]] = {},
):
    return driver.analyze(
        llvm_filepath=llvm_filepath,
        loops_filepath=loops_filepath,
        fn_name=fn_name,
        target_lang_fn=target_lang_fn,
        ps_grammar=None,
        inv_grammars={
            inv_name: InvGrammar(None, in_scope_var_names=var_names)
            for inv_name, var_names in inv_in_scope_vars.items()
        },
    )
