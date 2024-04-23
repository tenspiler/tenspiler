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

(define-grammar (len_inv0_gram arr i l n)
 [rv (choose (&& (&& (>= i 0 ) (<= i n ) ) (equal? l (v0) ) ))]
[v0 (choose (reduce_sum (v1)) (reduce_mul (v1)) (reduce_max (v1)))]
[v1 (choose (vec-slice-noerr arr (v2) (v2) ) (v5))]
[v2 (choose (v3) (v4))]
[v3 (choose 0 n i)]
[v4 (choose (integer-sqrt-noerr (v3) ) (integer-exp-noerr (v3) ) (+ (v3) (v3) ) (- (v3) (v3) ) (* (v3) (v3) ) (quotient-noerr (v3) (v3) ))]
[v5 (choose (v6) (vec_elemwise_add (vec-slice-noerr arr (v2) (v2) ) (vec-slice-noerr arr (v2) (v2) ) ) (vec_elemwise_sub (vec-slice-noerr arr (v2) (v2) ) (vec-slice-noerr arr (v2) (v2) ) ) (vec_elemwise_mul (vec-slice-noerr arr (v2) (v2) ) (vec-slice-noerr arr (v2) (v2) ) ) (vec_elemwise_div (vec-slice-noerr arr (v2) (v2) ) (vec-slice-noerr arr (v2) (v2) ) ) (vec_scalar_add (v3) (vec-slice-noerr arr (v2) (v2) ) ) (vec_scalar_sub (v3) (vec-slice-noerr arr (v2) (v2) ) ) (vec_scalar_mul (v3) (vec-slice-noerr arr (v2) (v2) ) ) (vec_scalar_div (v3) (vec-slice-noerr arr (v2) (v2) ) ) (scalar_vec_sub (v3) (vec-slice-noerr arr (v2) (v2) )) (scalar_vec_div (v3) (vec-slice-noerr arr (v2) (v2) )))]
[v6 (choose (vec_map (vec-slice-noerr arr (v2) (v2) ) map_int_to_int ))]
)

(define-grammar (len_ps_gram arr n len_rv)
 [rv (choose (equal? len_rv (v0) ))]
[v0 (choose (reduce_sum (v1)) (reduce_mul (v1)) (reduce_max (v1)))]
[v1 (choose (vec-slice-noerr arr (v2) (v2) ) (v5))]
[v2 (choose (v3) (v4))]
[v3 (choose 0 n)]
[v4 (choose (integer-sqrt-noerr (v3) ) (integer-exp-noerr (v3) ) (+ (v3) (v3) ) (- (v3) (v3) ) (* (v3) (v3) ) (quotient-noerr (v3) (v3) ))]
[v5 (choose (v6) (vec_elemwise_add (vec-slice-noerr arr (v2) (v2) ) (vec-slice-noerr arr (v2) (v2) ) ) (vec_elemwise_sub (vec-slice-noerr arr (v2) (v2) ) (vec-slice-noerr arr (v2) (v2) ) ) (vec_elemwise_mul (vec-slice-noerr arr (v2) (v2) ) (vec-slice-noerr arr (v2) (v2) ) ) (vec_elemwise_div (vec-slice-noerr arr (v2) (v2) ) (vec-slice-noerr arr (v2) (v2) ) ) (vec_scalar_add (v3) (vec-slice-noerr arr (v2) (v2) ) ) (vec_scalar_sub (v3) (vec-slice-noerr arr (v2) (v2) ) ) (vec_scalar_mul (v3) (vec-slice-noerr arr (v2) (v2) ) ) (vec_scalar_div (v3) (vec-slice-noerr arr (v2) (v2) ) ) (scalar_vec_sub (v3) (vec-slice-noerr arr (v2) (v2) )) (scalar_vec_div (v3) (vec-slice-noerr arr (v2) (v2) )))]
[v6 (choose (vec_map (vec-slice-noerr arr (v2) (v2) ) map_int_to_int ))]
)

(define-grammar (map_int_to_int_gram int_x)
 [rv (choose (v0))]
[v0 (choose (integer-exp-noerr int_x ) (integer-sqrt-noerr int_x ))]
)

(define (len_inv0 arr i l n) (len_inv0_gram arr i l n #:depth 10))
(define (len_ps arr n len_rv) (len_ps_gram arr n len_rv #:depth 10))

(define (map_int_to_int int_x) (map_int_to_int_gram int_x #:depth 10))

(define-symbolic arr_BOUNDEDSET-len integer?)
(define-symbolic arr_BOUNDEDSET-0 integer?)
(define-symbolic arr_BOUNDEDSET-1 integer?)
(define arr (take (list arr_BOUNDEDSET-0 arr_BOUNDEDSET-1) arr_BOUNDEDSET-len))
(define-symbolic i integer?)
(define-symbolic l integer?)
(define-symbolic len_rv integer?)
(define-symbolic n integer?)
(current-bitwidth 6)
(define (assertions)
 (assert (&& (&& (=> (&& (&& (>= n 1 ) (> (length arr ) 0 ) ) (>= (length arr ) n ) ) (len_inv0 arr 0 0 n) ) (=> (&& (&& (&& (&& (< i n ) (>= n 1 ) ) (> (length arr ) 0 ) ) (>= (length arr ) n ) ) (len_inv0 arr i l n) ) (len_inv0 arr (+ i 1 ) (+ l (* (list-ref-noerr arr i ) (list-ref-noerr arr i ) ) ) n) ) ) (=> (&& (&& (&& (&& (! (< i n ) ) (>= n 1 ) ) (> (length arr ) 0 ) ) (>= (length arr ) n ) ) (len_inv0 arr i l n) ) (len_ps arr n l) ) )))


    (define sol0
        (synthesize
            #:forall (list arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i l len_rv n)
            #:guarantee (assertions)
        )
    )
    (sat? sol0)
    (print-forms sol0)


        (define sol1
            (synthesize
                #:forall (list arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i l len_rv n)
                #:guarantee (begin
                    (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol0))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol0)))))
                    (assertions)
                )
            )
        )
        (sat? sol1)
        (print-forms sol1)


        (define sol2
            (synthesize
                #:forall (list arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i l len_rv n)
                #:guarantee (begin
                    (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol0))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol0))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol1))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol1)))))
                    (assertions)
                )
            )
        )
        (sat? sol2)
        (print-forms sol2)


        (define sol3
            (synthesize
                #:forall (list arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i l len_rv n)
                #:guarantee (begin
                    (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol0))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol0))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol1))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol1))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol2))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol2)))))
                    (assertions)
                )
            )
        )
        (sat? sol3)
        (print-forms sol3)


        (define sol4
            (synthesize
                #:forall (list arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i l len_rv n)
                #:guarantee (begin
                    (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol0))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol0))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol1))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol1))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol2))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol2))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol3))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol3)))))
                    (assertions)
                )
            )
        )
        (sat? sol4)
        (print-forms sol4)


        (define sol5
            (synthesize
                #:forall (list arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i l len_rv n)
                #:guarantee (begin
                    (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol0))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol0))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol1))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol1))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol2))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol2))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol3))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol3))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol4))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol4)))))
                    (assertions)
                )
            )
        )
        (sat? sol5)
        (print-forms sol5)


        (define sol6
            (synthesize
                #:forall (list arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i l len_rv n)
                #:guarantee (begin
                    (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol0))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol0))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol1))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol1))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol2))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol2))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol3))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol3))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol4))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol4))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol5))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol5)))))
                    (assertions)
                )
            )
        )
        (sat? sol6)
        (print-forms sol6)


        (define sol7
            (synthesize
                #:forall (list arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i l len_rv n)
                #:guarantee (begin
                    (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol0))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol0))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol1))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol1))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol2))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol2))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol3))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol3))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol4))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol4))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol5))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol5))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol6))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol6)))))
                    (assertions)
                )
            )
        )
        (sat? sol7)
        (print-forms sol7)


        (define sol8
            (synthesize
                #:forall (list arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i l len_rv n)
                #:guarantee (begin
                    (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol0))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol0))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol1))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol1))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol2))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol2))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol3))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol3))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol4))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol4))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol5))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol5))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol6))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol6))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol7))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol7)))))
                    (assertions)
                )
            )
        )
        (sat? sol8)
        (print-forms sol8)


        (define sol9
            (synthesize
                #:forall (list arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i l len_rv n)
                #:guarantee (begin
                    (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol0))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol0))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol1))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol1))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol2))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol2))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol3))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol3))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol4))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol4))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol5))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol5))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol6))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol6))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol7))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol7))))) (assume (|| (! (eq? (len_inv0 arr i l n) (evaluate (len_inv0 arr i l n) sol8))) (! (eq? (len_ps arr n len_rv) (evaluate (len_ps arr n len_rv) sol8)))))
                    (assertions)
                )
            )
        )
        (sat? sol9)
        (print-forms sol9)