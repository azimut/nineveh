(in-package :nineveh.graphing)

;;
;; This is a simple 3d graph that just uses instanced particles
;; as the points. Not the best for rapidly changing values but
;; could be handy for getting a general idea of what a function
;; is about.
;;

;;------------------------------------------------------------
;;

(defvar *pgraph-blend-params*
  (make-blending-params
   :mode-rgb :func-add
   :mode-alpha :func-add
   :source-rgb :one
   :destination-rgb :one
   :source-alpha :one
   :destination-alpha :one))

;;------------------------------------------------------------

(defun-g pgraph-dot-frag ((uv :vec2)
                          (color :vec4))
  (let ((sdf-scale 25f0))
    (mix
     (v! 0 0 0 0)
     color
     (nineveh.sdf.2d:mask-fill
      (nineveh.sdf.2d:circle (- (* uv 2 sdf-scale) (vec2 sdf-scale))
                             sdf-scale)))))

;;------------------------------------------------------------
;;

(defun pgraph-world->view (pos3 dir3)
  (m4:look-at (v! 0 1 0) pos3 (v3:+ pos3 dir3)))

(defun pgraph-view->clip ()
  (let ((vp (current-viewport)))
    (rtg-math.projection:perspective
     (float (viewport-resolution-x vp) 0f0)
     (float (viewport-resolution-y vp) 0f0)
     1f0
     5000f0
     45f0)))

(defun pgraph-process-pos (position-vec3)
  position-vec3)

(defun pgraph-process-dir (direction-vec3)
  direction-vec3)

;;------------------------------------------------------------

(defclass pgraph-control-state () ())

;;------------------------------------------------------------
;; Universal

(defgeneric args-for (kind))
(defgeneric instance-count-for (kind))
(defgeneric vert-transform-for (kind))
(defgeneric wrap-in-func-for (kind var body))

(defun key-args-for (kind)
  (loop
     :for (name init nil nil) :in (args-for kind)
     :collect (list name init)))

(defun dispatch-args-for (kind)
  (loop
     :for (name nil type lisp-form) :in (args-for kind)
     :for kwd := (intern (string name) :keyword)
     :when type
     :append (list kwd lisp-form)))

(defun uniform-args-for (kind)
  (loop
     :for (name nil type nil) :in (args-for kind)
     :when type
     :collect (list name type)))

;;------------------------------------------------------------
;; Range Graph

(defun-g range-vert-transform ((fn (function (:float) :vec3))
                               (vert g-pt)
                               (world->view :mat4)
                               (proj :mat4)
                               (point-size :float)
                               (point-color :vec4)
                               ;;
                               (min :float)
                               (by :float))
  (with-slots (position texture) vert
    (let* ((input (+ min (* by (float gl-instance-id))))
           (func-result (funcall fn input))
           (world-pos (vec4 func-result 1.0))
           (view-pos (+ (* world->view world-pos)
                        (vec4 (* position point-size) 0)))
           (clip-pos (* proj view-pos)))
      (values
       clip-pos
       texture
       point-color))))

(defmethod vert-transform-for ((kind (eql :range)))
  'range-vert-transform)

(defmethod args-for ((kind (eql :range)))
  '((min 0f0 :float (float min 0f0))
    (max 100f0 nil (float by 0f0))
    (by 1f0 :float (float by 0f0))))

(defmethod instance-count-for ((kind (eql :range)))
  `(floor (/ (- (float max 0f0)
                (float min 0f0))
             (float by 0f0))))

(defmethod wrap-in-func-for ((kind (eql :range)) var body)
  `(graph-func ((,var :float)) (the :vec3 (progn ,@body))))

;;------------------------------------------------------------
;; Range-Color Graph

(defun-g range-col-vert-transform ((fn (function (:float) (:vec3 :vec4)))
                                   (vert g-pt)
                                   (world->view :mat4)
                                   (proj :mat4)
                                   (point-size :float)
                                   (point-color :vec4)
                                   ;;
                                   (min :float)
                                   (by :float))
  (with-slots (position texture) vert
    (let* ((input (+ min (* by (float gl-instance-id)))))
      (multiple-value-bind (func-pos func-col) (funcall fn input)
        (let* ((world-pos (vec4 func-pos 1.0))
               (view-pos (+ (* world->view world-pos)
                            (vec4 (* position point-size) 0)))
               (clip-pos (* proj view-pos)))
          (values
           clip-pos
           texture
           func-col))))))

;; HEY! change this to 'range-vert-transform and watch it break,
;;      somethign is funky in the compiler
(defmethod vert-transform-for ((kind (eql :range-color)))
  'range-col-vert-transform)

(defmethod args-for ((kind (eql :range-color)))
  '((min 0f0 :float (float min 0f0))
    (max 100f0 nil (float by 0f0))
    (by 1f0 :float (float by 0f0))))

(defmethod instance-count-for ((kind (eql :range-color)))
  `(floor (/ (- (float max 0f0)
                (float min 0f0))
             (float by 0f0))))

(defmethod wrap-in-func-for ((kind (eql :range-color)) var body)
  `(graph-func ((,var :float)) (the :vec3 (progn ,@body))))

;;------------------------------------------------------------
;; Height Graph

(defun-g height-vert-transform ((fn (function (:vec2) :float))
                                (vert g-pt)
                                (world->view :mat4)
                                (proj :mat4)
                                (point-size :float)
                                (point-color :vec4)
                                ;;
                                (x-min :float)
                                (x-max :float)
                                (y-min :float)
                                (y-max :float)
                                (by :float)
                                (spacing :float))
  (with-slots (position texture) vert
    (let* ((id (float gl-instance-id))
           (x-range (/ (- x-max x-min) by))
           (y-range (/ (- y-max y-min) by))
           (x (* (mod id x-range) by))
           (y (* (/ id x-range) by))
           (input (vec2 x y))
           (pos2 (* input spacing point-size))
           (func-result (funcall fn input))
           (world-pos (v! (x pos2) func-result (y pos2) 1.0))
           (view-pos (+ (* world->view world-pos)
                        (vec4 (* position point-size) 0)))
           (clip-pos (* proj view-pos)))
      (values
       clip-pos
       texture
       point-color))))

(defmethod vert-transform-for ((kind (eql :height)))
  'height-vert-transform)

(defmethod args-for ((kind (eql :height)))
  '((x-min 0f0 :float (float x-min 0f0))
    (x-max 100f0 :float (float x-max 0f0))
    (y-min 0f0 :float (float y-min 0f0))
    (y-max 100f0 :float (float y-max 0f0))
    (by 1f0 :float (float by 0f0))
    (spacing 1.3f0 :float (float spacing 0f0))))

(defmethod instance-count-for ((kind (eql :height)))
  `(floor (* (/ (- x-max x-min) by)
             (/ (- y-max y-min) by))))

(defmethod wrap-in-func-for ((kind (eql :height)) var body)
  `(graph-func ((,var :vec2)) (the :float (progn ,@body))))

;;------------------------------------------------------------
;; Height-Col Graph

(defun-g height-col-vert-transform ((fn (function (:vec2) (:float :vec4)))
                                (vert g-pt)
                                (world->view :mat4)
                                (proj :mat4)
                                (point-size :float)
                                (point-color :vec4)
                                ;;
                                (x-min :float)
                                (x-max :float)
                                (y-min :float)
                                (y-max :float)
                                (by :float)
                                (spacing :float))
  (with-slots (position texture) vert
    (let* ((id (float gl-instance-id))
           (x-range (/ (- x-max x-min) by))
           (y-range (/ (- y-max y-min) by))
           (x (* (mod id x-range) by))
           (y (* (/ id x-range) by))
           (input (vec2 x y))
           (pos2 (* input spacing point-size)))
      (multiple-value-bind (func-result func-col)
          (funcall fn input)
        (let* ((world-pos (v! (x pos2) func-result (y pos2) 1.0))
               (view-pos (+ (* world->view world-pos)
                            (vec4 (* position point-size) 0)))
               (clip-pos (* proj view-pos)))
          (values
           clip-pos
           texture
           func-col))))))

(defmethod vert-transform-for ((kind (eql :height-color)))
  'height-col-vert-transform)

(defmethod args-for ((kind (eql :height-color)))
  '((x-min 0f0 :float (float x-min 0f0))
    (x-max 100f0 :float (float x-max 0f0))
    (y-min 0f0 :float (float y-min 0f0))
    (y-max 100f0 :float (float y-max 0f0))
    (by 1f0 :float (float by 0f0))
    (spacing 1.3f0 :float (float spacing 0f0))))

(defmethod instance-count-for ((kind (eql :height-color)))
  `(floor (* (/ (- x-max x-min) by)
             (/ (- y-max y-min) by))))

(defmethod wrap-in-func-for ((kind (eql :height-color)) var body)
  `(graph-func ((,var :vec2)) ,@body))

;;------------------------------------------------------------

(defmacro define-pgraph (name
                         (kind &rest options &key &allow-other-keys)
                                               (arg-name &rest uniforms)
                         &body body)
  (declare (ignore options))
  (assert (and (symbolp arg-name) (not (keywordp arg-name))))
  (let* ((vert-name (intern (format nil "%~a-VERT" name) *package*))
         (pline-name (intern (format nil "%~a-PIPELINE" name) *package*))
         (uniform-names (mapcar #'first uniforms))
         (uniform-keys (mapcar (lambda (x) (intern (string x) :keyword))
                               uniform-names))
         (func (wrap-in-func-for kind arg-name body)))
    `(progn
       (defun-g ,vert-name ((vert g-pt)
                            &uniform
                            (world->view :mat4)
                            (point-size :float)
                            (proj :mat4)
                            (point-color :vec4)
                            ,@(uniform-args-for kind)
                            ,@uniforms)
         (flet (,func)
           (,(vert-transform-for kind)
             #',(first func) vert world->view proj point-size point-color
             ,@(mapcar #'first (uniform-args-for kind)))))
       (defpipeline-g ,pline-name ()
         :vertex (,vert-name g-pt)
         :fragment (pgraph-dot-frag :vec2 :vec4))
       (defun ,name (position-vec3
                     direction-vec3
                     &key
                       (point-color (vec4 0.7 0.7 0.8 0.0))
                       (point-size 1f0)
                       ,@(key-args-for kind)
                       ,@uniform-names)
         (let* ((pos (pgraph-process-pos position-vec3))
                (dir (pgraph-process-dir direction-vec3)))
           (with-setf (depth-test-function) nil
             (with-blending *pgraph-blend-params*
               (with-instances ,(instance-count-for kind)
                 (map-g #',pline-name (nineveh.internals:get-gpu-quad)
                        :world->view (pgraph-world->view pos dir)
                        :proj (pgraph-view->clip)
                        :point-color point-color
                        :point-size (float point-size 0f0)
                        ,@(dispatch-args-for kind)
                        ,@(mapcan #'list uniform-keys uniform-names))))))))))

;;------------------------------------------------------------
