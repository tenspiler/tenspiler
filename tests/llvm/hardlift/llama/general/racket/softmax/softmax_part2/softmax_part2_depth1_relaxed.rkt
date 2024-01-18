#lang rosette
(require "./bounded.rkt")
(require "./utils.rkt")
(require rosette/lib/angelic rosette/lib/match rosette/lib/synthax)
(require rosette/solver/smt/bitwuzla)
(current-solver (bitwuzla #:path "/Users/jieq/Desktop/bitwuzla/build/src/main/bitwuzla" #:options (hash ':seed 0)))



 (define-bounded (vec_elemwise_add x y)
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (+ (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_add (list-tail-noerr x 1 ) (list-tail-noerr y 1 )) ) ))


 (define-bounded (vec_elemwise_sub x y)
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (- (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_sub (list-tail-noerr x 1 ) (list-tail-noerr y 1 )) ) ))


 (define-bounded (vec_elemwise_mul x y)
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (* (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_mul (list-tail-noerr x 1 ) (list-tail-noerr y 1 )) ) ))


 (define-bounded (vec_elemwise_div x y)
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (quotient-noerr (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_div (list-tail-noerr x 1 ) (list-tail-noerr y 1 )) ) ))


 (define-bounded (vec_scalar_add a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (+ a (list-ref-noerr x 0 ) ) (vec_scalar_add a (list-tail-noerr x 1 )) ) ))


 (define-bounded (vec_scalar_sub a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (- (list-ref-noerr x 0 ) a ) (vec_scalar_sub a (list-tail-noerr x 1 )) ) ))


 (define-bounded (vec_scalar_mul a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (* a (list-ref-noerr x 0 ) ) (vec_scalar_mul a (list-tail-noerr x 1 )) ) ))


 (define-bounded (vec_scalar_div a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (quotient-noerr (list-ref-noerr x 0 ) a ) (vec_scalar_div a (list-tail-noerr x 1 )) ) ))


 (define-bounded (scalar_vec_sub a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (- a (list-ref-noerr x 0 ) ) (scalar_vec_sub a (list-tail-noerr x 1 )) ) ))


 (define-bounded (scalar_vec_div a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (quotient-noerr a (list-ref-noerr x 0 ) ) (scalar_vec_div a (list-tail-noerr x 1 )) ) ))


 (define-bounded (vec_map x map_int_to_int)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (map_int_to_int (list-ref-noerr x 0 )) (vec_map (list-tail-noerr x 1 ) map_int_to_int) ) ))

(define-grammar (softmax_part2_inv0_gram agg.result cur i input max_pos max_val)
 [rv (choose (&& (&& (>= i (v0) ) (<= i (v1) ) ) (equal? agg.result (v2) ) ))]
[v0 (choose 0 (- 0 1 ) (+ 0 1 ))]
[v1 (choose max_pos (- max_pos 1 ) (+ max_pos 1 ))]
[v2 (choose (v3) (v5))]
[v3 (choose (list-slice-noerr input (v0) (v4) ))]
[v4 (choose i (- i 1 ) (+ i 1 ))]
[v5 (choose (v6) (vec_elemwise_add (v3) (v3)) (vec_elemwise_sub (v3) (v3)) (vec_elemwise_mul (v3) (v3)) (vec_elemwise_div (v3) (v3)) (vec_scalar_add (v7) (v3)) (vec_scalar_sub (v7) (v3)) (vec_scalar_mul (v7) (v3)) (vec_scalar_div (v7) (v3)) (scalar_vec_sub (v7) (v3)) (scalar_vec_div (v7) (v3)))]
[v6 (choose (vec_map (v3) map_int_to_int))]
[v7 (choose max_val max_pos)]
)

(define-grammar (softmax_part2_ps_gram input max_pos max_val softmax_part2_rv)
 [rv (choose (equal? softmax_part2_rv (v0) ))]
[v0 (choose (v1) (v4))]
[v1 (choose (list-slice-noerr input (v2) (v3) ))]
[v2 (choose 0 (- 0 1 ) (+ 0 1 ))]
[v3 (choose max_pos (- max_pos 1 ) (+ max_pos 1 ))]
[v4 (choose (v5) (vec_elemwise_add (v1) (v1)) (vec_elemwise_sub (v1) (v1)) (vec_elemwise_mul (v1) (v1)) (vec_elemwise_div (v1) (v1)) (vec_scalar_add (v6) (v1)) (vec_scalar_sub (v6) (v1)) (vec_scalar_mul (v6) (v1)) (vec_scalar_div (v6) (v1)) (scalar_vec_sub (v6) (v1)) (scalar_vec_div (v6) (v1)))]
[v5 (choose (vec_map (v1) map_int_to_int))]
[v6 (choose max_val max_pos)]
)

(define-grammar (map_int_to_int_gram int_x)
 [rv (choose (v0))]
[v0 (choose (integer-exp-noerr int_x ) (integer-sqrt-noerr int_x ))]
)

(define (softmax_part2_inv0 agg.result cur i input max_pos max_val) (softmax_part2_inv0_gram agg.result cur i input max_pos max_val #:depth 10))
(define (softmax_part2_ps input max_pos max_val softmax_part2_rv) (softmax_part2_ps_gram input max_pos max_val softmax_part2_rv #:depth 10))

(define (map_int_to_int int_x) (map_int_to_int_gram int_x #:depth 10))

(define-symbolic agg.result_BOUNDEDSET-len integer?)
(define-symbolic agg.result_BOUNDEDSET-0 integer?)
(define-symbolic agg.result_BOUNDEDSET-1 integer?)
(define agg.result (take (list agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1) agg.result_BOUNDEDSET-len))
(define-symbolic cur integer?)
(define-symbolic i integer?)
(define-symbolic input_BOUNDEDSET-len integer?)
(define-symbolic input_BOUNDEDSET-0 integer?)
(define-symbolic input_BOUNDEDSET-1 integer?)
(define input (take (list input_BOUNDEDSET-0 input_BOUNDEDSET-1) input_BOUNDEDSET-len))
(define-symbolic max_pos integer?)
(define-symbolic max_val integer?)
(define-symbolic softmax_part2_rv_BOUNDEDSET-len integer?)
(define-symbolic softmax_part2_rv_BOUNDEDSET-0 integer?)
(define-symbolic softmax_part2_rv_BOUNDEDSET-1 integer?)
(define softmax_part2_rv (take (list softmax_part2_rv_BOUNDEDSET-0 softmax_part2_rv_BOUNDEDSET-1) softmax_part2_rv_BOUNDEDSET-len))
(current-bitwidth 6)
(define (assertions)
 (assert (&& (&& (=> (&& (&& (> (length input ) 0 ) (<= max_pos (length input ) ) ) (>= max_pos 1 ) ) (softmax_part2_inv0 (list-empty ) 0 0 input max_pos max_val) ) (=> (&& (&& (&& (&& (< i max_pos ) (> (length input ) 0 ) ) (<= max_pos (length input ) ) ) (>= max_pos 1 ) ) (softmax_part2_inv0 agg.result cur i input max_pos max_val) ) (softmax_part2_inv0 (list-append agg.result (integer-exp-noerr (- (list-ref-noerr input i ) max_val ) ) ) (integer-exp-noerr (- (list-ref-noerr input i ) max_val ) ) (+ i 1 ) input max_pos max_val) ) ) (=> (or (&& (&& (&& (&& (! (< i max_pos ) ) (> (length input ) 0 ) ) (<= max_pos (length input ) ) ) (>= max_pos 1 ) ) (softmax_part2_inv0 agg.result cur i input max_pos max_val) ) (&& (&& (&& (&& (&& (! true ) (! (< i max_pos ) ) ) (> (length input ) 0 ) ) (<= max_pos (length input ) ) ) (>= max_pos 1 ) ) (softmax_part2_inv0 agg.result cur i input max_pos max_val) ) ) (softmax_part2_ps input max_pos max_val agg.result) ) )))


    (define sol0
        (synthesize
            #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 cur i input_BOUNDEDSET-len input_BOUNDEDSET-0 input_BOUNDEDSET-1 max_pos max_val softmax_part2_rv_BOUNDEDSET-len softmax_part2_rv_BOUNDEDSET-0 softmax_part2_rv_BOUNDEDSET-1)
            #:guarantee (assertions)
        )
    )
    (sat? sol0)
    (print-forms sol0)