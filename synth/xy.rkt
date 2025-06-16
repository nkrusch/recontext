#lang rosette/safe

(require rosette/lib/synthax)  ; sketching library
(require rosette/lib/destruct) ; value destructuring

; syntax
(struct plus (left right) #:transparent)
(struct mul  (left right) #:transparent)
(struct square (arg)      #:transparent)

; semantics
(define (interpret p)
  (destruct p
    [(plus a b)  (+ (interpret a) (interpret b))]
    [(mul a b)   (* (interpret a) (interpret b))]
    [(square a)  (expt (interpret a) 2)]
    [_ p]))

;; symbolic variables
(define-symbolic b c integer?)

;; find one solution
(solve (assert (= (interpret (mul c b)) (+ b b))))

;; forall x
(synthesize
  #:forall (list b)
  #:guarantee (assert (= (interpret (mul c b)) (+ b b))))

;; ================================================

;; shorthand for 32-bit bitvector.
(define int32? (bitvector 32))

;; int -> 32-bit bitvect.
(define (INT i) (bv i int32?))

;; DSL (2-variable) invariant grammar
(define-grammar (inv x y)  
  ;; e := x | y | op exp exp | op const exp
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

;; variables
(define-symbolic x y int32?)

(define solution
   (synthesize
    #:forall    (list x y)
    #:guarantee (same term x y)))

(if (sat? solution) (print-forms solution) (print "UNSAT"))

(print "DONE")