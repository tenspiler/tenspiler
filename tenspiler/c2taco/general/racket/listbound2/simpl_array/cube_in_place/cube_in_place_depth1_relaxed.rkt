#lang rosette
(require "./bounded.rkt")
(require "./utils.rkt")
(require rosette/lib/angelic rosette/lib/match rosette/lib/synthax)
(require rosette/solver/smt/bitwuzla)
(current-solver (bitwuzla #:path "/Users/sahilbhatia/Documents/bitwuzla/build/src/main/bitwuzla" #:options (hash ':seed 0)))


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


 (define-bounded (reduce_max x)
(if (<= (length x ) 1 ) (list-ref-noerr x 0 ) (if (> (list-ref-noerr x 0 ) (reduce_max (list-tail-noerr x 1 )) ) (list-ref-noerr x 0 ) (reduce_max (list-tail-noerr x 1 )) ) ))


 (define-bounded (reduce_sum x)
(if (< (length x ) 1 ) 0 (+ (list-ref-noerr x 0 ) (reduce_sum (list-tail-noerr x 1 )) ) ))


 (define-bounded (reduce_mul x)
(if (< (length x ) 1 ) 1 (* (list-ref-noerr x 0 ) (reduce_mul (list-tail-noerr x 1 )) ) ))

(define-grammar (cube_in_place_inv0_gram agg.result arr i n ref.tmp)
 [rv (choose (&& (&& (>= i (v0) ) (<= i (v1) ) ) (equal? agg.result (v2) ) ))]
[v0 (choose 0 (- 0 1 ) (+ 0 1 ))]
[v1 (choose n (- n 1 ) (+ n 1 ))]
[v2 (choose (vec-slice-noerr (v3) (v4) (v4) ) (v8))]
[v3 (choose arr)]
[v4 (choose (v5) (v7))]
[v5 (choose (v6) (- (v6) 1 ) (+ (v6) 1 ))]
[v6 (choose 0 n i)]
[v7 (choose (integer-sqrt-noerr (v5) ) (integer-exp-noerr (v5) ) (+ (v5) (v5) ) (- (v5) (v5) ) (* (v5) (v5) ) (quotient-noerr (v5) (v5) ))]
[v8 (choose (v9) (vec_elemwise_add (vec-slice-noerr (v3) (v4) (v4) ) (vec-slice-noerr (v3) (v4) (v4) ) ) (vec_elemwise_sub (vec-slice-noerr (v3) (v4) (v4) ) (vec-slice-noerr (v3) (v4) (v4) ) ) (vec_elemwise_mul (vec-slice-noerr (v3) (v4) (v4) ) (vec-slice-noerr (v3) (v4) (v4) ) ) (vec_elemwise_div (vec-slice-noerr (v3) (v4) (v4) ) (vec-slice-noerr (v3) (v4) (v4) ) ) (vec_scalar_add (v5) (vec-slice-noerr (v3) (v4) (v4) ) ) (vec_scalar_sub (v5) (vec-slice-noerr (v3) (v4) (v4) ) ) (vec_scalar_mul (v5) (vec-slice-noerr (v3) (v4) (v4) ) ) (vec_scalar_div (v5) (vec-slice-noerr (v3) (v4) (v4) ) ) (scalar_vec_sub (v5) (vec-slice-noerr (v3) (v4) (v4) )) (scalar_vec_div (v5) (vec-slice-noerr (v3) (v4) (v4) )))]
[v9 (choose (vec_map (vec-slice-noerr (v3) (v4) (v4) ) map_int_to_int ))]
)

(define-grammar (cube_in_place_ps_gram arr n cube_in_place_rv)
 [rv (choose (equal? cube_in_place_rv (v0) ))]
[v0 (choose (vec-slice-noerr (v1) (v2) (v2) ) (v6))]
[v1 (choose arr)]
[v2 (choose (v3) (v5))]
[v3 (choose (v4) (- (v4) 1 ) (+ (v4) 1 ))]
[v4 (choose 0 n)]
[v5 (choose (integer-sqrt-noerr (v3) ) (integer-exp-noerr (v3) ) (+ (v3) (v3) ) (- (v3) (v3) ) (* (v3) (v3) ) (quotient-noerr (v3) (v3) ))]
[v6 (choose (v7) (vec_elemwise_add (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_elemwise_sub (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_elemwise_mul (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_elemwise_div (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_add (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_sub (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_mul (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_div (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (scalar_vec_sub (v3) (vec-slice-noerr (v1) (v2) (v2) )) (scalar_vec_div (v3) (vec-slice-noerr (v1) (v2) (v2) )))]
[v7 (choose (vec_map (vec-slice-noerr (v1) (v2) (v2) ) map_int_to_int ))]
)

(define-grammar (map_int_to_int_gram int_x)
 [rv (choose (v0))]
[v0 (choose (integer-exp-noerr int_x ) (integer-sqrt-noerr int_x ))]
)

(define (cube_in_place_inv0 agg.result arr i n ref.tmp) (cube_in_place_inv0_gram agg.result arr i n ref.tmp #:depth 10))
(define (cube_in_place_ps arr n cube_in_place_rv) (cube_in_place_ps_gram arr n cube_in_place_rv #:depth 10))

(define (map_int_to_int int_x) (map_int_to_int_gram int_x #:depth 10))

(define-symbolic agg.result_BOUNDEDSET-len integer?)
(define-symbolic agg.result_BOUNDEDSET-0 integer?)
(define-symbolic agg.result_BOUNDEDSET-1 integer?)
(define agg.result (take (list agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1) agg.result_BOUNDEDSET-len))
(define-symbolic arr_BOUNDEDSET-len integer?)
(define-symbolic arr_BOUNDEDSET-0 integer?)
(define-symbolic arr_BOUNDEDSET-1 integer?)
(define arr (take (list arr_BOUNDEDSET-0 arr_BOUNDEDSET-1) arr_BOUNDEDSET-len))
(define-symbolic cube_in_place_rv_BOUNDEDSET-len integer?)
(define-symbolic cube_in_place_rv_BOUNDEDSET-0 integer?)
(define-symbolic cube_in_place_rv_BOUNDEDSET-1 integer?)
(define cube_in_place_rv (take (list cube_in_place_rv_BOUNDEDSET-0 cube_in_place_rv_BOUNDEDSET-1) cube_in_place_rv_BOUNDEDSET-len))
(define-symbolic i integer?)
(define-symbolic n integer?)
(define-symbolic ref.tmp integer?)
(current-bitwidth 6)
(define (assertions)
 (assert (&& (&& (=> (&& (>= n 1 ) (>= (length arr ) n ) ) (cube_in_place_inv0 (list-empty ) arr 0 n 0) ) (=> (&& (&& (&& (< i n ) (>= n 1 ) ) (>= (length arr ) n ) ) (cube_in_place_inv0 agg.result arr i n ref.tmp) ) (cube_in_place_inv0 (list-append agg.result (* (* (list-ref-noerr arr i ) (list-ref-noerr arr i ) ) (list-ref-noerr arr i ) ) ) arr (+ i 1 ) n (* (* (list-ref-noerr arr i ) (list-ref-noerr arr i ) ) (list-ref-noerr arr i ) )) ) ) (=> (or (&& (&& (&& (! (< i n ) ) (>= n 1 ) ) (>= (length arr ) n ) ) (cube_in_place_inv0 agg.result arr i n ref.tmp) ) (&& (&& (&& (&& (! true ) (! (< i n ) ) ) (>= n 1 ) ) (>= (length arr ) n ) ) (cube_in_place_inv0 agg.result arr i n ref.tmp) ) ) (cube_in_place_ps arr n agg.result) ) )))


    (define sol0
        (synthesize
            #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 cube_in_place_rv_BOUNDEDSET-len cube_in_place_rv_BOUNDEDSET-0 cube_in_place_rv_BOUNDEDSET-1 i n ref.tmp)
            #:guarantee (assertions)
        )
    )
    (sat? sol0)
    (print-forms sol0)