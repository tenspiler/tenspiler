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


 (define-bounded (reduce_max x)
(if (<= (length x ) 1 ) (list-ref-noerr x 0 ) (if (> (list-ref-noerr x 0 ) (reduce_max (list-tail-noerr x 1 )) ) (list-ref-noerr x 0 ) (reduce_max (list-tail-noerr x 1 )) ) ))


 (define-bounded (reduce_sum x)
(if (< (length x ) 1 ) 0 (+ (list-ref-noerr x 0 ) (reduce_sum (list-tail-noerr x 1 )) ) ))


 (define-bounded (reduce_mul x)
(if (< (length x ) 1 ) 1 (* (list-ref-noerr x 0 ) (reduce_mul (list-tail-noerr x 1 )) ) ))


 (define-bounded (vec_map x map_int_to_int)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (map_int_to_int (list-ref-noerr x 0 )) (vec_map (list-tail-noerr x 1 ) map_int_to_int ) ) ))


 (define (vec_slice lst start end)
(list-tail-noerr (list-take-noerr lst end ) start ))

(define-grammar (lmsfir2_inv0_gram NTAPS agg.result coefficient curr error i input)
 [rv (choose (&& (&& (>= i (v0) ) (<= i (v1) ) ) (equal? agg.result (v2) ) ))]
[v0 (choose 0 (- 0 1 ) (+ 0 1 ))]
[v1 (choose (- NTAPS 1 ) (- (- NTAPS 1 ) 1 ) (+ (- NTAPS 1 ) 1 ))]
[v2 (choose (v3) (v9))]
[v3 (choose (vec-slice-noerr (v4) (v5) (v5) ))]
[v4 (choose input coefficient)]
[v5 (choose (v6) (v8))]
[v6 (choose (v7) (- (v7) 1 ) (+ (v7) 1 ))]
[v7 (choose 0 (- NTAPS 1 ) i error)]
[v8 (choose (integer-sqrt-noerr (v6) ) (integer-exp-noerr (v6) ) (+ (v6) (v6) ) (- (v6) (v6) ) (* (v6) (v6) ) (quotient-noerr (v6) (v6) ))]
[v9 (choose (v10) (vec_elemwise_add (v3) (v3) ) (vec_elemwise_sub (v3) (v3) ) (vec_elemwise_mul (v3) (v3) ) (vec_elemwise_div (v3) (v3) ) (vec_scalar_add (v6) (v3) ) (vec_scalar_sub (v6) (v3) ) (vec_scalar_mul (v6) (v3) ) (vec_scalar_div (v6) (v3) ) (scalar_vec_sub (v6) (v3)) (scalar_vec_div (v6) (v3)))]
[v10 (choose (vec_map (v3) map_int_to_int ))]
)

(define-grammar (lmsfir2_ps_gram NTAPS input coefficient error lmsfir2_rv)
 [rv (choose (equal? lmsfir2_rv (v0) ))]
[v0 (choose (v1) (v7))]
[v1 (choose (vec-slice-noerr (v2) (v3) (v3) ))]
[v2 (choose input coefficient)]
[v3 (choose (v4) (v6))]
[v4 (choose (v5) (- (v5) 1 ) (+ (v5) 1 ))]
[v5 (choose 0 (- NTAPS 1 ) error)]
[v6 (choose (integer-sqrt-noerr (v4) ) (integer-exp-noerr (v4) ) (+ (v4) (v4) ) (- (v4) (v4) ) (* (v4) (v4) ) (quotient-noerr (v4) (v4) ))]
[v7 (choose (v8) (vec_elemwise_add (v1) (v1) ) (vec_elemwise_sub (v1) (v1) ) (vec_elemwise_mul (v1) (v1) ) (vec_elemwise_div (v1) (v1) ) (vec_scalar_add (v4) (v1) ) (vec_scalar_sub (v4) (v1) ) (vec_scalar_mul (v4) (v1) ) (vec_scalar_div (v4) (v1) ) (scalar_vec_sub (v4) (v1)) (scalar_vec_div (v4) (v1)))]
[v8 (choose (vec_map (v1) map_int_to_int ))]
)

(define-grammar (map_int_to_int_gram int_x)
 [rv (choose (v0))]
[v0 (choose (integer-exp-noerr int_x ) (integer-sqrt-noerr int_x ))]
)

(define (lmsfir2_inv0 NTAPS agg.result coefficient curr error i input) (lmsfir2_inv0_gram NTAPS agg.result coefficient curr error i input #:depth 10))
(define (lmsfir2_ps NTAPS input coefficient error lmsfir2_rv) (lmsfir2_ps_gram NTAPS input coefficient error lmsfir2_rv #:depth 10))

(define (map_int_to_int int_x) (map_int_to_int_gram int_x #:depth 10))

(define-symbolic NTAPS integer?)
(define-symbolic agg.result_BOUNDEDSET-len integer?)
(define-symbolic agg.result_BOUNDEDSET-0 integer?)
(define-symbolic agg.result_BOUNDEDSET-1 integer?)
(define agg.result (take (list agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1) agg.result_BOUNDEDSET-len))
(define-symbolic coefficient_BOUNDEDSET-len integer?)
(define-symbolic coefficient_BOUNDEDSET-0 integer?)
(define-symbolic coefficient_BOUNDEDSET-1 integer?)
(define coefficient (take (list coefficient_BOUNDEDSET-0 coefficient_BOUNDEDSET-1) coefficient_BOUNDEDSET-len))
(define-symbolic curr integer?)
(define-symbolic error integer?)
(define-symbolic i integer?)
(define-symbolic input_BOUNDEDSET-len integer?)
(define-symbolic input_BOUNDEDSET-0 integer?)
(define-symbolic input_BOUNDEDSET-1 integer?)
(define input (take (list input_BOUNDEDSET-0 input_BOUNDEDSET-1) input_BOUNDEDSET-len))
(define-symbolic lmsfir2_rv_BOUNDEDSET-len integer?)
(define-symbolic lmsfir2_rv_BOUNDEDSET-0 integer?)
(define-symbolic lmsfir2_rv_BOUNDEDSET-1 integer?)
(define lmsfir2_rv (take (list lmsfir2_rv_BOUNDEDSET-0 lmsfir2_rv_BOUNDEDSET-1) lmsfir2_rv_BOUNDEDSET-len))
(current-bitwidth 6)
(define (assertions)
 (assert (&& (&& (=> (&& (&& (>= NTAPS 1 ) (>= (length input ) NTAPS ) ) (>= (length coefficient ) NTAPS ) ) (lmsfir2_inv0 NTAPS (list-empty ) coefficient 0 error 0 input) ) (=> (&& (&& (&& (&& (< i (- NTAPS 1 ) ) (>= NTAPS 1 ) ) (>= (length input ) NTAPS ) ) (>= (length coefficient ) NTAPS ) ) (lmsfir2_inv0 NTAPS agg.result coefficient curr error i input) ) (lmsfir2_inv0 NTAPS (list-append agg.result (+ (list-ref-noerr coefficient i ) (* (list-ref-noerr input i ) error ) ) ) coefficient (+ (list-ref-noerr coefficient i ) (* (list-ref-noerr input i ) error ) ) error (+ i 1 ) input) ) ) (=> (or (&& (&& (&& (&& (! (< i (- NTAPS 1 ) ) ) (>= NTAPS 1 ) ) (>= (length input ) NTAPS ) ) (>= (length coefficient ) NTAPS ) ) (lmsfir2_inv0 NTAPS agg.result coefficient curr error i input) ) (&& (&& (&& (&& (&& (! true ) (! (< i (- NTAPS 1 ) ) ) ) (>= NTAPS 1 ) ) (>= (length input ) NTAPS ) ) (>= (length coefficient ) NTAPS ) ) (lmsfir2_inv0 NTAPS agg.result coefficient curr error i input) ) ) (lmsfir2_ps NTAPS input coefficient error agg.result) ) )))


    (define sol0
        (synthesize
            #:forall (list NTAPS agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 coefficient_BOUNDEDSET-len coefficient_BOUNDEDSET-0 coefficient_BOUNDEDSET-1 curr error i input_BOUNDEDSET-len input_BOUNDEDSET-0 input_BOUNDEDSET-1 lmsfir2_rv_BOUNDEDSET-len lmsfir2_rv_BOUNDEDSET-0 lmsfir2_rv_BOUNDEDSET-1)
            #:guarantee (assertions)
        )
    )
    (sat? sol0)
    (print-forms sol0)
