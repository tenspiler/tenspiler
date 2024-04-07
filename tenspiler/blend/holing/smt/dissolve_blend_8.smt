; list definitions
(declare-datatypes ((MLList 1))
                   ((par (T) ((cons (head T) (tail (MLList T))) (nil)))))

(define-sort List_T1 () Int)


;(define-fun-rec list_length ((l (MLList List_T1))) Int
  ;(ite (= l nil) 0 (+ 1 (list_length (tail l))))
;)
(declare-fun list_length ( (MLList List_T1) ) Int)

(assert (= (list_length (as nil (MLList List_T1))) 0))
(assert (forall ( (val List_T1) (l (MLList List_T1)) )
                (= (list_length (cons val l)) (+ 1 (list_length l)))))
(assert (forall ( (l (MLList List_T1)) )
                (<= 0 (list_length l))))


(define-fun list_prepend ( (val List_T1) (l (MLList List_T1)) ) (MLList List_T1) (cons val l))


(declare-fun list_append ( (MLList List_T1) List_T1 ) (MLList List_T1))

(assert (forall ( (val List_T1) )
                (= (list_append (as nil (MLList List_T1)) val) (cons val (as nil (MLList List_T1))))))
(assert (forall ( (h List_T1) (t (MLList List_T1)) (val List_T1) )
                (= (list_append (cons h t) val) (cons h (list_append t val)))))


(declare-fun list_get_helper ( (MLList List_T1) Int ) List_T1)
(define-fun list_get ( (l (MLList List_T1)) (i Int) ) List_T1 (list_get_helper l i))

(assert (forall ( (h List_T1) (t (MLList List_T1)) (i Int) )
                (ite (<= i 0)
                     (= (list_get_helper (cons h t) i) h)
                     (= (list_get_helper (cons h t) i) (list_get_helper t (- i 1))))))


(define-fun list_empty ( ) (MLList List_T1) (as nil (MLList List_T1)))


(define-fun-rec list_tail ((l (MLList List_T1) ) (n Int)) (MLList List_T1)
  (ite (<= n 0)  l (list_tail (tail l) (- n 1))))


(assert (forall ( (start Int) (h List_T1) (t (MLList List_T1)) )
                (ite (<= start 0)
                     (= (list_tail (cons h t) start) (cons h t))
                     (= (list_tail (cons h t) start) (list_tail t (- start 1))))))
(assert (forall ( (start Int) )
                (= (list_tail (as nil (MLList List_T1)) start) (as nil (MLList List_T1)))))
(assert (forall ( (start Int) (l (MLList List_T1)) )
                (=> (>= start (list_length l))
                    (= (list_tail l start) (as nil (MLList List_T1))))))


(declare-fun list_take ( (MLList List_T1) Int ) (MLList List_T1))

(assert (forall ( (end Int) (h List_T1) (t (MLList List_T1)) )
                (ite (<= end 0)
                     (= (list_take (cons h t) end) (as nil (MLList List_T1)))
                     (= (list_take (cons h t) end) (cons h (list_take t (- end 1)))))))
(assert (forall ( (end Int) )
                (= (list_take (as nil (MLList List_T1)) end) (as nil (MLList List_T1)))))
(assert (forall ( (end Int) (l (MLList List_T1)) )
                (=> (>= end (list_length l))
                    (= (list_take l end) l))))

(assert (forall ( (l (MLList List_T1)) ) (= (list_take l 0) (as nil (MLList List_T1)))))

;(declare-fun list_concat ( (MLList List_T1) (MLList List_T1) ) (MLList List_T1))
;(assert (forall ((xs (MLList List_T1)) (ys (MLList List_T1)) (x List_T1))
;            (ite (= (as nil (MLList List_T1)) xs)
;                 (= (list_concat xs ys) ys)
;                 (= (list_concat (cons x xs) ys) (cons x (list_concat xs ys))))))

(define-fun-rec list_concat ((xs (MLList List_T1)) (ys (MLList List_T1))) (MLList List_T1)
    (ite (= (as nil (MLList List_T1)) xs)
         ys
         (cons (head xs) (list_concat (tail xs) ys))))

(define-fun-rec list_contains ((l (MLList List_T1)) (val List_T1)) Bool
  (ite (= (list_length l) 0)
       false
       (ite (= (head l) val)
            true
            (list_contains (tail l) val))))

; list axioms

; l :: nil = l
(assert (forall ( (l (MLList List_T1)) )
                (= (list_concat l (as nil (MLList List_T1))) l)))


; l[i:] = l[i] : l[i+1:]
(assert (forall ( (l (MLList List_T1)) (i Int) (out (MLList List_T1)) )
                (=> (and (>= i 0) (< i (list_length l)))
                    (= (list_tail l i)
                       (cons (list_get l i) (list_tail l (+ i 1)))))))

; xs :: (y : ys) = (xs : y) :: ys
(assert (forall ( (xs (MLList List_T1)) (y List_T1) (ys (MLList List_T1)) )
                (= (list_concat xs (cons y ys))
                   (list_concat (list_append xs y) ys))))


; end of list definition

; list of lists definition

(declare-fun matrix_length ( (MLList (MLList Int) ) ) Int)
(assert (= (matrix_length (as nil (MLList (MLList Int) ))) 0))
(assert (forall ( (val (MLList Int) ) (l (MLList (MLList Int) )) )
                (= (matrix_length (cons val l)) (+ 1 (matrix_length l)))))
(assert (forall ( (l (MLList (MLList Int) )) )
                (<= 0 (matrix_length l))))

;end of list length

(define-fun matrix_prepend ( (val (MLList Int) ) (l (MLList (MLList Int) ) )) (MLList (MLList Int) ) (cons val l))
; end of list prepend


(declare-fun matrix_append ( (MLList (MLList Int)  ) (MLList Int) ) (MLList (MLList Int) ))
(assert (forall ( (val (MLList Int)) )
                (= (matrix_append (as nil (MLList (MLList Int))) val) (cons val (as nil (MLList (MLList Int)))))))
(assert (forall ( (h (MLList Int)) (t (MLList (MLList Int))) (val (MLList Int)) )
                (= (matrix_append (cons h t) val) (cons h (matrix_append t val)))))
;end of list append

(declare-fun matrix_get_helper ( (MLList (MLList Int) ) Int ) (MLList Int) )
(define-fun matrix_get ( (l (MLList (MLList Int) )) (i Int) ) (MLList Int) (matrix_get_helper l i))
(assert (forall ( (h (MLList Int) ) (t (MLList (MLList Int) )) (i Int) )
                (ite (<= i 0)
                     (= (matrix_get_helper (cons h t) i) h)
                     (= (matrix_get_helper (cons h t) i) (matrix_get_helper t (- i 1))))))
;end of list get

(define-fun matrix_empty ( ) (MLList (MLList Int)) (as nil (MLList (MLList Int) )))
;end of empty list



(define-fun-rec matrix_tail ((l (MLList (MLList Int) ) ) (n Int)) (MLList (MLList Int) )
  (ite (<= n 0)  l (matrix_tail (tail l) (- n 1))))
(assert (forall ( (start Int) (h (MLList Int) ) (t (MLList (MLList Int) )) )
                (ite (<= start 0)
                     (= (matrix_tail (cons h t) start) (cons h t))
                     (= (matrix_tail (cons h t) start) (matrix_tail t (- start 1))))))
(assert (forall ( (start Int) )
                (= (matrix_tail (as nil (MLList (MLList Int) )) start) (as nil (MLList (MLList Int)) ))))
(assert (forall ( (start Int) (l (MLList (MLList Int) )) )
                (=> (>= start (matrix_length l))
                    (= (matrix_tail l start) (as nil (MLList (MLList Int) ))))))

; end of list tail

(declare-fun matrix_take ( (MLList (MLList Int)) Int ) (MLList (MLList Int)))

(assert (forall ( (end Int) (h (MLList Int)) (t (MLList (MLList Int))) )
                (ite (<= end 0)
                     (= (matrix_take (cons h t) end) (as nil (MLList (MLList Int))))
                     (= (matrix_take (cons h t) end) (cons h (matrix_take t (- end 1)))))))
(assert (forall ( (end Int) )
                (= (matrix_take (as nil (MLList (MLList Int))) end) (as nil (MLList (MLList Int))))))
(assert (forall ( (end Int) (l (MLList (MLList Int))) )
                (=> (>= end (matrix_length l))
                    (= (matrix_take l end) l))))

(assert (forall ( (l (MLList (MLList Int))) ) (= (matrix_take l 0) (as nil (MLList (MLList Int))))))
; end of list take

; end of list of lists definition

(define-fun vec_slice ((lst (MLList Int)) (start Int) (end Int)) (MLList Int)
(list_take (list_take lst end) start))

(define-fun list_slice_with_length ((lst (MLList Int)) (start Int) (lst_length Int)) (MLList Int)
(vec_slice lst start (+ start lst_length)))

(define-fun matrix_row_slice ((matrix (MLList (MLList Int))) (start Int) (end Int)) (MLList (MLList Int))
(matrix_take (matrix_take matrix end) start))

(define-fun matrix_slice_with_length ((matrix (MLList (MLList Int))) (start Int) (lst_length Int)) (MLList (MLList Int))
(matrix_row_slice matrix start (+ start lst_length)))

(define-fun-rec matrix_col_slice ((matrix (MLList (MLList Int))) (start Int) (end Int)) (MLList (MLList Int))
(ite (< (matrix_length matrix) 1) matrix_empty (matrix_prepend (vec_slice (matrix_get matrix 0) start end) (matrix_col_slice (matrix_tail matrix 1) start end))))

(define-fun-rec matrix_col_slice_with_length ((matrix (MLList (MLList Int))) (start Int) (lst_length Int)) (MLList (MLList Int))
(matrix_col_slice matrix start (+ start lst_length)))

(define-fun-rec firsts ((matrix (MLList (MLList Int)))) (MLList Int)
(ite (< (matrix_length matrix) 1) list_empty (list_prepend (list_get (matrix_get matrix 0) 0) (firsts (matrix_tail matrix 1)))))

(define-fun-rec rests ((matrix (MLList (MLList Int)))) (MLList (MLList Int))
(ite (< (matrix_length matrix) 1) matrix_empty (matrix_col_slice matrix 1 (list_length (matrix_get matrix 0)))))

(define-fun-rec matrix_transpose ((matrix (MLList (MLList Int)))) (MLList (MLList Int))
(ite (< (matrix_length matrix) 1) matrix_empty (matrix_prepend (firsts matrix) (matrix_transpose (rests matrix)))))

(define-fun-rec dissolve_select_two_args ((int_x Int) (int_y Int) (opacity Int) (rand_cons Int)) Int
(ite (>= (- opacity (div (+ (mod rand_cons 100) 1) 100)) 0) int_y int_x))

(define-fun-rec dissolve_selection_two_args ((x (MLList Int)) (y (MLList Int)) (opacity Int) (rand_cons Int)) (MLList Int)
(ite (or (< (list_length x) 1) (not (= (list_length x) (list_length y)))) list_empty (list_prepend (dissolve_select_two_args (list_get x 0) (list_get y 0) opacity rand_cons) (dissolve_selection_two_args (list_tail x 1) (list_tail y 1) opacity rand_cons))))



(define-fun-rec dissolve_matrix_selection_two_args ((matrix_x (MLList (MLList Int))) (matrix_y (MLList (MLList Int))) (opacity Int) (rand_cons Int)) (MLList (MLList Int))
(ite (or (< (matrix_length matrix_x) 1) (not (= (matrix_length matrix_x) (matrix_length matrix_y)))) matrix_empty (matrix_prepend (dissolve_selection_two_args (matrix_get matrix_x 0) (matrix_get matrix_y 0) opacity rand_cons) (dissolve_matrix_selection_two_args (matrix_tail matrix_x 1) (matrix_tail matrix_y 1) opacity rand_cons))))

(define-fun-rec OUTER_LOOP_INDEX_FIRST () Bool
true)



(define-fun-rec dissolve_blend_8_inv0 ((active (MLList (MLList Int))) (agg.result (MLList (MLList Int))) (base (MLList (MLList Int))) (col Int) (opacity Int) (pixel Int) (rand_cons Int) (rand_val Int) (row Int) (row_vec (MLList Int))) Bool
(and (and (>= row 0) (<= row (matrix_length base))) (= agg.result (dissolve_matrix_selection_two_args (ite OUTER_LOOP_INDEX_FIRST (matrix_take base row) (matrix_col_slice active 0 row)) (ite OUTER_LOOP_INDEX_FIRST (matrix_take active row) (matrix_col_slice active 0 row)) opacity rand_cons))))



(define-fun-rec dissolve_blend_8_inv1 ((active (MLList (MLList Int))) (base (MLList (MLList Int))) (col Int) (opacity Int) (pixel Int) (rand_cons Int) (rand_val Int) (row_vec (MLList Int)) (agg.result (MLList (MLList Int))) (row Int)) Bool
(and (and (and (and (and (>= row 0) (<= row (matrix_length base))) (>= col 0)) (<= col (list_length (matrix_get base 0)))) (= row_vec (dissolve_selection_two_args (ite OUTER_LOOP_INDEX_FIRST (list_take (matrix_get base row) col) (matrix_get (matrix_transpose (matrix_col_slice_with_length (matrix_take active col) row 1)) 0)) (ite OUTER_LOOP_INDEX_FIRST (list_take (matrix_get active row) col) (matrix_get (matrix_transpose (matrix_col_slice_with_length (matrix_take active col) row 1)) 0)) opacity rand_cons))) (= agg.result (dissolve_matrix_selection_two_args (ite OUTER_LOOP_INDEX_FIRST (matrix_take base row) (matrix_col_slice active 0 row)) (ite OUTER_LOOP_INDEX_FIRST (matrix_take active row) (matrix_col_slice active 0 row)) opacity rand_cons))))



(define-fun-rec dissolve_blend_8_ps ((base (MLList (MLList Int))) (active (MLList (MLList Int))) (opacity Int) (rand_cons Int) (dissolve_blend_8_rv (MLList (MLList Int)))) Bool
(= dissolve_blend_8_rv (dissolve_matrix_selection_two_args base active opacity rand_cons)))

(declare-const rand_cons Int)
(declare-const base (MLList (MLList Int)))
(declare-const int_x Int)
(declare-const active (MLList (MLList Int)))
(declare-const agg.result (MLList (MLList Int)))
(declare-const col Int)
(declare-const pixel Int)
(declare-const rand_val Int)
(declare-const row Int)
(declare-const row_vec (MLList Int))
(declare-const dissolve_blend_8_rv (MLList Int))
(declare-const int_y Int)
(declare-const opacity Int)



(assert (not (and (and (and (and (=> (and (and (> (matrix_length base) 1) (= (matrix_length base) (matrix_length active))) (= (list_length (matrix_get base 0)) (list_length (matrix_get active 0)))) (dissolve_blend_8_inv0 active matrix_empty base 0 opacity 0 rand_cons 0 0 list_empty)) (=> (and (and (and (and (< row (matrix_length base)) (> (matrix_length base) 1)) (= (matrix_length base) (matrix_length active))) (= (list_length (matrix_get base 0)) (list_length (matrix_get active 0)))) (dissolve_blend_8_inv0 active agg.result base col opacity pixel rand_cons rand_val row row_vec)) (dissolve_blend_8_inv1 active base 0 opacity pixel rand_cons rand_val list_empty agg.result row))) (=> (or (and (and (and (and (and (and (and (>= (- opacity (div (+ (mod rand_cons 100) 1) 100)) 0) (< col (list_length (matrix_get base 0)))) (< row (matrix_length base))) (> (matrix_length base) 1)) (= (matrix_length base) (matrix_length active))) (= (list_length (matrix_get base 0)) (list_length (matrix_get active 0)))) (dissolve_blend_8_inv0 active agg.result base col opacity pixel rand_cons rand_val row row_vec)) (dissolve_blend_8_inv1 active base col opacity pixel rand_cons rand_val row_vec agg.result row)) (and (and (and (and (and (and (and (not (>= (- opacity (div (+ (mod rand_cons 100) 1) 100)) 0)) (< col (list_length (matrix_get base 0)))) (< row (matrix_length base))) (> (matrix_length base) 1)) (= (matrix_length base) (matrix_length active))) (= (list_length (matrix_get base 0)) (list_length (matrix_get active 0)))) (dissolve_blend_8_inv0 active agg.result base col opacity pixel rand_cons rand_val row row_vec)) (dissolve_blend_8_inv1 active base col opacity pixel rand_cons rand_val row_vec agg.result row))) (dissolve_blend_8_inv1 active base (+ col 1) opacity (ite (and (and (and (and (and (and (and (not (>= (- opacity (div (+ (mod rand_cons 100) 1) 100)) 0)) (< col (list_length (matrix_get base 0)))) (< row (matrix_length base))) (> (matrix_length base) 1)) (= (matrix_length base) (matrix_length active))) (= (list_length (matrix_get base 0)) (list_length (matrix_get active 0)))) (dissolve_blend_8_inv0 active agg.result base col opacity pixel rand_cons rand_val row row_vec)) (dissolve_blend_8_inv1 active base col opacity pixel rand_cons rand_val row_vec agg.result row)) (list_get (matrix_get base row) col) (list_get (matrix_get active row) col)) rand_cons (div (+ (mod rand_cons 100) 1) 100) (list_append row_vec (ite (and (and (and (and (and (and (and (not (>= (- opacity (div (+ (mod rand_cons 100) 1) 100)) 0)) (< col (list_length (matrix_get base 0)))) (< row (matrix_length base))) (> (matrix_length base) 1)) (= (matrix_length base) (matrix_length active))) (= (list_length (matrix_get base 0)) (list_length (matrix_get active 0)))) (dissolve_blend_8_inv0 active agg.result base col opacity pixel rand_cons rand_val row row_vec)) (dissolve_blend_8_inv1 active base col opacity pixel rand_cons rand_val row_vec agg.result row)) (list_get (matrix_get base row) col) (list_get (matrix_get active row) col))) agg.result row))) (=> (and (and (and (and (and (and (not (< col (list_length (matrix_get base 0)))) (< row (matrix_length base))) (> (matrix_length base) 1)) (= (matrix_length base) (matrix_length active))) (= (list_length (matrix_get base 0)) (list_length (matrix_get active 0)))) (dissolve_blend_8_inv0 active agg.result base col opacity pixel rand_cons rand_val row row_vec)) (dissolve_blend_8_inv1 active base col opacity pixel rand_cons rand_val row_vec agg.result row)) (dissolve_blend_8_inv0 active (matrix_append agg.result row_vec) base col opacity pixel rand_cons rand_val (+ row 1) row_vec))) (=> (or (and (and (and (and (not (< row (matrix_length base))) (> (matrix_length base) 1)) (= (matrix_length base) (matrix_length active))) (= (list_length (matrix_get base 0)) (list_length (matrix_get active 0)))) (dissolve_blend_8_inv0 active agg.result base col opacity pixel rand_cons rand_val row row_vec)) (and (and (and (and (and (not true) (not (< row (matrix_length base)))) (> (matrix_length base) 1)) (= (matrix_length base) (matrix_length active))) (= (list_length (matrix_get base 0)) (list_length (matrix_get active 0)))) (dissolve_blend_8_inv0 active agg.result base col opacity pixel rand_cons rand_val row row_vec))) (dissolve_blend_8_ps base active opacity rand_cons agg.result)))))

(check-sat)
(get-model)
