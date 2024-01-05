#lang rosette
(require "./bounded.rkt")
(require "./utils.rkt")
(require rosette/lib/angelic rosette/lib/match rosette/lib/synthax)
(require rosette/solver/smt/z3)
(current-solver (z3 #:options (hash ':random-seed 0)))



 (define-bounded (vec_elemwise_add x y) 
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (+ (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_add (list-tail-noerr x 1 ) (list-tail-noerr y 1 )) ) )) 


 (define-bounded (nested_list_elemwise_add nested_x nested_y) 
(if (or (< (length nested_x ) 1 ) (! (equal? (length nested_x ) (length nested_y ) ) ) ) (list-empty ) (list-prepend (vec_elemwise_add (list-list-ref-noerr nested_x 0 ) (list-list-ref-noerr nested_y 0 )) (nested_list_elemwise_add (list-tail-noerr nested_x 1 ) (list-tail-noerr nested_y 1 )) ) )) 


 (define-bounded (vec_elemwise_sub x y) 
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (- (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_sub (list-tail-noerr x 1 ) (list-tail-noerr y 1 )) ) )) 


 (define-bounded (nested_list_elemwise_sub nested_x nested_y) 
(if (or (< (length nested_x ) 1 ) (! (equal? (length nested_x ) (length nested_y ) ) ) ) (list-empty ) (list-prepend (vec_elemwise_sub (list-list-ref-noerr nested_x 0 ) (list-list-ref-noerr nested_y 0 )) (nested_list_elemwise_sub (list-tail-noerr nested_x 1 ) (list-tail-noerr nested_y 1 )) ) )) 


 (define-bounded (vec_elemwise_mul x y) 
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (* (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_mul (list-tail-noerr x 1 ) (list-tail-noerr y 1 )) ) )) 


 (define-bounded (nested_list_elemwise_mul nested_x nested_y) 
(if (or (< (length nested_x ) 1 ) (! (equal? (length nested_x ) (length nested_y ) ) ) ) (list-empty ) (list-prepend (vec_elemwise_mul (list-list-ref-noerr nested_x 0 ) (list-list-ref-noerr nested_y 0 )) (nested_list_elemwise_mul (list-tail-noerr nested_x 1 ) (list-tail-noerr nested_y 1 )) ) )) 


 (define-bounded (vec_elemwise_div x y) 
(if (or (< (length x ) 1 ) (! (equal? (length x ) (length y ) ) ) ) (list-empty ) (list-prepend (quotient-noerr (list-ref-noerr x 0 ) (list-ref-noerr y 0 ) ) (vec_elemwise_div (list-tail-noerr x 1 ) (list-tail-noerr y 1 )) ) )) 


 (define-bounded (nested_list_elemwise_div nested_x nested_y) 
(if (or (< (length nested_x ) 1 ) (! (equal? (length nested_x ) (length nested_y ) ) ) ) (list-empty ) (list-prepend (vec_elemwise_div (list-list-ref-noerr nested_x 0 ) (list-list-ref-noerr nested_y 0 )) (nested_list_elemwise_div (list-tail-noerr nested_x 1 ) (list-tail-noerr nested_y 1 )) ) )) 


 (define-bounded (vec_scalar_add a x) 
(if (< (length x ) 1 ) (list-empty ) (list-prepend (+ a (list-ref-noerr x 0 ) ) (vec_scalar_add a (list-tail-noerr x 1 )) ) )) 


 (define-bounded (nested_list_scalar_add a nested_x) 
(if (< (length nested_x ) 1 ) (list-empty ) (list-prepend (vec_scalar_add a (list-list-ref-noerr nested_x 0 )) (nested_list_scalar_add a (list-tail-noerr nested_x 1 )) ) )) 


 (define-bounded (vec_scalar_sub a x) 
(if (< (length x ) 1 ) (list-empty ) (list-prepend (- (list-ref-noerr x 0 ) a ) (vec_scalar_sub a (list-tail-noerr x 1 )) ) )) 


 (define-bounded (nested_list_scalar_sub a nested_x) 
(if (< (length nested_x ) 1 ) (list-empty ) (list-prepend (vec_scalar_sub a (list-list-ref-noerr nested_x 0 )) (nested_list_scalar_sub a (list-tail-noerr nested_x 1 )) ) )) 


 (define-bounded (vec_scalar_mul a x) 
(if (< (length x ) 1 ) (list-empty ) (list-prepend (* a (list-ref-noerr x 0 ) ) (vec_scalar_mul a (list-tail-noerr x 1 )) ) )) 


 (define-bounded (nested_list_scalar_mul a nested_x) 
(if (< (length nested_x ) 1 ) (list-empty ) (list-prepend (vec_scalar_mul a (list-list-ref-noerr nested_x 0 )) (nested_list_scalar_mul a (list-tail-noerr nested_x 1 )) ) )) 


 (define-bounded (vec_scalar_div a x) 
(if (< (length x ) 1 ) (list-empty ) (list-prepend (quotient-noerr (list-ref-noerr x 0 ) a ) (vec_scalar_div a (list-tail-noerr x 1 )) ) )) 


 (define-bounded (nested_list_scalar_div a nested_x) 
(if (< (length nested_x ) 1 ) (list-empty ) (list-prepend (vec_scalar_div a (list-list-ref-noerr nested_x 0 )) (nested_list_scalar_div a (list-tail-noerr nested_x 1 )) ) )) 

(define-grammar (multiply_blend_8_inv0_gram active agg.result base col pixel row row_vec)
 [rv (choose (&& (&& (>= row 0 ) (<= row (length base ) ) ) (equal? agg.result (nested_list_scalar_div 255 (nested_list_elemwise_mul (list-take-noerr base row ) (list-take-noerr active row ))) ) ))]

) 

(define-grammar (multiply_blend_8_inv1_gram active base col pixel row_vec agg.result row)
 [rv (choose (&& (&& (&& (&& (&& (>= row 0 ) (< row (length base ) ) ) (>= col 0 ) ) (<= col (length (list-list-ref-noerr base 0 ) ) ) ) (equal? row_vec (vec_scalar_div 255 (vec_elemwise_mul (list-take-noerr (list-list-ref-noerr base row ) col ) (list-take-noerr (list-list-ref-noerr active row ) col ))) ) ) (equal? agg.result (nested_list_scalar_div 255 (nested_list_elemwise_mul (list-take-noerr base row ) (list-take-noerr active row ))) ) ))]

) 

(define-grammar (multiply_blend_8_ps_gram base active multiply_blend_8_rv)
 [rv (choose (equal? multiply_blend_8_rv (v0) ))]
[v0 (choose (v1) (nested_list_scalar_mul (v3) (v1)) (nested_list_elemwise_mul (v1) (v1)) (nested_list_scalar_div (v3) (v1)) (nested_list_elemwise_div (v1) (v1)))]
[v1 (choose (v2) (nested_list_scalar_mul (v3) (v2)) (nested_list_elemwise_mul (v2) (v2)) (nested_list_scalar_div (v3) (v2)) (nested_list_elemwise_div (v2) (v2)))]
[v2 (choose base active)]
[v3 (choose 255)]
) 

(define (multiply_blend_8_inv0 active agg.result base col pixel row row_vec) (multiply_blend_8_inv0_gram active agg.result base col pixel row row_vec #:depth 10))
(define (multiply_blend_8_inv1 active base col pixel row_vec agg.result row) (multiply_blend_8_inv1_gram active base col pixel row_vec agg.result row #:depth 10))
(define (multiply_blend_8_ps base active multiply_blend_8_rv) (multiply_blend_8_ps_gram base active multiply_blend_8_rv #:depth 10))

(define-symbolic active_BOUNDEDSET-len integer?)
(define-symbolic active_BOUNDEDSET-0 integer?)
(define-symbolic active_BOUNDEDSET-1 integer?)
(define-symbolic active_BOUNDEDSET-2 integer?)
(define-symbolic active_BOUNDEDSET-3 integer?)
(define active (take (list (list active_BOUNDEDSET-0 active_BOUNDEDSET-1) (list active_BOUNDEDSET-2 active_BOUNDEDSET-3)) active_BOUNDEDSET-len))
(define-symbolic agg.result_BOUNDEDSET-len integer?)
(define-symbolic agg.result_BOUNDEDSET-0 integer?)
(define-symbolic agg.result_BOUNDEDSET-1 integer?)
(define-symbolic agg.result_BOUNDEDSET-2 integer?)
(define-symbolic agg.result_BOUNDEDSET-3 integer?)
(define agg.result (take (list (list agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1) (list agg.result_BOUNDEDSET-2 agg.result_BOUNDEDSET-3)) agg.result_BOUNDEDSET-len))
(define-symbolic base_BOUNDEDSET-len integer?)
(define-symbolic base_BOUNDEDSET-0 integer?)
(define-symbolic base_BOUNDEDSET-1 integer?)
(define-symbolic base_BOUNDEDSET-2 integer?)
(define-symbolic base_BOUNDEDSET-3 integer?)
(define base (take (list (list base_BOUNDEDSET-0 base_BOUNDEDSET-1) (list base_BOUNDEDSET-2 base_BOUNDEDSET-3)) base_BOUNDEDSET-len))
(define-symbolic col integer?)
(define-symbolic multiply_blend_8_rv_BOUNDEDSET-len integer?)
(define-symbolic multiply_blend_8_rv_BOUNDEDSET-0 integer?)
(define-symbolic multiply_blend_8_rv_BOUNDEDSET-1 integer?)
(define multiply_blend_8_rv (take (list multiply_blend_8_rv_BOUNDEDSET-0 multiply_blend_8_rv_BOUNDEDSET-1) multiply_blend_8_rv_BOUNDEDSET-len))
(define-symbolic pixel integer?)
(define-symbolic row integer?)
(define-symbolic row_vec_BOUNDEDSET-len integer?)
(define-symbolic row_vec_BOUNDEDSET-0 integer?)
(define-symbolic row_vec_BOUNDEDSET-1 integer?)
(define row_vec (take (list row_vec_BOUNDEDSET-0 row_vec_BOUNDEDSET-1) row_vec_BOUNDEDSET-len))
(current-bitwidth 6)
(define (assertions)
 (assert (&& (&& (&& (&& (=> (&& (&& (> (length base ) 1 ) (equal? (length base ) (length active ) ) ) (equal? (length (list-list-ref-noerr base 0 ) ) (length (list-list-ref-noerr active 0 ) ) ) ) (multiply_blend_8_inv0 active (list-empty ) base 0 0 0 (list-empty )) ) (=> (&& (&& (&& (&& (< row (length base ) ) (> (length base ) 1 ) ) (equal? (length base ) (length active ) ) ) (equal? (length (list-list-ref-noerr base 0 ) ) (length (list-list-ref-noerr active 0 ) ) ) ) (multiply_blend_8_inv0 active agg.result base col pixel row row_vec) ) (multiply_blend_8_inv1 active base 0 pixel (list-empty ) agg.result row) ) ) (=> (&& (&& (&& (&& (&& (&& (< col (length (list-list-ref-noerr base 0 ) ) ) (< row (length base ) ) ) (> (length base ) 1 ) ) (equal? (length base ) (length active ) ) ) (equal? (length (list-list-ref-noerr base 0 ) ) (length (list-list-ref-noerr active 0 ) ) ) ) (multiply_blend_8_inv0 active agg.result base col pixel row row_vec) ) (multiply_blend_8_inv1 active base col pixel row_vec agg.result row) ) (multiply_blend_8_inv1 active base (+ col 1 ) (quotient-noerr (* (list-ref-noerr (list-list-ref-noerr base row ) col ) (list-ref-noerr (list-list-ref-noerr active row ) col ) ) 255 ) (list-list-append row_vec (quotient-noerr (* (list-ref-noerr (list-list-ref-noerr base row ) col ) (list-ref-noerr (list-list-ref-noerr active row ) col ) ) 255 ) ) agg.result row) ) ) (=> (&& (&& (&& (&& (&& (&& (! (< col (length (list-list-ref-noerr base 0 ) ) ) ) (< row (length base ) ) ) (> (length base ) 1 ) ) (equal? (length base ) (length active ) ) ) (equal? (length (list-list-ref-noerr base 0 ) ) (length (list-list-ref-noerr active 0 ) ) ) ) (multiply_blend_8_inv0 active agg.result base col pixel row row_vec) ) (multiply_blend_8_inv1 active base col pixel row_vec agg.result row) ) (multiply_blend_8_inv0 active (list-list-append agg.result row_vec ) base col pixel (+ row 1 ) row_vec) ) ) (=> (or (&& (&& (&& (&& (! (< row (length base ) ) ) (> (length base ) 1 ) ) (equal? (length base ) (length active ) ) ) (equal? (length (list-list-ref-noerr base 0 ) ) (length (list-list-ref-noerr active 0 ) ) ) ) (multiply_blend_8_inv0 active agg.result base col pixel row row_vec) ) (&& (&& (&& (&& (&& (! true ) (! (< row (length base ) ) ) ) (> (length base ) 1 ) ) (equal? (length base ) (length active ) ) ) (equal? (length (list-list-ref-noerr base 0 ) ) (length (list-list-ref-noerr active 0 ) ) ) ) (multiply_blend_8_inv0 active agg.result base col pixel row row_vec) ) ) (multiply_blend_8_ps base active agg.result) ) )))

(define sol
 (synthesize
 #:forall (list active_BOUNDEDSET-len active_BOUNDEDSET-0 active_BOUNDEDSET-1 active_BOUNDEDSET-2 active_BOUNDEDSET-3 agg.result_BOUNDEDSET-len agg.result_BOUNDEDSET-0 agg.result_BOUNDEDSET-1 agg.result_BOUNDEDSET-2 agg.result_BOUNDEDSET-3 base_BOUNDEDSET-len base_BOUNDEDSET-0 base_BOUNDEDSET-1 base_BOUNDEDSET-2 base_BOUNDEDSET-3 col multiply_blend_8_rv_BOUNDEDSET-len multiply_blend_8_rv_BOUNDEDSET-0 multiply_blend_8_rv_BOUNDEDSET-1 pixel row row_vec_BOUNDEDSET-len row_vec_BOUNDEDSET-0 row_vec_BOUNDEDSET-1)
 #:guarantee (assertions)))
 (sat? sol)
 (print-forms sol)