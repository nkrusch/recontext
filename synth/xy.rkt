#lang rosette/safe

; Require the sketching library.
(require rosette/lib/synthax)

;; shorthand for 32-bit bitvector.
(define int32? (bitvector 32))

;; int -> 32-bit bitvect.
(define (INT i) (bv i int32?))

;; Invariant grammar (of 2 variables)
(define-grammar (inv x y)  
  ;; e := x | y | op e e | op c e
  [e (choose x y ((op) (e) (e)) ((op) (c) (e)))] 
  ;; op  :=  + | - | * | %
  [op (choose bvadd bvsub bvmul bvsmod)]
  ;; c := const
  [c (choose (?? int32?))]
)

;; Specification:
;; invariant must satisfy trace
(define (same fn a b)
  (assert (bveq (INT 0)(fn a b)))
) 
  
;; invariant term
(define (term v1 v2)
  (inv v1 v2 #:depth 2))

(define-symbolic x y int32?)

(define solution
   (synthesize
    #:forall    (list x y)
    #:guarantee (same term x y)))


(if (sat? solution) (print-forms solution) (print "UNSAT"))
(print "DONE")