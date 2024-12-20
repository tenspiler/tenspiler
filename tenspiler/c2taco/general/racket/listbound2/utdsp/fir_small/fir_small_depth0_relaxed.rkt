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

(define-grammar (fir_small_inv0_gram NTAPS coefficient i input sum)
 [rv (choose (&& (&& (>= i (v0) ) (<= i (v1) ) ) (equal? sum (v2) ) ))]
[v0 (choose 0 (- 0 1 ) (+ 0 1 ))]
[v1 (choose NTAPS (- NTAPS 1 ) (+ NTAPS 1 ))]
[v2 (choose (reduce_sum (v3)) (reduce_mul (v3)) (reduce_max (v3)))]
[v3 (choose (v4))]
[v4 (choose (vec-slice-noerr (v5) (v6) (v6) ))]
[v5 (choose input coefficient)]
[v6 (choose (v7))]
[v7 (choose (v8) (- (v8) 1 ) (+ (v8) 1 ))]
[v8 (choose 0 NTAPS i)]
)

(define-grammar (fir_small_ps_gram NTAPS input coefficient fir_small_rv)
 [rv (choose (equal? fir_small_rv (v0) ))]
[v0 (choose (reduce_sum (v1)) (reduce_mul (v1)) (reduce_max (v1)))]
[v1 (choose (v2))]
[v2 (choose (vec-slice-noerr (v3) (v4) (v4) ))]
[v3 (choose input coefficient)]
[v4 (choose (v5))]
[v5 (choose (v6) (- (v6) 1 ) (+ (v6) 1 ))]
[v6 (choose 0 NTAPS)]
)

(define-grammar (map_int_to_int_gram int_x)
 [rv (choose (v0))]
[v0 (choose (integer-exp-noerr int_x ) (integer-sqrt-noerr int_x ))]
)

(define (fir_small_inv0 NTAPS coefficient i input sum) (fir_small_inv0_gram NTAPS coefficient i input sum #:depth 10))
(define (fir_small_ps NTAPS input coefficient fir_small_rv) (fir_small_ps_gram NTAPS input coefficient fir_small_rv #:depth 10))

(define (map_int_to_int int_x) (map_int_to_int_gram int_x #:depth 10))

(define-symbolic NTAPS integer?)
(define-symbolic coefficient_BOUNDEDSET-len integer?)
(define-symbolic coefficient_BOUNDEDSET-0 integer?)
(define-symbolic coefficient_BOUNDEDSET-1 integer?)
(define coefficient (take (list coefficient_BOUNDEDSET-0 coefficient_BOUNDEDSET-1) coefficient_BOUNDEDSET-len))
(define-symbolic fir_small_rv integer?)
(define-symbolic i integer?)
(define-symbolic input_BOUNDEDSET-len integer?)
(define-symbolic input_BOUNDEDSET-0 integer?)
(define-symbolic input_BOUNDEDSET-1 integer?)
(define input (take (list input_BOUNDEDSET-0 input_BOUNDEDSET-1) input_BOUNDEDSET-len))
(define-symbolic sum integer?)
(current-bitwidth 6)
(define (assertions)
 (assert (&& (&& (=> (&& (&& (>= NTAPS 1 ) (>= (length input ) NTAPS ) ) (>= (length coefficient ) NTAPS ) ) (fir_small_inv0 NTAPS coefficient 0 input 0) ) (=> (&& (&& (&& (&& (< i NTAPS ) (>= NTAPS 1 ) ) (>= (length input ) NTAPS ) ) (>= (length coefficient ) NTAPS ) ) (fir_small_inv0 NTAPS coefficient i input sum) ) (fir_small_inv0 NTAPS coefficient (+ i 1 ) input (+ sum (* (list-ref-noerr input i ) (list-ref-noerr coefficient i ) ) )) ) ) (=> (&& (&& (&& (&& (! (< i NTAPS ) ) (>= NTAPS 1 ) ) (>= (length input ) NTAPS ) ) (>= (length coefficient ) NTAPS ) ) (fir_small_inv0 NTAPS coefficient i input sum) ) (fir_small_ps NTAPS input coefficient sum) ) )))


    (define sol0
        (synthesize
            #:forall (list NTAPS coefficient_BOUNDEDSET-len coefficient_BOUNDEDSET-0 coefficient_BOUNDEDSET-1 fir_small_rv i input_BOUNDEDSET-len input_BOUNDEDSET-0 input_BOUNDEDSET-1 sum)
            #:guarantee (assertions)
        )
    )
    (sat? sol0)
    (print-forms sol0)
