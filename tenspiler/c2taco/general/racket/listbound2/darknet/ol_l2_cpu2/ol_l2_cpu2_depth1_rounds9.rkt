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


 (define-bounded (reduce_max x)
(if (<= (length x ) 1 ) (list-ref-noerr x 0 ) (if (> (list-ref-noerr x 0 ) (reduce_max (list-tail-noerr x 1 )) ) (list-ref-noerr x 0 ) (reduce_max (list-tail-noerr x 1 )) ) ))


 (define-bounded (reduce_sum x)
(if (< (length x ) 1 ) 0 (+ (list-ref-noerr x 0 ) (reduce_sum (list-tail-noerr x 1 )) ) ))


 (define-bounded (reduce_mul x)
(if (< (length x ) 1 ) 1 (* (list-ref-noerr x 0 ) (reduce_mul (list-tail-noerr x 1 )) ) ))

(define-grammar (ol_l2_cpu2_inv0_gram agg.result diff i n pred truth)
 [rv (choose (&& (&& (>= i 0 ) (<= i n ) ) (equal? agg.result (v0) ) ))]
[v0 (choose (vec-slice-noerr (v1) (v2) (v2) ) (v5))]
[v1 (choose pred truth)]
[v2 (choose (v3) (v4))]
[v3 (choose 0 n i)]
[v4 (choose (integer-sqrt-noerr (v3) ) (integer-exp-noerr (v3) ) (+ (v3) (v3) ) (- (v3) (v3) ) (* (v3) (v3) ) (quotient-noerr (v3) (v3) ))]
[v5 (choose (v6) (vec_elemwise_add (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_elemwise_sub (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_elemwise_mul (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_elemwise_div (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_add (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_sub (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_mul (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_div (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (scalar_vec_sub (v3) (vec-slice-noerr (v1) (v2) (v2) )) (scalar_vec_div (v3) (vec-slice-noerr (v1) (v2) (v2) )))]
[v6 (choose (vec_map (vec-slice-noerr (v1) (v2) (v2) ) map_int_to_int ))]
)

(define-grammar (ol_l2_cpu2_ps_gram n pred truth ol_l2_cpu2_rv)
 [rv (choose (equal? ol_l2_cpu2_rv (v0) ))]
[v0 (choose (vec-slice-noerr (v1) (v2) (v2) ) (v5))]
[v1 (choose pred truth)]
[v2 (choose (v3) (v4))]
[v3 (choose 0 n)]
[v4 (choose (integer-sqrt-noerr (v3) ) (integer-exp-noerr (v3) ) (+ (v3) (v3) ) (- (v3) (v3) ) (* (v3) (v3) ) (quotient-noerr (v3) (v3) ))]
[v5 (choose (v6) (vec_elemwise_add (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_elemwise_sub (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_elemwise_mul (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_elemwise_div (vec-slice-noerr (v1) (v2) (v2) ) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_add (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_sub (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_mul (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (vec_scalar_div (v3) (vec-slice-noerr (v1) (v2) (v2) ) ) (scalar_vec_sub (v3) (vec-slice-noerr (v1) (v2) (v2) )) (scalar_vec_div (v3) (vec-slice-noerr (v1) (v2) (v2) )))]
[v6 (choose (vec_map (vec-slice-noerr (v1) (v2) (v2) ) map_int_to_int ))]
)

(define-grammar (map_int_to_int_gram int_x)
 [rv (choose (v0))]
[v0 (choose (integer-exp-noerr int_x ) (integer-sqrt-noerr int_x ))]
)

(define (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (ol_l2_cpu2_inv0_gram agg.result diff i n pred truth #:depth 10))
(define (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (ol_l2_cpu2_ps_gram n pred truth ol_l2_cpu2_rv #:depth 10))

(define (map_int_to_int int_x) (map_int_to_int_gram int_x #:depth 10))

(define-symbolic agg.result_BOUNDEDSET-len integer?)
(define-symbolic agg.result_BOUNDEDSET-0 integer?)
(define-symbolic agg.result_BOUNDEDSET-1 integer?)
(define agg.result (take (list agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1) agg.result_BOUNDEDSET-len))
(define-symbolic diff integer?)
(define-symbolic i integer?)
(define-symbolic n integer?)
(define-symbolic ol_l2_cpu2_rv_BOUNDEDSET-len integer?)
(define-symbolic ol_l2_cpu2_rv_BOUNDEDSET-0 integer?)
(define-symbolic ol_l2_cpu2_rv_BOUNDEDSET-1 integer?)
(define ol_l2_cpu2_rv (take (list ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1) ol_l2_cpu2_rv_BOUNDEDSET-len))
(define-symbolic pred_BOUNDEDSET-len integer?)
(define-symbolic pred_BOUNDEDSET-0 integer?)
(define-symbolic pred_BOUNDEDSET-1 integer?)
(define pred (take (list pred_BOUNDEDSET-0 pred_BOUNDEDSET-1) pred_BOUNDEDSET-len))
(define-symbolic truth_BOUNDEDSET-len integer?)
(define-symbolic truth_BOUNDEDSET-0 integer?)
(define-symbolic truth_BOUNDEDSET-1 integer?)
(define truth (take (list truth_BOUNDEDSET-0 truth_BOUNDEDSET-1) truth_BOUNDEDSET-len))
(current-bitwidth 6)
(define (assertions)
 (assert (&& (&& (=> (&& (&& (>= n 1 ) (>= (length pred ) n ) ) (>= (length truth ) n ) ) (ol_l2_cpu2_inv0 (list-empty ) 0 0 n pred truth) ) (=> (&& (&& (&& (&& (< i n ) (>= n 1 ) ) (>= (length pred ) n ) ) (>= (length truth ) n ) ) (ol_l2_cpu2_inv0 agg.result diff i n pred truth) ) (ol_l2_cpu2_inv0 (list-append agg.result (- (list-ref-noerr truth i ) (list-ref-noerr pred i ) ) ) (- (list-ref-noerr truth i ) (list-ref-noerr pred i ) ) (+ i 1 ) n pred truth) ) ) (=> (or (&& (&& (&& (&& (! (< i n ) ) (>= n 1 ) ) (>= (length pred ) n ) ) (>= (length truth ) n ) ) (ol_l2_cpu2_inv0 agg.result diff i n pred truth) ) (&& (&& (&& (&& (&& (! true ) (! (< i n ) ) ) (>= n 1 ) ) (>= (length pred ) n ) ) (>= (length truth ) n ) ) (ol_l2_cpu2_inv0 agg.result diff i n pred truth) ) ) (ol_l2_cpu2_ps n pred truth agg.result) ) )))


    (define sol0
        (synthesize
            #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 diff i n ol_l2_cpu2_rv_BOUNDEDSET-len ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1 pred_BOUNDEDSET-len pred_BOUNDEDSET-0 pred_BOUNDEDSET-1 truth_BOUNDEDSET-len truth_BOUNDEDSET-0 truth_BOUNDEDSET-1)
            #:guarantee (assertions)
        )
    )
    (sat? sol0)
    (print-forms sol0)


        (define sol1
            (synthesize
                #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 diff i n ol_l2_cpu2_rv_BOUNDEDSET-len ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1 pred_BOUNDEDSET-len pred_BOUNDEDSET-0 pred_BOUNDEDSET-1 truth_BOUNDEDSET-len truth_BOUNDEDSET-0 truth_BOUNDEDSET-1)
                #:guarantee (begin
                    (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol0))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol0)))))
                    (assertions)
                )
            )
        )
        (sat? sol1)
        (print-forms sol1)


        (define sol2
            (synthesize
                #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 diff i n ol_l2_cpu2_rv_BOUNDEDSET-len ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1 pred_BOUNDEDSET-len pred_BOUNDEDSET-0 pred_BOUNDEDSET-1 truth_BOUNDEDSET-len truth_BOUNDEDSET-0 truth_BOUNDEDSET-1)
                #:guarantee (begin
                    (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol0))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol0))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol1))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol1)))))
                    (assertions)
                )
            )
        )
        (sat? sol2)
        (print-forms sol2)


        (define sol3
            (synthesize
                #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 diff i n ol_l2_cpu2_rv_BOUNDEDSET-len ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1 pred_BOUNDEDSET-len pred_BOUNDEDSET-0 pred_BOUNDEDSET-1 truth_BOUNDEDSET-len truth_BOUNDEDSET-0 truth_BOUNDEDSET-1)
                #:guarantee (begin
                    (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol0))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol0))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol1))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol1))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol2))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol2)))))
                    (assertions)
                )
            )
        )
        (sat? sol3)
        (print-forms sol3)


        (define sol4
            (synthesize
                #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 diff i n ol_l2_cpu2_rv_BOUNDEDSET-len ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1 pred_BOUNDEDSET-len pred_BOUNDEDSET-0 pred_BOUNDEDSET-1 truth_BOUNDEDSET-len truth_BOUNDEDSET-0 truth_BOUNDEDSET-1)
                #:guarantee (begin
                    (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol0))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol0))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol1))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol1))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol2))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol2))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol3))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol3)))))
                    (assertions)
                )
            )
        )
        (sat? sol4)
        (print-forms sol4)


        (define sol5
            (synthesize
                #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 diff i n ol_l2_cpu2_rv_BOUNDEDSET-len ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1 pred_BOUNDEDSET-len pred_BOUNDEDSET-0 pred_BOUNDEDSET-1 truth_BOUNDEDSET-len truth_BOUNDEDSET-0 truth_BOUNDEDSET-1)
                #:guarantee (begin
                    (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol0))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol0))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol1))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol1))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol2))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol2))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol3))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol3))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol4))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol4)))))
                    (assertions)
                )
            )
        )
        (sat? sol5)
        (print-forms sol5)


        (define sol6
            (synthesize
                #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 diff i n ol_l2_cpu2_rv_BOUNDEDSET-len ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1 pred_BOUNDEDSET-len pred_BOUNDEDSET-0 pred_BOUNDEDSET-1 truth_BOUNDEDSET-len truth_BOUNDEDSET-0 truth_BOUNDEDSET-1)
                #:guarantee (begin
                    (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol0))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol0))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol1))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol1))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol2))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol2))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol3))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol3))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol4))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol4))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol5))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol5)))))
                    (assertions)
                )
            )
        )
        (sat? sol6)
        (print-forms sol6)


        (define sol7
            (synthesize
                #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 diff i n ol_l2_cpu2_rv_BOUNDEDSET-len ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1 pred_BOUNDEDSET-len pred_BOUNDEDSET-0 pred_BOUNDEDSET-1 truth_BOUNDEDSET-len truth_BOUNDEDSET-0 truth_BOUNDEDSET-1)
                #:guarantee (begin
                    (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol0))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol0))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol1))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol1))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol2))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol2))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol3))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol3))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol4))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol4))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol5))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol5))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol6))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol6)))))
                    (assertions)
                )
            )
        )
        (sat? sol7)
        (print-forms sol7)


        (define sol8
            (synthesize
                #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 diff i n ol_l2_cpu2_rv_BOUNDEDSET-len ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1 pred_BOUNDEDSET-len pred_BOUNDEDSET-0 pred_BOUNDEDSET-1 truth_BOUNDEDSET-len truth_BOUNDEDSET-0 truth_BOUNDEDSET-1)
                #:guarantee (begin
                    (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol0))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol0))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol1))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol1))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol2))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol2))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol3))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol3))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol4))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol4))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol5))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol5))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol6))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol6))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol7))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol7)))))
                    (assertions)
                )
            )
        )
        (sat? sol8)
        (print-forms sol8)


        (define sol9
            (synthesize
                #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 diff i n ol_l2_cpu2_rv_BOUNDEDSET-len ol_l2_cpu2_rv_BOUNDEDSET-0 ol_l2_cpu2_rv_BOUNDEDSET-1 pred_BOUNDEDSET-len pred_BOUNDEDSET-0 pred_BOUNDEDSET-1 truth_BOUNDEDSET-len truth_BOUNDEDSET-0 truth_BOUNDEDSET-1)
                #:guarantee (begin
                    (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol0))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol0))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol1))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol1))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol2))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol2))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol3))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol3))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol4))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol4))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol5))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol5))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol6))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol6))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol7))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol7))))) (assume (|| (! (eq? (ol_l2_cpu2_inv0 agg.result diff i n pred truth) (evaluate (ol_l2_cpu2_inv0 agg.result diff i n pred truth) sol8))) (! (eq? (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) (evaluate (ol_l2_cpu2_ps n pred truth ol_l2_cpu2_rv) sol8)))))
                    (assertions)
                )
            )
        )
        (sat? sol9)
        (print-forms sol9)
