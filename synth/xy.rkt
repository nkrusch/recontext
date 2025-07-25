#lang rosette/safe

(require rosette/lib/synthax)  ; sketching library
(require rosette/lib/destruct) ; value destructuring

;; shorthand for 32-bit bitvector.
(define int32? (bitvector 32))

;; int -> 32-bit bitvect.
(define (INT i) (bv i int32?))

;; symbolic variables
;; (define-symbolic x y int32?)
(define-symbolic b c integer?)

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

(define-grammar (ex x)
  [exp (choose x (?? integer?) ((bop) (exp) (exp)))]   
  [bop (choose plus subs mult divs mods square cube)])

(define (constraints p b)
     (= (interpret (p b)) 25))

(define (prog b)
  (ex b #:depth 3))

(solve 
  (assert 
    (constraints prog b)))

(solve 
  (assert 
    (= (interpret (square (plus b 2))) 25)))


;; ; find one solution
;; (solve
;;   (assert
;;    (= (interpret (prog c)) c)))
;;  
;; ;; solution forall b
;; (define solution
;;   (synthesize
;;     #:forall (list c)
;;     #:guarantee (= (interpret (prog c)) c)))
;; 
;; (if (sat? solution) (print-forms solution) (print "UNSAT"))
;; 

;; ;; Specification:
;; ;; invariant must satisfy trace
;; (define (constraints f)
;;     (equal? (f (INT 0)) (INT 0)))
;;    ;; (and (= (f INT 0) INT 0) (= (f INT 1) INT 1)))
;;    ;;      (= (f INT 3) INT 3) (= (f INT 4) INT 4)))
;; 
;; ;; DSL: 2-variable invariant grammar
;; (define-grammar (invariant x)  
;;   [exp     ;; x | y | const | bop exp exp | op exp const
;;      (choose x (?? integer?) ;; (?? (int32?))
;;              ((bop) (exp) (exp)))]   
;;   [bop     ;; op  :=  + | - | * | / | %
;;      (choose + - * / )])
;; ;;     (choose bvadd bvsub bvmul bvsdiv bvsmod)])
;; 
;; ;; ;; invariant term
;; (define (term t)
;;   (invariant t #:depth 2))
;;
;; (solve
;;    (assert (= (term b) 0)))
;; 
;; (define solution
;;      (synthesize
;;       #:forall (list b c)
;;       #:guarantee (assert (= (term b) (+ c c)))))
;;
;; (define solution
;;    (synthesize
;;     #:forall    (list x y)
;;     #:guarantee (constraints term x y)))
;;  
;;(if (sat? solution) (print-forms solution) (print "UNSAT"))
(print "DONE")