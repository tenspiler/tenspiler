import argparse
from typing import List, Union

from metalift.frontend.llvm import Driver, InvGrammar
from metalift.ir import Bool, FnDecl, FnDeclRecursive, Int
from metalift.ir import List as mlList
from metalift.ir import Object, choose
from metalift.vc_util import and_objects
from tests.llvm.hardlift.hardlift_common import call_reduce_sum, reduce_sum


def softmax_part3_target_lang() -> List[Union[FnDecl, FnDeclRecursive]]:
    return [reduce_sum]


def softmax_part3_ps_grammar(
    writes: List[Object], reads: List[Object], in_scope: List[Object]
) -> Bool:
    ret_val = writes[0]
    output, max_pos = reads
    lower_bound = Int(0)
    upper_bound = max_pos
    if parser_args.relaxed:
        lower_bound = choose(lower_bound, lower_bound - 1, lower_bound + 1)
        upper_bound = choose(upper_bound, upper_bound - 1, upper_bound + 1)
    vec = choose(output[lower_bound:upper_bound])
    return ret_val == call_reduce_sum(vec)


def softmax_part3_inv0_grammar(
    writes: List[Object], reads: List[Object], in_scope: List[Object]
) -> Bool:
    output, max_pos = reads
    i, sum = writes
    lower_bound = Int(0)
    upper_bound = max_pos
    slice_upper_bound = i
    if parser_args.relaxed:
        lower_bound = choose(lower_bound, lower_bound - 1, lower_bound + 1)
        upper_bound = choose(upper_bound, upper_bound - 1, upper_bound + 1)
        slice_upper_bound = choose(
            slice_upper_bound, slice_upper_bound - 1, slice_upper_bound + 1
        )
    vec = choose(output[lower_bound:slice_upper_bound])

    return and_objects(i >= lower_bound, i <= upper_bound, sum == call_reduce_sum(vec))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--depth", type=int)
    parser.add_argument("--relaxed", action="store_true")
    parser_args = parser.parse_args()

    # Synthesize part 3
    driver = Driver()
    softmax_part3 = driver.analyze(
        llvm_filepath="tests/llvm/hardlift/llama/cpp/softmax/softmax_part3.ll",
        loops_filepath="tests/llvm/hardlift/llama/cpp/softmax/softmax_part3.loops",
        fn_name="softmax_part3",
        target_lang_fn=softmax_part3_target_lang,
        inv_grammars={
            "softmax_part3_inv0": InvGrammar(softmax_part3_inv0_grammar, []),
        },
        ps_grammar=softmax_part3_ps_grammar,
    )

    output_var = mlList(Int, "output")
    max_pos_var = Int("max_pos")
    driver.add_var_objects([output_var, max_pos_var])
    driver.add_precondition(output_var.len() > 0)
    driver.add_precondition(max_pos_var <= output_var.len())
    driver.add_precondition(max_pos_var >= 1)

    softmax_part3(output_var, max_pos_var)

    relaxed_suffix = "_relaxed" if parser_args.relaxed else ""
    depth_suffix = f"_depth{parser_args.depth}"
    driver.synthesize(filename=f"softmax_part3{depth_suffix}{relaxed_suffix}")
