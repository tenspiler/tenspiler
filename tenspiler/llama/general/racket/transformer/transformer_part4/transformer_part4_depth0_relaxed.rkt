#lang rosette
(require "./bounded.rkt")
(require "./utils.rkt")
(require rosette/lib/angelic rosette/lib/match rosette/lib/synthax)
(require rosette/solver/smt/bitwuzla)
(current-solver (bitwuzla #:path "/bitwuzla/build/src/main/bitwuzla" #:options (hash ':seed 0)))


 (define-bounded (vec_elemwise_add x y)
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (+ (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_add (list-tail-noerr x 1 ) (list-tail-noerr y 1 ) ) ) ))


 (define-bounded (vec_elemwise_sub x y)
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (- (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_sub (list-tail-noerr x 1 ) (list-tail-noerr y 1 ) ) ) ))


 (define-bounded (vec_elemwise_mul x y)
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (* (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_mul (list-tail-noerr x 1 ) (list-tail-noerr y 1 ) ) ) ))


 (define-bounded (vec_elemwise_div x y)
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (quotient-noerr (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_div (list-tail-noerr x 1 ) (list-tail-noerr y 1 ) ) ) ))


 (define-bounded (vec_scalar_add a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (+ a (list-ref-noerr x 0 ) ) (vec_scalar_add a (list-tail-noerr x 1 ) ) ) ))


 (define-bounded (vec_scalar_sub a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (- (list-ref-noerr x 0 ) a ) (vec_scalar_sub a (list-tail-noerr x 1 ) ) ) ))


 (define-bounded (vec_scalar_mul a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (* a (list-ref-noerr x 0 ) ) (vec_scalar_mul a (list-tail-noerr x 1 ) ) ) ))


 (define-bounded (vec_scalar_div a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (quotient-noerr (list-ref-noerr x 0 ) a ) (vec_scalar_div a (list-tail-noerr x 1 ) ) ) ))


 (define-bounded (scalar_vec_sub a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (- a (list-ref-noerr x 0 ) ) (scalar_vec_sub a (list-tail-noerr x 1 )) ) ))


 (define-bounded (scalar_vec_div a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (quotient-noerr a (list-ref-noerr x 0 ) ) (scalar_vec_div a (list-tail-noerr x 1 )) ) ))


 (define-bounded (vec_map x map_int_to_int)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (map_int_to_int (list-ref-noerr x 0 )) (vec_map (list-tail-noerr x 1 ) map_int_to_int ) ) ))

(define-grammar (transformer_part4_inv0_gram agg.result hidden_dim i input1 input2 ref.tmp)
 [rv (choose (&& (&& (>= i (v0) ) (<= i (v1) ) ) (equal? agg.result (v2) ) ))]
[v0 (choose 0 (- 0 1 ) (+ 0 1 ))]
[v1 (choose hidden_dim (- hidden_dim 1 ) (+ hidden_dim 1 ))]
[v2 (choose (v3))]
[v3 (choose (vec-slice-noerr input1 (v4) (v4) ) (vec-slice-noerr input2 (v4) (v4) ))]
[v4 (choose (v5))]
[v5 (choose (v6) (- (v6) 1 ) (+ (v6) 1 ))]
[v6 (choose 0 hidden_dim i)]
)

(define-grammar (transformer_part4_ps_gram input1 input2 hidden_dim transformer_part4_rv)
 [rv (choose (equal? transformer_part4_rv (v0) ))]
[v0 (choose (v1))]
[v1 (choose (vec-slice-noerr input1 (v2) (v2) ) (vec-slice-noerr input2 (v2) (v2) ))]
[v2 (choose (v3))]
[v3 (choose (v4) (- (v4) 1 ) (+ (v4) 1 ))]
[v4 (choose 0 hidden_dim)]
)

(define-grammar (map_int_to_int_gram int_x)
 [rv (choose (v0))]
[v0 (choose (integer-exp-noerr int_x ) (integer-sqrt-noerr int_x ))]
)

(define (transformer_part4_inv0 agg.result hidden_dim i input1 input2 ref.tmp) (transformer_part4_inv0_gram agg.result hidden_dim i input1 input2 ref.tmp #:depth 10))
(define (transformer_part4_ps input1 input2 hidden_dim transformer_part4_rv) (transformer_part4_ps_gram input1 input2 hidden_dim transformer_part4_rv #:depth 10))

(define (map_int_to_int int_x) (map_int_to_int_gram int_x #:depth 10))

(define-symbolic agg.result_BOUNDEDSET-len integer?)
(define-symbolic agg.result_BOUNDEDSET-0 integer?)
(define-symbolic agg.result_BOUNDEDSET-1 integer?)
(define agg.result (take (list agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1) agg.result_BOUNDEDSET-len))
(define-symbolic hidden_dim integer?)
(define-symbolic i integer?)
(define-symbolic input1_BOUNDEDSET-len integer?)
(define-symbolic input1_BOUNDEDSET-0 integer?)
(define-symbolic input1_BOUNDEDSET-1 integer?)
(define input1 (take (list input1_BOUNDEDSET-0 input1_BOUNDEDSET-1) input1_BOUNDEDSET-len))
(define-symbolic input2_BOUNDEDSET-len integer?)
(define-symbolic input2_BOUNDEDSET-0 integer?)
(define-symbolic input2_BOUNDEDSET-1 integer?)
(define input2 (take (list input2_BOUNDEDSET-0 input2_BOUNDEDSET-1) input2_BOUNDEDSET-len))
(define-symbolic ref.tmp integer?)
(define-symbolic transformer_part4_rv_BOUNDEDSET-len integer?)
(define-symbolic transformer_part4_rv_BOUNDEDSET-0 integer?)
(define-symbolic transformer_part4_rv_BOUNDEDSET-1 integer?)
(define transformer_part4_rv (take (list transformer_part4_rv_BOUNDEDSET-0 transformer_part4_rv_BOUNDEDSET-1) transformer_part4_rv_BOUNDEDSET-len))
(current-bitwidth 6)
(define (assertions)
 (assert (&& (&& (=> (&& (&& (>= hidden_dim 0 ) (>= (length input1 ) hidden_dim ) ) (>= (length input2 ) hidden_dim ) ) (transformer_part4_inv0 (list-empty ) hidden_dim 0 input1 input2 0) ) (=> (&& (&& (&& (&& (< i hidden_dim ) (>= hidden_dim 0 ) ) (>= (length input1 ) hidden_dim ) ) (>= (length input2 ) hidden_dim ) ) (transformer_part4_inv0 agg.result hidden_dim i input1 input2 ref.tmp) ) (transformer_part4_inv0 (list-append agg.result (* (list-ref-noerr input1 i ) (list-ref-noerr input2 i ) ) ) hidden_dim (+ i 1 ) input1 input2 (* (list-ref-noerr input1 i ) (list-ref-noerr input2 i ) )) ) ) (=> (or (&& (&& (&& (&& (! (< i hidden_dim ) ) (>= hidden_dim 0 ) ) (>= (length input1 ) hidden_dim ) ) (>= (length input2 ) hidden_dim ) ) (transformer_part4_inv0 agg.result hidden_dim i input1 input2 ref.tmp) ) (&& (&& (&& (&& (&& (! true ) (! (< i hidden_dim ) ) ) (>= hidden_dim 0 ) ) (>= (length input1 ) hidden_dim ) ) (>= (length input2 ) hidden_dim ) ) (transformer_part4_inv0 agg.result hidden_dim i input1 input2 ref.tmp) ) ) (transformer_part4_ps input1 input2 hidden_dim agg.result) ) )))


    (define sol0
        (synthesize
            #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 hidden_dim i input1_BOUNDEDSET-len input1_BOUNDEDSET-0 input1_BOUNDEDSET-1 input2_BOUNDEDSET-len input2_BOUNDEDSET-0 input2_BOUNDEDSET-1 ref.tmp transformer_part4_rv_BOUNDEDSET-len transformer_part4_rv_BOUNDEDSET-0 transformer_part4_rv_BOUNDEDSET-1)
            #:guarantee (assertions)
        )
    )
    (sat? sol0)
    (print-forms sol0)
