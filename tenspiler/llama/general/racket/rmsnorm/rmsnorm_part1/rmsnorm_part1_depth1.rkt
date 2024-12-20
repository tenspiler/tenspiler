#lang rosette
(require "./bounded.rkt")
(require "./utils.rkt")
(require rosette/lib/angelic rosette/lib/match rosette/lib/synthax)
(require rosette/solver/smt/bitwuzla)
(current-solver (bitwuzla #:path "/bitwuzla/build/src/main/bitwuzla" #:options (hash ':seed 0)))



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


 (define-bounded (reduce_max x)
(if (<= (length x ) 1 ) (list-ref-noerr x 0 ) (if (> (list-ref-noerr x 0 ) (reduce_max (list-tail-noerr x 1 )) ) (list-ref-noerr x 0 ) (reduce_max (list-tail-noerr x 1 )) ) ))


 (define-bounded (reduce_sum x)
(if (< (length x ) 1 ) 0 (+ (list-ref-noerr x 0 ) (reduce_sum (list-tail-noerr x 1 )) ) ))


 (define-bounded (reduce_mul x)
(if (< (length x ) 1 ) 1 (* (list-ref-noerr x 0 ) (reduce_mul (list-tail-noerr x 1 )) ) ))

(define-grammar (rmsnorm_part1_inv0_gram i input ss weight)
 [rv (choose (&& (&& (>= i 0 ) (<= i (length input ) ) ) (equal? ss (v0) ) ))]
[v0 (choose (reduce_sum (v1)) (reduce_mul (v1)) (reduce_max (v1)))]
[v1 (choose (v2) (v6))]
[v2 (choose (vec-slice-noerr input (v3) (v3) ) (vec-slice-noerr weight (v3) (v3) ))]
[v3 (choose (v4) (v5))]
[v4 (choose 0 (length input ) i)]
[v5 (choose (integer-sqrt-noerr (v4) ) (integer-exp-noerr (v4) ) (+ (v4) (v4) ) (- (v4) (v4) ) (* (v4) (v4) ) (quotient-noerr (v4) (v4) ))]
[v6 (choose (v7) (vec_elemwise_add (v2) (v2)) (vec_elemwise_sub (v2) (v2)) (vec_elemwise_mul (v2) (v2)) (vec_elemwise_div (v2) (v2)) (vec_scalar_add (v8) (v2)) (vec_scalar_sub (v8) (v2)) (vec_scalar_mul (v8) (v2)) (vec_scalar_div (v8) (v2)) (scalar_vec_sub (v8) (v2)) (scalar_vec_div (v8) (v2)))]
[v7 (choose (vec_map (v2) map_int_to_int))]
[v8 (choose 0 1)]
)

(define-grammar (rmsnorm_part1_ps_gram input weight rmsnorm_part1_rv)
 [rv (choose (equal? rmsnorm_part1_rv (v0) ))]
[v0 (choose (reduce_sum (v1)) (reduce_mul (v1)) (reduce_max (v1)))]
[v1 (choose (v2) (v6))]
[v2 (choose (vec-slice-noerr input (v3) (v3) ) (vec-slice-noerr weight (v3) (v3) ))]
[v3 (choose (v4) (v5))]
[v4 (choose 0 (length input ))]
[v5 (choose (integer-sqrt-noerr (v4) ) (integer-exp-noerr (v4) ) (+ (v4) (v4) ) (- (v4) (v4) ) (* (v4) (v4) ) (quotient-noerr (v4) (v4) ))]
[v6 (choose (v7) (vec_elemwise_add (v2) (v2)) (vec_elemwise_sub (v2) (v2)) (vec_elemwise_mul (v2) (v2)) (vec_elemwise_div (v2) (v2)) (vec_scalar_add (v8) (v2)) (vec_scalar_sub (v8) (v2)) (vec_scalar_mul (v8) (v2)) (vec_scalar_div (v8) (v2)) (scalar_vec_sub (v8) (v2)) (scalar_vec_div (v8) (v2)))]
[v7 (choose (vec_map (v2) map_int_to_int))]
[v8 (choose 0 1)]
)

(define-grammar (map_int_to_int_gram int_x)
 [rv (choose (v0))]
[v0 (choose (integer-exp-noerr int_x ) (integer-sqrt-noerr int_x ))]
)

(define (rmsnorm_part1_inv0 i input ss weight) (rmsnorm_part1_inv0_gram i input ss weight #:depth 10))
(define (rmsnorm_part1_ps input weight rmsnorm_part1_rv) (rmsnorm_part1_ps_gram input weight rmsnorm_part1_rv #:depth 10))

(define (map_int_to_int int_x) (map_int_to_int_gram int_x #:depth 10))

(define-symbolic i integer?)
(define-symbolic input_BOUNDEDSET-len integer?)
(define-symbolic input_BOUNDEDSET-0 integer?)
(define-symbolic input_BOUNDEDSET-1 integer?)
(define input (take (list input_BOUNDEDSET-0 input_BOUNDEDSET-1) input_BOUNDEDSET-len))
(define-symbolic rmsnorm_part1_rv integer?)
(define-symbolic ss integer?)
(define-symbolic weight_BOUNDEDSET-len integer?)
(define-symbolic weight_BOUNDEDSET-0 integer?)
(define-symbolic weight_BOUNDEDSET-1 integer?)
(define weight (take (list weight_BOUNDEDSET-0 weight_BOUNDEDSET-1) weight_BOUNDEDSET-len))
(current-bitwidth 6)
(define (assertions)
 (assert (&& (&& (=> (&& (equal? (length input ) (length weight ) ) (> (length input ) 0 ) ) (rmsnorm_part1_inv0 0 input 0 weight) ) (=> (&& (&& (&& (< i (length input ) ) (equal? (length input ) (length weight ) ) ) (> (length input ) 0 ) ) (rmsnorm_part1_inv0 i input ss weight) ) (rmsnorm_part1_inv0 (+ i 1 ) input (+ ss (* (list-ref-noerr input i ) (list-ref-noerr input i ) ) ) weight) ) ) (=> (&& (&& (&& (! (< i (length input ) ) ) (equal? (length input ) (length weight ) ) ) (> (length input ) 0 ) ) (rmsnorm_part1_inv0 i input ss weight) ) (rmsnorm_part1_ps input weight ss) ) )))


    (define sol0
        (synthesize
            #:forall (list i input_BOUNDEDSET-len input_BOUNDEDSET-0 input_BOUNDEDSET-1 rmsnorm_part1_rv ss weight_BOUNDEDSET-len weight_BOUNDEDSET-0 weight_BOUNDEDSET-1)
            #:guarantee (assertions)
        )
    )
    (sat? sol0)
    (print-forms sol0)
