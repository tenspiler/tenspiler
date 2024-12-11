import time
from pathlib import Path

from llm.synthesis import (
    DoubleLoopInfo,
    LLMModel,
    get_inv_args,
    replace_args,
    run_llm_synthesis_algorithm,
)
from metalift.frontend.llvm import Driver, InvGrammar
from metalift.ir import Int, List, Matrix

if __name__ == "__main__":
    start_time = time.time()
    driver = Driver()

    loop_info = DoubleLoopInfo(
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
    output_var = List(List[Int], "out")

    inv0_args, inv1_args = get_inv_args(loop_info)
    inv0_args = replace_args(args=inv0_args, replace_args={"out": "agg.result"})
    inv1_args = replace_args(args=inv1_args, replace_args={"out": "agg.result"})
    inv0_grammar = InvGrammar(None, [], inv0_args)
    inv1_grammar = InvGrammar(None, [], inv1_args)
    color_dodge_8 = driver.analyze(
        llvm_filepath="tenspiler/blend/cpp/for_synthesis/color_dodge_8.ll",
        loops_filepath="tenspiler/blend/cpp/for_synthesis/color_dodge_8.loops",
        fn_name="color_dodge_8",
        target_lang_fn=[],
        inv_grammars={
            "color_dodge_8_inv0": inv0_grammar,
            "color_dodge_8_inv1": inv1_grammar,
        },
        ps_grammar=None,
    )

    base = Matrix(Int, "base")
    active = Matrix(Int, "active")
    driver.add_var_objects([base, active])

    # Add preconditions
    driver.add_precondition(base.len() > 1)
    driver.add_precondition(base.len() == active.len())
    driver.add_precondition(base[0].len() == active[0].len())

    color_dodge_8(base, active)

    input_code = Path(f"tenspiler/blend/cpp/for_synthesis/color_dodge_8.cc").read_text()

    run_llm_synthesis_algorithm(
        driver=driver,
        loop_info=loop_info,
        output_var=output_var,
        source_code=input_code,
        benchmark_name="color_dodge_8",
        llm_model=LLMModel.GPT,
    )
    end_time = time.time()
    print(f"Synthesis took {end_time - start_time} seconds")
