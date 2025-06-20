#lang rosette/safe

(require rosette/lib/synthax)  ; sketching library
(require rosette/lib/destruct) ; value destructuring

;; shorthand for 32-bit bitvector.
(define int32? (bitvector 32))

;; int -> 32-bit bitvect.
(define (INT i) (bv i int32?))

;; symbolic variables
(define-symbolic b c integer?)
(define-symbolic x y int32?)

 ;; DSL: 2-variable invariant grammar
(define-grammar (inv x y)  
  [exp     ;; x | y | bop exp exp | op exp const
     (choose x y
             ((bop) (exp) (exp))
             ((bop) (exp) (const)))]   
  [bop     ;; op  :=  + | - | * | / | %
     (choose bvadd bvsub bvmul bvsdiv bvsmod)]
  [const   ;; c := const
     (choose (?? int32?))])

; syntax
(struct plus (left right) #:transparent)
(struct mult (left right) #:transparent)
(struct subs (left right) #:transparent)
(struct divs (left right) #:transparent)
(struct mods (left right) #:transparent)
(struct square (arg)      #:transparent)
(struct cube   (arg)      #:transparent)

; semantics
(define (interpret p)
  (destruct p
    [(plus a b)  (+ (interpret a) (interpret b))]
    [(mult a b)  (* (interpret a) (interpret b))]
    [(subs a b)  (- (interpret a) (interpret b))]
    [(divs a b)  (/ (interpret a) (interpret b))]
    [(mods a b)  (modulo (interpret a) (interpret b))]
    [(square a)  (expt (interpret a) 2)]
    [(cube   a)  (expt (interpret a) 3)]
    [_ p]))


;; find one solution
(solve
 (assert
  (= (interpret (mult c b)) (+ b b))))

;; solution forall b
(synthesize
  #:forall (list b)
  #:guarantee (assert (= (interpret (mult c b)) (+ b b))))


;; invariant term
(define (term a b)
  (inv a b #:depth 3))

;; Specification:
;; invariant must satisfy trace
(define (same fn)
  (assert (bveq (INT 0)(fn (INT 0) (INT 0))))
) 

;(define solution
;   (synthesize
;    #:forall    (list x y)
;    #:guarantee (same term x y)))
;(if (sat? solution) (print-forms solution) (print "UNSAT"))

(print "DONE")