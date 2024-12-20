from collections import defaultdict
from typing import List

from metalift.frontend.llvm import Driver, InvGrammar
from metalift.ir import (
    Bool,
    FnDeclRecursive,
    Int,
    Object,
    call,
    choose,
    fn_decl_recursive,
    ite,
)
from tests.python.utils.utils import codegen


def target_lang() -> List[FnDeclRecursive]:
    x = Int("x")
    sum_n = fn_decl_recursive(
        "sum_n",
        Int,
        ite(
            x >= 1,
            x + call("sum_n", Int, x - 1),
            Int(0),
        ).src,
        x.src,
    )
    return [sum_n]


def ps_grammar(
    writes: List[Object], reads: List[Object], in_scope: List[Object], relaxed: bool
) -> Bool:
    ret_val = writes[0]
    return ret_val == call("sum_n", Int, choose(Int(1), Int(2)))


def inv_grammar(
    writes: List[Object], reads: List[Object], in_scope: List[Object], relaxed: bool
) -> Bool:
    e = choose(*writes)
    f = choose(Int(1), Int(2), Int(3))
    c = e == call("sum_n", Int, e - f)
    d = (e >= f).And(e <= f)
    b = c.And(d)
    return b


if __name__ == "__main__":
    driver = Driver()
    test = driver.analyze(
        llvm_filepath="tests/llvm/while4.ll",
        loops_filepath="tests/llvm/while4.loops",
        fn_name="test",
        target_lang_fn=target_lang,
        inv_grammars=defaultdict(lambda: InvGrammar(inv_grammar, [])),
        ps_grammar=ps_grammar,
    )

    test()

    driver.synthesize(filename="while4")
    print("\n\ngenerated code:" + test.codegen(codegen))
