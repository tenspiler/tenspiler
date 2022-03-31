from __future__ import annotations

import multiprocessing as mp
import multiprocessing.pool
import queue
import traceback

from actors.lattices import Lattice
from analysis import CodeInfo
import process_tracker
import ir
from ir import Expr
from actors.synthesis import SynthesizeFun, synthesize_actor
from synthesis_common import SynthesisFailed

from typing import Any, Callable, Iterator, List, Optional, Tuple


def synthesize_crdt(
    queue: queue.Queue[Tuple[Any, Optional[List[Expr]]]],
    synthStateStructure: List[Lattice],
    initState: Callable[[Any], Expr],
    grammarStateInvariant: Callable[[Expr], Expr],
    grammarSupportedCommand: Callable[[Expr, Any], Expr],
    inOrder: Callable[[Any, Any], Expr],
    opPrecondition: Callable[[Any], Expr],
    grammar: Callable[[CodeInfo, Any], Expr],
    grammarQuery: Callable[[CodeInfo], Expr],
    grammarEquivalence: Callable[[Expr, Expr], Expr],
    targetLang: Callable[[], List[Expr]],
    synthesize: SynthesizeFun,
    useOpList: bool,
    stateTypeHint: Optional[ir.Type],
    opArgTypeHint: Optional[List[ir.Type]],
    queryArgTypeHint: Optional[List[ir.Type]],
    queryRetTypeHint: Optional[ir.Type],
    filename: str,
    fnNameBase: str,
    loopsFile: str,
    cvcPath: str,
    uid: int,
) -> None:
    synthStateType = ir.Tuple(*[a.ir_type() for a in synthStateStructure])

    try:
        queue.put(
            (
                synthStateStructure,
                synthesize_actor(
                    filename,
                    fnNameBase,
                    loopsFile,
                    cvcPath,
                    synthStateType,
                    lambda: initState(synthStateStructure),
                    grammarStateInvariant,
                    grammarSupportedCommand,
                    inOrder,
                    opPrecondition,
                    lambda ci: grammar(ci, synthStateStructure),
                    grammarQuery,
                    grammarEquivalence,
                    targetLang,
                    synthesize,
                    uid=uid,
                    useOpList=useOpList,
                    stateTypeHint=stateTypeHint,
                    opArgTypeHint=opArgTypeHint,
                    queryArgTypeHint=queryArgTypeHint,
                    queryRetTypeHint=queryRetTypeHint,
                    log=False,
                ),
            )
        )
    except SynthesisFailed:
        queue.put((synthStateStructure, None))
    except:
        traceback.print_exc()
        queue.put((synthStateStructure, None))


def search_crdt_structures(
    initState: Callable[[Any], Expr],
    grammarStateInvariant: Callable[[Expr], Expr],
    grammarSupportedCommand: Callable[[Expr, Any], Expr],
    inOrder: Callable[[Any, Any], Expr],
    opPrecondition: Callable[[Any], Expr],
    grammar: Callable[[CodeInfo, Any], Expr],
    grammarQuery: Callable[[CodeInfo], Expr],
    grammarEquivalence: Callable[[Expr, Expr], Expr],
    targetLang: Callable[[], List[Expr]],
    synthesize: SynthesizeFun,
    filename: str,
    fnNameBase: str,
    loopsFile: str,
    cvcPath: str,
    useOpList: bool,
    structureCandidates: Iterator[Any],
    stateTypeHint: Optional[ir.Type] = None,
    opArgTypeHint: Optional[List[ir.Type]] = None,
    queryArgTypeHint: Optional[List[ir.Type]] = None,
    queryRetTypeHint: Optional[ir.Type] = None,
) -> None:
    q: queue.Queue[Tuple[Any, Optional[List[Expr]]]] = queue.Queue()
    queue_size = 0
    uid = 0

    next_res_type = None
    next_res = None

    try:
        with multiprocessing.pool.ThreadPool() as pool:
            while True:
                while queue_size < (mp.cpu_count() // 2):
                    next_structure_type = next(structureCandidates, None)
                    if next_structure_type is None:
                        break
                    else:

                        def error_callback(e: BaseException) -> None:
                            raise e

                        try:
                            synthStateType = ir.Tuple(
                                *[a.ir_type() for a in next_structure_type]
                            )
                            synthesize_actor(
                                filename,
                                fnNameBase,
                                loopsFile,
                                cvcPath,
                                synthStateType,
                                lambda: initState(next_structure_type),
                                grammarStateInvariant,
                                grammarSupportedCommand,
                                inOrder,
                                opPrecondition,
                                lambda ci: grammar(ci, next_structure_type),
                                grammarQuery,
                                grammarEquivalence,
                                targetLang,
                                synthesize,
                                uid=uid,
                                useOpList=useOpList,
                                stateTypeHint=stateTypeHint,
                                opArgTypeHint=opArgTypeHint,
                                queryArgTypeHint=queryArgTypeHint,
                                queryRetTypeHint=queryRetTypeHint,
                                log=False,
                                skipSynth=True,
                            )
                        except KeyError:
                            # this is due to a grammar not being able to find a value
                            continue

                        print(f"Enqueueing #{uid}:", next_structure_type)
                        pool.apply_async(
                            synthesize_crdt,
                            args=(
                                q,
                                next_structure_type,
                                initState,
                                grammarStateInvariant,
                                grammarSupportedCommand,
                                inOrder,
                                opPrecondition,
                                grammar,
                                grammarQuery,
                                grammarEquivalence,
                                targetLang,
                                synthesize,
                                useOpList,
                                stateTypeHint,
                                opArgTypeHint,
                                queryArgTypeHint,
                                queryRetTypeHint,
                                filename,
                                fnNameBase,
                                loopsFile,
                                cvcPath,
                                uid,
                            ),
                            error_callback=error_callback,
                        )
                        uid += 1
                        queue_size += 1

                if queue_size == 0:
                    raise Exception("no more structures")
                else:
                    (next_res_type, next_res) = q.get(block=True, timeout=None)
                    queue_size -= 1
                    if next_res != None:
                        break
                    else:
                        print("Failed to synthesize with structure", next_res_type)

        if next_res == None:
            raise Exception("Synthesis failed")
        else:
            print(
                "\n========================= SYNTHESIS COMPLETE =========================\n"
            )
            print("State Structure:", next_res_type)
            print("\nRuntime Logic:")
            print("\n\n".join([c.toSMT() for c in next_res]))  # type: ignore
    finally:
        for p in process_tracker.all_processes:
            p.terminate()