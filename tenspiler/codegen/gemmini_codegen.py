from typing import Any, Dict, Tuple, Union, List

from metalift.ir import (
    Add,
    Bool,
    Call,
    Div,
    Eq,
    Expr,
    FnDecl,
    FnDeclRecursive,
    Ge,
    Gt,
    Int,
    Le,
    Lit,
    Lt,
    Mod,
    Mul,
    Not,
    ObjectT,
    Sub,
    Var,
    List as mlList,
    And,
    Or,
    Matrix
)
from tenspiler.codegen.utils import DataType
from tenspiler.tenspiler_common import (
    MAP_INT_TO_INT,
    MATRIX_ELEMWISE_ADD,
    MATRIX_ELEMWISE_DIV,
    MATRIX_ELEMWISE_MUL,
    MATRIX_ELEMWISE_SUB,
    MATRIX_SCALAR_ADD,
    MATRIX_SCALAR_DIV,
    MATRIX_SCALAR_MUL,
    MATRIX_SCALAR_SUB,
    SCALAR_MATRIX_DIV,
    SCALAR_MATRIX_SUB,
    SCALAR_VEC_DIV,
    SCALAR_VEC_SUB,
    VEC_ELEMWISE_ADD,
    VEC_ELEMWISE_DIV,
    VEC_ELEMWISE_MUL,
    VEC_ELEMWISE_SUB,
    VEC_SCALAR_ADD,
    VEC_SCALAR_DIV,
    VEC_SCALAR_MUL,
    VEC_SCALAR_SUB,
)

translations = {
    VEC_ELEMWISE_ADD: lambda processed_args, curr_var, var_dimensions: f"tiled_resadd_auto({var_dimensions[curr_var][0]}, {var_dimensions[curr_var][1]}, 1, 1, 1, {processed_args[0]}[0], {processed_args[1]}[0], {curr_var}[0], false, WS); \n",
    MATRIX_ELEMWISE_ADD: lambda processed_args, curr_var, var_dimensions: f"tiled_resadd_auto({var_dimensions[curr_var][0]}, {var_dimensions[curr_var][1]}, 1, 1, 1, {processed_args[0]}[0], {processed_args[1]}[0], {curr_var}[0], false, WS); \n",
    VEC_SCALAR_ADD: lambda processed_args, curr_var, var_dimensions, is_floor=False: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t {curr_var}[i][0] = {processed_args[0]}[i][0] + {processed_args[1]}; \n }} \n",
    MATRIX_SCALAR_ADD: lambda processed_args, curr_var, var_dimensions, is_floor=False: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t for (int j = 0; j < {var_dimensions[curr_var][1]}; j++) {{ \n \t \t {curr_var}[i][j] = {processed_args[0]}[i][j] + {processed_args[1]}; \n \t }} \n }} \n",
    
    VEC_ELEMWISE_SUB: lambda processed_args, curr_var, var_dimensions: f"tiled_resadd_auto({var_dimensions[curr_var][0]}, {var_dimensions[curr_var][1]}, 1, -1, 1, {processed_args[0]}[0], {processed_args[1]}[0], {curr_var}[0], false, WS); \n",
    MATRIX_ELEMWISE_SUB: lambda processed_args, curr_var, var_dimensions: f"tiled_resadd_auto({var_dimensions[curr_var][0]}, {var_dimensions[curr_var][1]}, 1, -1, 1, {processed_args[0]}[0], {processed_args[1]}[0], {curr_var}[0], false, WS); \n",
    
    SCALAR_VEC_SUB: lambda processed_args, curr_var, var_dimensions, is_floor=False: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t {curr_var}[i][0] = {processed_args[0]} - {processed_args[1]}[i][0]; \n }} \n",
    SCALAR_MATRIX_SUB: lambda processed_args, curr_var, var_dimensions, is_floor=False: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t for (int j = 0; j < {var_dimensions[curr_var][1]}; j++) {{ \n \t \t {curr_var}[i][j] = {processed_args[0]} - {processed_args[1]}[i][j]; \n \t }} \n }} \n",
    
    VEC_SCALAR_SUB: lambda processed_args, curr_var, var_dimensions, is_floor=False: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t {curr_var}[i][0] = {processed_args[1]}[i][0] - {processed_args[0]}; \n }} \n",
    MATRIX_SCALAR_SUB: lambda processed_args, curr_var, var_dimensions, is_floor=False: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t for (int j = 0; j < {var_dimensions[curr_var][1]}; j++) {{ \n \t \t {curr_var}[i][j] = {processed_args[1]}[i][j] - {processed_args[0]}; \n \t }} \n }} \n",

    VEC_ELEMWISE_MUL: lambda processed_args, curr_var, var_dimensions: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t {curr_var}[i][0] = {processed_args[0]}[i][0] * {processed_args[1]}[i][0]; \n }} \n",
    MATRIX_ELEMWISE_MUL: lambda processed_args, curr_var, var_dimensions: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t for (int j = 0; j < {var_dimensions[curr_var][1]}; j++) {{ \n \t \t {curr_var}[i][j] = {processed_args[0]}[i][j] * {processed_args[1]}[i][j]; \n \t }} \n }} \n",
    VEC_SCALAR_MUL: lambda processed_args: f"GEMMINI_ACC_SCALE({processed_args[1]}, {processed_args[0]}); \n",
    MATRIX_SCALAR_MUL: lambda processed_args: f"GEMMINI_ACC_SCALE({processed_args[1]}, {processed_args[0]}); \n",

    VEC_ELEMWISE_DIV: lambda processed_args, curr_var, var_dimensions, is_floor=False: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t {curr_var}[i][0] = {processed_args[0]}[i][0] / (float){processed_args[1]}[i][0]; \n }} \n",
    MATRIX_ELEMWISE_DIV: lambda processed_args, curr_var, var_dimensions, is_floor=False: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t for (int j = 0; j < {var_dimensions[curr_var][1]}; j++) {{ \n \t \t {curr_var}[i][j] = {processed_args[0]}[i][j] / (float){processed_args[1]}[i][j]; \n \t }} \n }} \n",
    
    SCALAR_VEC_DIV: lambda processed_args, curr_var, var_dimensions, is_floor=False: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t {curr_var}[i][0] = {processed_args[0]} / (float) {processed_args[1]}[i][0]; \n }} \n",
    SCALAR_MATRIX_DIV: lambda processed_args, curr_var, var_dimensions, is_floor=False: f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t for (int j = 0; j < {var_dimensions[curr_var][1]}; j++) {{ \n \t \t {curr_var}[i][j] = {processed_args[0]} / (float){processed_args[1]}[i][j]; \n \t }} \n }} \n",

    VEC_SCALAR_DIV: lambda processed_args, is_floor=False: f"GEMMINI_ACC_SCALE({processed_args[1]}, 1 / (float){processed_args[0]}); \n",
    MATRIX_SCALAR_DIV: lambda processed_args, is_floor=False: f"GEMMINI_ACC_SCALE({processed_args[1]}, 1 / (float){processed_args[0]}); \n",

    "matrix_vec_mul": lambda processed_args, curr_var: f"tiled_matmul_auto(LEN, LEN, 1, (elem_t*) {processed_args[0]}, (elem_t*) {processed_args[1]}, NULL, {curr_var}, 1, LEN, LEN, LEN, 1, 1, 1, 0, 1, 0, false, false, false, false, 0, 0, WS); \n",

    "reduce_sum": lambda processed_args, curr_var, var_dimensions: f"tiled_global_average({processed_args[0]}[0], (elem_t*) {curr_var}, 1, 1, {var_dimensions[curr_var][0]}, 1); \n",

    "list_take": lambda processed_args, curr_var: f"for (int i = 0; i < {processed_args[1]}; i++) {{ \n \t {curr_var}[i][0] = {processed_args[0]}[i][0]; \n }} \n",

    Add: lambda processed_args: f"({processed_args[0]}) + ({processed_args[1]})",
    Sub: lambda processed_args: f"({processed_args[0]}) - ({processed_args[1]})",
    Mul: lambda processed_args: f"({processed_args[0]}) * ({processed_args[1]})",
    Div: lambda processed_args: f"({processed_args[0]}) / ({processed_args[1]})",
    # "float_div": lambda processed_args: f"({processed_args[0]}) / ({processed_args[1]})",
    Mod: lambda processed_args: f"({processed_args[0]}) % ({processed_args[1]})",
}

def gemmini_codegen(
    ps_fn_decl: Union[FnDecl, FnDeclRecursive],
    all_synthesized_fns: Dict[str, Expr],
    d_type: DataType = DataType.FLOAT,
) -> str:
    temp_var_count: int = 0
    def helper(expr: Any, vars_to_replace: Dict[str, Expr] = {}, curr_var: str = "", var_dimensions: Dict[str, List[str]] = {}) -> Tuple[str, ObjectT]:
        nonlocal temp_var_count
        global translations
        if not isinstance(expr, Expr):
            return str(expr), None
        if isinstance(expr, Call):
            processed_args = []
            res = ""
            fn_name = expr.name()
            #special case optimization
            if fn_name == VEC_ELEMWISE_ADD or fn_name == MATRIX_ELEMWISE_ADD:
                args = expr.arguments()
                if isinstance(args[0], Call) and isinstance(args[1], Call) and args[0].name() == VEC_SCALAR_MUL and args[1].name() == VEC_SCALAR_MUL:
                    expr1_args = [helper(arg, vars_to_replace, "", var_dimensions)[0] for arg in args[0].arguments()]
                    expr2_args = [helper(arg, vars_to_replace, "", var_dimensions)[0] for arg in args[1].arguments()]
                    var_dimensions[curr_var] = [var_dimensions[expr1_args[1]][0], var_dimensions[expr1_args[1]][1]]
                    return f"tiled_resadd_auto({var_dimensions[curr_var][0]}, {var_dimensions[curr_var][1]}, {expr1_args[0]}, {expr2_args[0]}, 1, {expr1_args[1]}[0], {expr2_args[1]}[0], {curr_var}[0], false, WS); \n", expr.type
                    
            for arg in expr.arguments():
                if (isinstance(arg, Call)):
                    temp_var_name = f"temp{temp_var_count}"
                    temp_var_count += 1
                    #this assumes down stream call will actually add "var =" if needed. it will also add the dimentionality to var_dimensions if necessary
                    (var_expr, var_type, *rest) = helper(arg, vars_to_replace, temp_var_name, var_dimensions)
 
                    if var_type == Matrix[Int] or var_type == mlList[Int]:
                        var_def = f"static elem_t {temp_var_name}[{var_dimensions[temp_var_name][0]}][{var_dimensions[temp_var_name][1]}]; \n"
                    elif var_type == Int:
                        var_def = f"static elem_t {temp_var_name}; \n"
                        continue
                    elif var_type == Bool:
                        var_def = f"static bool {temp_var_name}; \n"
                        continue
                    else:
                        raise Exception(f"Cannot create variable of type {var_type}")
                    res += var_def
                    res += var_expr
                    processed_args.append(temp_var_name)
                else:
                    processed_args.append(helper(arg, vars_to_replace, "", var_dimensions)[0])

            
            if fn_name == VEC_ELEMWISE_ADD or fn_name == MATRIX_ELEMWISE_ADD:
                var_dimensions[curr_var] = [var_dimensions[processed_args[0]][0], var_dimensions[processed_args[0]][1]]
                return res + translations[fn_name](processed_args, curr_var, var_dimensions), expr.type
            elif fn_name == VEC_ELEMWISE_SUB or fn_name == MATRIX_ELEMWISE_SUB:
                var_dimensions[curr_var] = [var_dimensions[processed_args[0]][0], var_dimensions[processed_args[0]][1]]
                return res + translations[fn_name](processed_args, curr_var, var_dimensions), expr.type
            elif fn_name == VEC_ELEMWISE_MUL or fn_name == MATRIX_ELEMWISE_MUL:
                var_dimensions[curr_var] = [var_dimensions[processed_args[0]][0], var_dimensions[processed_args[0]][1]]
                return res + translations[fn_name](processed_args, curr_var, var_dimensions), expr.type
            elif fn_name == VEC_ELEMWISE_DIV or fn_name == MATRIX_ELEMWISE_DIV:
                var_dimensions[curr_var] = [var_dimensions[processed_args[0]][0], var_dimensions[processed_args[0]][1]]
                return res + translations[fn_name](processed_args, curr_var, var_dimensions), expr.type
            elif fn_name == VEC_SCALAR_ADD or fn_name == MATRIX_SCALAR_ADD or fn_name == VEC_SCALAR_SUB or fn_name == MATRIX_SCALAR_SUB:
                var_dimensions[curr_var] = [var_dimensions[processed_args[1]][0], var_dimensions[processed_args[1]][1]]
                return res + translations[fn_name](processed_args, curr_var, var_dimensions), expr.type
            elif fn_name == VEC_SCALAR_MUL or fn_name == MATRIX_SCALAR_MUL or fn_name == VEC_SCALAR_DIV or fn_name == MATRIX_SCALAR_DIV:
                var_dimensions[curr_var] = [var_dimensions[processed_args[1]][0], var_dimensions[processed_args[1]][1]]
                return res + translations[fn_name](processed_args), expr.type
            elif fn_name == SCALAR_VEC_SUB or fn_name == SCALAR_MATRIX_SUB or fn_name == SCALAR_VEC_DIV or fn_name == SCALAR_MATRIX_DIV:
                var_dimensions[curr_var] = [var_dimensions[processed_args[1]][0], var_dimensions[processed_args[1]][1]]
                return res + translations[fn_name](processed_args, curr_var, var_dimensions), expr.type

            elif fn_name == "matrix_vec_mul":
                # result_matrix_var = f"result_matrix{temp_var_count}"
                # temp_var_count += 1
                # result_matrix_var_def = f"static elem_t {result_matrix_var}[{var_dimensions[processed_args[0]][0]}][{var_dimensions[processed_args[0]][0]}]; \n"
                # var_dimensions[result_matrix_var] = [var_dimensions[processed_args[0]][0], var_dimensions[processed_args[0]][0]]
                # res += result_matrix_var_def
                # res +=  translations[fn_name](processed_args, result_matrix_var)
                # # extract first column of result matrix
                # var_dimensions[curr_var] = [var_dimensions[processed_args[0]][0], var_dimensions[processed_args[0]][1]]
                # res += f"for (int i = 0; i < {var_dimensions[curr_var][0]}; i++) {{ \n \t {curr_var}[i][0] = {result_matrix_var}[i][0]; \n }} \n"
                # return res, expr.type
                var_dimensions[curr_var] = [var_dimensions[processed_args[0]][0], var_dimensions[processed_args[1]][1]]
                res +=  translations[fn_name](processed_args, curr_var)
                return res, expr.type
            elif fn_name == "reduce_sum":
                #TODO: need to extract the result of reduce_sum? curr_var should be int
                # expanded_var = f"unflat{temp_var_count}"
                # temp_var_count += 1
                # expanded_var_def = f"static elem_t {expanded_var}[{var_dimensions[processed_args[0]][1]}][{var_dimensions[processed_args[0]][1]}]; \n"
                # var_dimensions[expanded_var] = [var_dimensions[processed_args[0]][1], var_dimensions[processed_args[0]][1]]
                # res += expanded_var_def
                # res += f"int v{temp_var_count} = 0; \n for (int i = 0; i < {var_dimensions[expanded_var][0]}; i++) {{ \n \t for (int j = 0; j < {var_dimensions[expanded_var][1]}; j++) {{ \n \t \t {expanded_var}[i][j] = {processed_args[0]}[v{temp_var_count}][0]; \n \t \t v{temp_var_count}++; \n \t}} \n}} \n"
                # temp_var_count += 1

                # input_arg = expanded_var
                # res += f"tiled_global_average({input_arg}[0], {curr_var}, 1, 1, {var_dimensions[expanded_var][0]}, 1); \n"
                res += translations[fn_name](processed_args, curr_var, var_dimensions)
                res += f"{curr_var} = {curr_var} * {var_dimensions[processed_args[0]][0]} * {var_dimensions[processed_args[0]][1]}; \n"
                return res, expr.type
            
            elif fn_name == "list_take":
                var_dimensions[curr_var] = [processed_args[1], processed_args[1]]
                return res + translations[fn_name](processed_args, curr_var), expr.type
                
        # Arithmetic operations
        processed_args = [helper(arg, vars_to_replace, "", var_dimensions) for arg in expr.args]
        processed_args_types = [a[1] for a in processed_args]
        processed_args = [a[0] for a in processed_args]
        if any(isinstance(expr, cls) for cls in [Add, Sub, Mul, Div, Mod]):
            is_arg_type_int = all([a_type is Int for a_type in processed_args_types])
            ret_type = Int if is_arg_type_int else [a_type for a_type in processed_args_types if a_type is not Int and a_type is not None][0]
            if ret_type != Int:
                raise Exception(f"Arithmatic of non-integer type")
            if isinstance(expr, Div) and d_type == DataType.FLOAT:
                return translations["float_div"](processed_args), ret_type
            return translations[type(expr)](processed_args), ret_type 
        # Relational operations
        elif any(isinstance(expr, cls) for cls in [Gt, Ge, Eq, Lt, Le]):
            is_arg_type_int = all([a_type is Int for a_type in processed_args_types])
            ret_type = Bool if is_arg_type_int else mlList[Bool]
            if ret_type != Bool:
                raise Exception(f"Relational that doesn't return Bool")
            return translations[type(expr)](processed_args, is_arg_type_int), ret_type
        elif any(isinstance(expr, cls) for cls in [And, Or, Not]):
            is_arg_type_prim = all([a_type is Int or a_type is Bool for a_type in processed_args_types])
            ret_type = Bool if is_arg_type_prim else mlList[Bool]
            if ret_type != Bool:
                raise Exception(f"Logical that doesn't return Bool")
            return translations[type(expr)](processed_args, is_arg_type_prim), ret_type

        # Other
        elif isinstance(expr, Lit):
            return f"{expr.val()}", expr.type
        elif isinstance(expr, Var):
            if expr.name() in vars_to_replace:
                return helper(vars_to_replace[expr.name()], vars_to_replace, "", var_dimensions)
            return expr.name(), expr.type
        return str(expr)

    #TODO: we need some way of knowing what is the dimensionality of output and input var if they are matrix or list or int, and var names
    #could be no size (integer) or [LEN,LEN]
    #vector of size LEN is also [LEN, LEN] but only first column is used. PADDING

    return helper(ps_fn_decl.body(), {}, "out", {"out": ["LEN", "LEN"], "base": ["LEN", "LEN"], "active": ["LEN", "LEN"], "output": ["LEN", "LEN"], "input": ["LEN", "LEN"], "weight": ["LEN", "LEN"]})[0]

#TODO: write kernel function wrapper and glue code function wrapper. ALSO need info on variable names, types    
    # typedef int8_t elem_t; or float? but this is already in the included file "include/gemmini_params.h"?

#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include "include/gemmini_params.h"
#include "include/gemmini.h"
#ifndef BAREMETAL
#include <sys/mman.h>
#endif

# define LEN 200