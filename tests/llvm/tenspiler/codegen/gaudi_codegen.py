from typing import Dict, Union

from metalift.ir import (
    Call,
    Expr,
    FnDecl,
    FnDeclRecursive,
    ObjectT,
    Var,
    create_object,
    is_list_type,
    is_matrix_type,
)

# def gaudi_codegen(
#     ps_expr: Expr, all_synthesized_fns: Dict[str, Expr], mode: str = "Float"
# ) -> str:
#     translations = {
#         "vec_elemwise_mul": lambda args: f"torch.multiply({helper(args[1])}, {helper(args[0])})",
#         "matrix_vec_mul": lambda args: f"torch.matmul({helper(args[0])}, {helper(args[1])})",
#         "matrix_transpose": lambda args: f"torch.transpose({helper(args[0])}, 0, 1)",
#         "test_sqrt": lambda args: f"torch.sqrt(torch.as_tensor({helper(args[0])}))",
#         #### Which of the name is used for sqrt?
#         "integer_sqrt": lambda args: f"torch.sqrt(torch.as_tensor({helper(args[0])}))",
#         "vec_map": lambda args: f"torch.sqrt(torch.as_tensor({helper(args[0])}))"
#         if helper(args[1]) == "integer_sqrt"
#         else f"torch.exp({helper(args[0])})",
#         "reduce_sum": lambda args: f"torch.sum({helper(args[0])})",
#         "reduce_max": lambda args: f"torch.max({helper(args[0])})",
#         "list_length": lambda args: f"{helper(args[0])}.size(dim=0)",
#         "vec_scalar_mul": lambda args: f"torch.multiply({helper(args[0])}, {helper(args[1])})",
#         "scalar_vec_div": lambda args: f"torch.divide({helper(args[0])}, {helper(args[1])})",
#         "rand": lambda args: "torch.randint(1, 2147483647, base.shape, dtype=torch.int32, device='cuda')",
#         "Ite": lambda args: f"torch.where({helper(args[0])}, {helper(args[1])}, {helper(args[2])})",
#         "Lt": lambda args: f"torch.less({helper(args[0])}, {helper(args[1])})",
#         "Le": lambda args: f"torch.less_equal({helper(args[0])}, {helper(args[1])})",
#         "Gt": lambda args: f"torch.greater({helper(args[0])}, {helper(args[1])})",
#         "Ge": lambda args: f"torch.greater_equal({helper(args[0])}, {helper(args[1])})",
#         "Eq": lambda args: f"torch.eq({helper(args[0])}, {helper(args[1])})",
#         # General for any of the frameworks
#         "vec_scalar_sub": lambda args: f"{helper(args[1])} - {helper(args[0])}",
#         "vec_scalar_div": lambda args: f"{helper(args[1])} / {helper(args[0])}",
#         "vec_scalar_add": lambda args: f"{helper(args[1])} + {helper(args[0])}",
#         "scalar_vec_sub": lambda args: f"{helper(args[0])} - {helper(args[1])}",
#         # General for any python code
#         "list_list_col_slice_with_length": lambda args: f"{helper(args[0])}[:, {helper(args[1])}:{helper(args[1])} + {args[2]}]",
#         "list_slice_with_length": lambda args: f"{helper(args[0])}[{helper(args[1])}:{helper(args[1])} + {args[2]}]",
#         "list_take": lambda args: f"{helper(args[0])}[:{helper(args[1])}]",
#         "Div": lambda args: f"{helper(args[0])} / {helper(args[1])}"
#         if mode == "Float"
#         else f"{helper(args[0])} // {helper(args[1])}",
#         "Mul": lambda args: f"{helper(args[0])} * {helper(args[1])}",
#         "Sub": lambda args: f"{helper(args[0])} - {helper(args[1])}",
#         "Add": lambda args: f"{helper(args[0])} + {helper(args[1])}",
#         "Mod": lambda args: f"{helper(args[0])} % {helper(args[1])}",
#         "And": lambda args: " and ".join(helper(a) for a in args),
#         "Or": lambda args: " or ".join(helper(a) for a in args),
#         "Not": lambda args: f"not {helper(args[0])}",
#         "vec_map": {
#             "integer_exp": lambda args: f"torch.exp({helper(args[0])})",
#             "integer_sqrt": lambda args: f"torch.sqrt({helper(args[0])})",
#         },
#         "matrix_selection_two_args": lambda args: f"torch.where({helper(args[0])}, {helper(args[1])}, {helper(args[2])})",
#     }
#     vars_to_replace = {"int_x": "base", "int_y": "active"}

#     def helper(expr):
#         if isinstance(expr, Call):
#             if expr.name() == "vec_map":
#                 map_fn_name = all_synthesized_fns["map_int_to_int"].body().name()
#                 return translations[expr.name()][map_fn_name]([expr.arguments()[0]])
#             if expr.name() == "matrix_selection_two_args":
#                 select_two_args_body = all_synthesized_fns["select_two_args"].body()
#                 cond = select_two_args_body.c()
#                 if_then = select_two_args_body.e1()
#                 if_else = select_two_args_body.e2()
#                 return translations[expr.name()]((cond, if_then, if_else))
#         elif isinstance(expr, Lit):
#             return f"{expr.val()}"
#         elif expr.__class__.__name__ in translations.keys():
#             return translations[expr.__class__.__name__](expr.args)
#         else:
#             name = "%s" % (expr)
#             return vars_to_replace.get(name, name)

#     return helper(ps_expr)


def gaudi_codegen(
    ps_fn_decl: Union[FnDecl, FnDeclRecursive],
    all_synthesized_fns: Dict[str, Union[FnDecl, FnDeclRecursive]],
    mode: str = "Float",  # TODO(jie): extract this as enum
) -> str:
    def expr_codegen(expr: Expr):
        # TODO(jie): handle floats
        if isinstance(expr, Var):
            if is_list_type(expr.type) or is_matrix_type(expr.type):
                return f"v_u8_ld_tnsr_b(inputCoord, {expr.name()})"
            else:
                return expr.name()
        elif isinstance(expr, Call):
            if expr.name() == "matrix_elemwise_add":
                first_arg, second_arg = expr.arguments()
                return (
                    f"v_u8_add_b({expr_codegen(first_arg)}, {expr_codegen(second_arg)})"
                )

    def type_codegen(ty: ObjectT) -> str:
        if is_list_type(ty) or is_matrix_type(ty):
            return "tensor"
        else:
            raise Exception(f"Unsupported Gaudi type {ty}")

    # First we generate the function header
    # If the return value is a tensor, then we include it in the arguments.
    # The return value is always the last argument to the fn decl
    # If we just call returnT then it's always a bool, due to the way we define the ps function
    if not is_list_type(ps_fn_decl.returnT()) and not is_matrix_type(
        ps_fn_decl.returnT()
    ):
        # TODO(jie): do you need to order
        ret_type_str = type_codegen(ps_fn_decl.returnT().type)
        arguments = [
            f"{type_codegen(arg.type)} {arg.name()}" for arg in ps_fn_decl.arguments()
        ]
        arguments_str = ", ".join(arguments)
        header = f"{ret_type_str} main({arguments_str})"
        body = None  # TODO(jie)
    else:
        rv_name = f"{ps_fn_decl.name()}_rv"
        rv = create_object(ps_fn_decl.returnT(), rv_name).src
        arguments = [
            f"{type_codegen(arg.type)} {arg.name()}"
            for arg in [*ps_fn_decl.arguments(), rv]
        ]
        arguments_str = ", ".join(arguments)
        header = f"void main({arguments_str})"
        # Generate the body
        # Generate the return value
        body = (
            f"v_u8_st_tnsr(outputCoord, {rv_name}, {expr_codegen(ps_fn_decl.body())});"
        )

    # If mode is float, then we operate on 64 elements at a time, else 256
    if mode == "Float":
        vec_len = 64
    else:
        vec_len = 256

    main_body = f"""
    int5 index_space_start = get_index_space_offset();
    int5 index_space_end = index_space_start + get_index_space_size();

    int5 inputCoord = {{ 0 }};
    int5 outputCoord = {{ 0 }};

    // We operate on a block of 256 char elements at a time.
    // Our index space operates on the basis of vec_len of 256.
    unsigned vec_len = {vec_len};
    for(int i = index_space_start[0]; i < index_space_end[0]; i++) {{
        #pragma loop_unroll(4)
        for (int j = index_space_start[1]; j < index_space_end[1]; j++) {{
            // index space mapping
            // coordinate 0 is for dim0.
            inputCoord[0] = outputCoord[0] = (i * vec_len);
            // coordinate 1 is for dim1.
            inputCoord[1] = outputCoord[1] = j;

            {body}
        }}
    }}
    """

    return f"""
    {header} {{
        {main_body}
    }}
    """