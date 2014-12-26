#lang racket

(provide draw-rules)

(require lang/posn
         openssl/sha1
         2htdp/image
         sugar
         "utils.rkt")

; Constants
(define RHOMBUS-ANGLE 60)
(define HEX-TOP 200)
(define HEX-LEFT 80)
(define HEX-RIGHT 155)
(define ALPHA-MAX 50)
(define DEFAULT-ALPHA 255)
(define CANVAS-COLOR "white")
(define BORDER-MAX 10)

; Data structs
(struct point (x y) #:transparent)
(struct dim (w h) #:transparent)
(struct canvas (outside inside border) #:transparent)
(struct hex (offset row col point image) #:transparent)

; Rhombus offset - the hexes are two sideways rhombii tall, so this
; will calculate 1/4 of their height, used in stacking on y-axis
(define (rhombus-offset height)
  (- height (/ height 4)))

; Pad a list with its last value to size
(define (pad-list l size)
  (cond
    [(empty? l) (build-list size values)]
    [(< (length l) size) (pad-list (append l (list (last l))) size)]
    [else l]))

; Fold over a list of lists and gather values from pos in each list into a new list
(define (gather-values pos l)
  (cond
    [(empty? l) '()]
    [else (foldl (λ (x y) (cons (if (empty? x)
                                    '()
                                    (pos x)) y)) '() l)]))

; Build up a list of triplets '(1 2 3) to use as color information
(define (make-triplets user)
  (cond 
    [(> (modulo (length user) 3) 0) (error "user must have multiples of three")])
  (let* ([initial (filter (λ (x) (> (length x) 0)) (slice-at user 3))]
         [triples (if (< (length initial) 3)
                      (append initial (list (reverse (last initial))))
                      initial)]
         [firsts (slice-at (pad-list (gather-values first triples) 3) 3)]
         [seconds (slice-at (pad-list (gather-values second triples) 3) 3)]
         [thirds (slice-at (pad-list (gather-values third triples) 3) 3)])
    (append initial firsts seconds thirds)))

; Take the dimensions and calculate a border 10% of dim and the internal draw space
(define (make-canvas width height)
  (let* ([border (min (* width .1) BORDER-MAX)]
         [iw (->int (- width (* border 2)))]
         [ih (->int (- height (* border 2)))]
         [outside (dim width height)]
         [inside (dim iw ih)])
    (canvas outside inside border)))

; Generate a color with alphas from r g b list
(define (build-color base-color [alpha DEFAULT-ALPHA])
  (cond
    [(string? base-color) base-color]
    [(list? base-color) (color (first base-color)
                               (second base-color)
                               (third base-color)
                               (max ALPHA-MAX alpha))]))

; Given a width, find the side length of a rhombus using rwidth by searching constraints
(define (find-side width)
  (let ([r (range (+ width 1))])
    (define (loop n)
      (cond
        [(empty? n) 0]
        [(>= (round (rwidth (first n))) width) (first n)]
        [else (loop (rest n))]))
    (loop r)))

; Get width of rhombus from length of side
(define (rwidth side)
  (sqrt
   (+ (* 2 (expt side 2))
      (* (* 2 (expt side 2))
         (cos (degrees->radians RHOMBUS-ANGLE))))))

; hex (offset row col point image)
(define (build-hexes points size hex-dim hex-offset canvas)
  (for/list ([row points]
             [row-pos (range (length points))]
             [offset (map even? (range 0 (length points)))])
    (for/list ([color row]
               [col (range (length row))])
      (let* ([w (dim-w hex-dim)]
             [h (dim-h hex-dim)]
             [dx (/ (- (/ (dim-w (canvas-inside canvas)) 2) (/ (* (dim-w hex-dim) (length row)) 2)) 2)]
             [dy (- (dim-w (canvas-inside canvas)) (* (rhombus-offset h) 4))]
             [off (if offset
                      (+ (/ w 2) dx)
                      dx)]
             [x (+ (* w col) (/ w 2) off)]
             [y (+ (* (rhombus-offset h) row-pos) (+ (/ h 2) (/ dy 4)))])
        (hex offset row-pos col (point x y) (make-hex size color))))))

; (build (make-canvas 200 200) (make-triplets (build-list 18 (λ (x) (random 255)))) 3)
(define (build canvas triplets columns)
  (let* ([points (slice-at (filter-triplets triplets) columns)]
         [rows (length points)]
         [canvas-w (dim-w (canvas-inside canvas))]
         [canvas-h (dim-h (canvas-inside canvas))]
         [point-h (/ canvas-h rows)]
         [hex-size (find-side point-h)]
         [hex (make-hex hex-size "white")]
         [hex-dim (dim (image-width hex) (image-height hex))]
         [hex-offset-x (* (dim-w hex-dim) .5)]
         [hexes (flatten (build-hexes points hex-size hex-dim hex-offset canvas))]
         [scene (square (dim-w (canvas-inside canvas)) "solid" CANVAS-COLOR)])
    (define (loop image hexes)
      (cond
        [(empty? hexes) image]
        [else (place-image
               (hex-image (first hexes))
               (point-x (hex-point (first hexes)))
               (point-y (hex-point (first hexes)))
               (loop scene (rest hexes)))]))
    (overlay
     (loop scene hexes)
     (square (dim-w (canvas-outside canvas)) "solid" CANVAS-COLOR))))


; Create a hexagon from three rhombii
(define (make-hex size base-color)
  (overlay/offset
   (rotate 90 (rhombus size RHOMBUS-ANGLE "solid" (build-color base-color HEX-TOP)))
   0 (rhombus-offset size)
   (beside (rotate 30 (rhombus size RHOMBUS-ANGLE "solid" (build-color base-color HEX-LEFT)))
           (rotate -30 (rhombus size RHOMBUS-ANGLE "solid" (build-color base-color HEX-RIGHT))))))

; Numbers divisible by 3 are white
(define (filter-triplets triplets)
  (map (λ (t)
         (if (zero? (modulo (foldl + 0 t) 3))
             CANVAS-COLOR
             t)) triplets))

; Main draw function
(define (draw-rules width height user)
  (let* ([canvas (make-canvas width height)])
    (build canvas (make-triplets user) 3)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Tests

(module+ test
  (require quickcheck
           sugar)
  
  ; rhombus-offset calculcation is correct
  (define rhombus-offset-outputs-agree
    (property ([num arbitrary-natural])
              (let* ([onum (rhombus-offset num)]
                     [diff (- num onum)])
                (= num
                   (* diff 4)))))
  (quickcheck rhombus-offset-outputs-agree)  
  
  ; pad-list should increase the list to size
  (define pad-list-lengths-agree
    (property ([lst (arbitrary-list arbitrary-natural)]
               [size arbitrary-natural])
              (>= (length (pad-list lst size)) size)))
  (quickcheck pad-list-lengths-agree)
  
  ; gather values will builds up lists made from pos values in lst
  (define gather-values-lengths-agree
    (property ([lst (arbitrary-list (arbitrary-list arbitrary-natural))])
              (let ([len (length lst)])
                (= (length (gather-values first lst)) len))))
  (quickcheck gather-values-lengths-agree))
