from collections import defaultdict
from typing import List

from metalift.frontend.llvm import Driver, InvGrammar
from metalift.ir import Bool, FnDecl, Int, Object, ite
from tests.python.utils.utils import codegen


def target_lang() -> List[FnDecl]:
    return []


def ps_grammar(
    writes: List[Object], reads: List[Object], in_scope: List[Object], relaxed: bool
) -> Bool:
    ret_val = writes[0]
    i = reads[0]
    return ret_val == ite(i > 10, Int(1), Int(2))


def inv_grammar(
    writes: List[Object], reads: List[Object], in_scope: List[Object], relaxed: bool
) -> Bool:
    raise Exception("no loop in the source")


if __name__ == "__main__":
    driver = Driver()
    test = driver.analyze(
        llvm_filepath="tests/llvm/ite1.ll",
        loops_filepath="tests/llvm/ite1.loops",
        fn_name="test",
        target_lang_fn=target_lang,
        inv_grammars=defaultdict(lambda: InvGrammar(inv_grammar, [])),
        ps_grammar=ps_grammar,
    )

    i = Int("i")
    driver.add_var_object(i)
    test(i)

    driver.synthesize(filename="ite1")
    print("\n\ngenerated code:" + test.codegen(codegen))
