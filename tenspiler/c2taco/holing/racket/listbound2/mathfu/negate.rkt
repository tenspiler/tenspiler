#lang rosette
(require "./bounded.rkt")
(require "./utils.rkt")
(require rosette/lib/angelic rosette/lib/match rosette/lib/synthax)
(require rosette/solver/smt/bitwuzla)
(current-solver (bitwuzla #:path "/Users/jieq/Desktop/bitwuzla/build/src/main/bitwuzla" #:options (hash ':seed 0)))



 (define-bounded (scalar_vec_sub a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (- a (list-ref-noerr x 0 ) ) (scalar_vec_sub a (list-tail-noerr x 1 )) ) ))

(define-grammar (negate_inv0_gram agg.result arr i n ref.tmp)
 [rv (choose (&& (&& (>= i 0 ) (<= i n ) ) (equal? agg.result (scalar_vec_sub 0 (v0)) ) ))]
[v0 (choose (list-take-noerr arr i ))]
)

(define-grammar (negate_ps_gram arr n negate_rv)
 [rv (choose (equal? negate_rv (scalar_vec_sub 0 (v0)) ))]
[v0 (choose (list-take-noerr arr n ))]
)

(define (negate_inv0 agg.result arr i n ref.tmp) (negate_inv0_gram agg.result arr i n ref.tmp #:depth 10))
(define (negate_ps arr n negate_rv) (negate_ps_gram arr n negate_rv #:depth 10))

(define-symbolic agg.result_BOUNDEDSET-len integer?)
(define-symbolic agg.result_BOUNDEDSET-0 integer?)
(define-symbolic agg.result_BOUNDEDSET-1 integer?)
(define agg.result (take (list agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1) agg.result_BOUNDEDSET-len))
(define-symbolic arr_BOUNDEDSET-len integer?)
(define-symbolic arr_BOUNDEDSET-0 integer?)
(define-symbolic arr_BOUNDEDSET-1 integer?)
(define arr (take (list arr_BOUNDEDSET-0 arr_BOUNDEDSET-1) arr_BOUNDEDSET-len))
(define-symbolic i integer?)
(define-symbolic n integer?)
(define-symbolic negate_rv_BOUNDEDSET-len integer?)
(define-symbolic negate_rv_BOUNDEDSET-0 integer?)
(define-symbolic negate_rv_BOUNDEDSET-1 integer?)
(define negate_rv (take (list negate_rv_BOUNDEDSET-0 negate_rv_BOUNDEDSET-1) negate_rv_BOUNDEDSET-len))
(define-symbolic ref.tmp integer?)
(current-bitwidth 6)
(define (assertions)
 (assert (&& (&& (=> (&& (>= n 1 ) (>= (length arr ) n ) ) (negate_inv0 (list-empty ) arr 0 n 0) ) (=> (&& (&& (&& (< i n ) (>= n 1 ) ) (>= (length arr ) n ) ) (negate_inv0 agg.result arr i n ref.tmp) ) (negate_inv0 (list-append agg.result (- 0 (list-ref-noerr arr i ) ) ) arr (+ i 1 ) n (- 0 (list-ref-noerr arr i ) )) ) ) (=> (or (&& (&& (&& (! (< i n ) ) (>= n 1 ) ) (>= (length arr ) n ) ) (negate_inv0 agg.result arr i n ref.tmp) ) (&& (&& (&& (&& (! true ) (! (< i n ) ) ) (>= n 1 ) ) (>= (length arr ) n ) ) (negate_inv0 agg.result arr i n ref.tmp) ) ) (negate_ps arr n agg.result) ) )))


    (define sol0
        (synthesize
            #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 arr_BOUNDEDSET-len arr_BOUNDEDSET-0 arr_BOUNDEDSET-1 i n negate_rv_BOUNDEDSET-len negate_rv_BOUNDEDSET-0 negate_rv_BOUNDEDSET-1 ref.tmp)
            #:guarantee (assertions)
        )
    )
    (sat? sol0)
    (print-forms sol0)