#lang rosette
(require "./bounded.rkt")
(require "./utils.rkt")
(require rosette/lib/angelic rosette/lib/match rosette/lib/synthax)
(require rosette/solver/smt/bitwuzla)
(current-solver (bitwuzla #:path "/bitwuzla/build/src/main/bitwuzla" #:options (hash ':seed 0)))



 (define-bounded (vec_scalar_sub a x)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (- (list-ref-noerr x 0 ) a ) (vec_scalar_sub a (list-tail-noerr x 1 )) ) ))


 (define-bounded (vec_map x map_int_to_int)
(if (< (length x ) 1 ) (list-empty ) (list-prepend (map_int_to_int (list-ref-noerr x 0 )) (vec_map (list-tail-noerr x 1 ) map_int_to_int) ) ))

(define-grammar (softmax_part2_inv0_gram agg.result cur i input max_pos max_val)
 [rv (choose (&& (&& (>= i 0 ) (<= i max_pos ) ) (equal? agg.result (vec_map (vec_scalar_sub (v0) (v1)) map_int_to_int) ) ))]
[v0 (choose max_pos max_val)]
[v1 (choose (list-take-noerr input i ))]
)

(define-grammar (softmax_part2_ps_gram input max_pos max_val softmax_part2_rv)
 [rv (choose (equal? softmax_part2_rv (vec_map (vec_scalar_sub (v0) (v1)) map_int_to_int) ))]
[v0 (choose max_pos max_val)]
[v1 (choose (list-take-noerr input max_pos ))]
)

(define-grammar (map_int_to_int_gram int_x)
 [rv (choose (v0))]
[v0 (choose (integer-exp int_x ) (integer-sqrt int_x ))]
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
 (assert (&& (&& (=> (&& (&& (> (length input ) 0 ) (<= max_pos (length input ) ) ) (>= max_pos 1 ) ) (softmax_part2_inv0 (list-empty ) 0 0 input max_pos max_val) ) (=> (&& (&& (&& (&& (< i max_pos ) (> (length input ) 0 ) ) (<= max_pos (length input ) ) ) (>= max_pos 1 ) ) (softmax_part2_inv0 agg.result cur i input max_pos max_val) ) (softmax_part2_inv0 (list-append agg.result (integer-exp (- (list-ref-noerr input i ) max_val ) ) ) (integer-exp (- (list-ref-noerr input i ) max_val ) ) (+ i 1 ) input max_pos max_val) ) ) (=> (or (&& (&& (&& (&& (! (< i max_pos ) ) (> (length input ) 0 ) ) (<= max_pos (length input ) ) ) (>= max_pos 1 ) ) (softmax_part2_inv0 agg.result cur i input max_pos max_val) ) (&& (&& (&& (&& (&& (! true ) (! (< i max_pos ) ) ) (> (length input ) 0 ) ) (<= max_pos (length input ) ) ) (>= max_pos 1 ) ) (softmax_part2_inv0 agg.result cur i input max_pos max_val) ) ) (softmax_part2_ps input max_pos max_val agg.result) ) )))


    (define sol0
        (synthesize
            #:forall (list agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 cur i input_BOUNDEDSET-len input_BOUNDEDSET-0 input_BOUNDEDSET-1 max_pos max_val softmax_part2_rv_BOUNDEDSET-len softmax_part2_rv_BOUNDEDSET-0 softmax_part2_rv_BOUNDEDSET-1)
            #:guarantee (assertions)
        )
    )
    (sat? sol0)
    (print-forms sol0)
