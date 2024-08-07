import argparse
import time

from metalift.frontend.llvm import Driver
from metalift.ir import Int, Matrix
from tenspiler.tenspiler_common import get_dissolve_general_search_space

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--depth", type=int)
    parser.add_argument("--relaxed", action="store_true", default=False)
    parser_args = parser.parse_args()

    driver = Driver()
    base = Matrix(Int, "base")
    active = Matrix(Int, "active")
    opacity = Int("opacity")
    rand_cons = Int("rand_cons")
    (
        inv0_grammar,
        inv1_grammar,
        ps_grammar_fn,
        target_lang,
        fns_synths,
    ) = get_dissolve_general_search_space(
        driver=driver,
        depth=parser_args.depth,
        relaxed=parser_args.relaxed,
    )
    dissolve_blend_8 = driver.analyze(
        llvm_filepath="tenspiler/blend/cpp/for_synthesis/dissolve_blend_8.ll",
        loops_filepath="tenspiler/blend/cpp/for_synthesis/dissolve_blend_8.loops",
        fn_name="dissolve_blend_8",
        target_lang_fn=target_lang,
        inv_grammars={
            "dissolve_blend_8_inv0": inv0_grammar,
            "dissolve_blend_8_inv1": inv1_grammar,
        },
        ps_grammar=ps_grammar_fn,
    )

    base = Matrix(Int, "base")
    active = Matrix(Int, "active")
    opacity = Int("opacity")
    rand_cons = Int("rand_cons")
    driver.add_var_objects([base, active, opacity, rand_cons])

    # Add preconditions
    driver.add_precondition(base.len() > 1)
    driver.add_precondition(base.len() == active.len())
    driver.add_precondition(base[0].len() == active[0].len())

    driver.fns_synths = fns_synths
    dissolve_blend_8(base, active, opacity, rand_cons)

    relaxed_suffix = "_relaxed" if parser_args.relaxed else ""
    depth_suffix = f"_depth{parser_args.depth}"

    start_time = time.time()
    driver.synthesize(
        filename=f"dissolve_blend_8{depth_suffix}{relaxed_suffix}",
        rounds_to_guess=0,
        no_verify=True,
    )
    end_time = time.time()
    print(f"Synthesis took {end_time - start_time} seconds")
