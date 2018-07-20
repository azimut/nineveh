;;;; nineveh.asd

(asdf:defsystem #:nineveh
  :description "A library of common gpu functions"
  :author "Chris Bagley (Baggers) <techsnuffle@gmail.com>"
  :license "BSD 2 Clause"
  :serial t
  :depends-on (#:cepl #:cl-soil #:livesupport #:easing
                      #:documentation-utils #:dendrite.primitives
                      #:rtg-math.vari #:with-setf)
  :components ((:file "package")
               ;;
               (:file "internals/quad")
               ;;
               (:file "math-primitives/log")
               (:file "math-primitives/clamping")
               (:file "math-primitives/mod")
               (:file "math-primitives/atan2")
               (:file "math-primitives/remap")
               (:file "math-primitives/radical-inverse")
               (:file "math-primitives/vmax")
               (:file "math-primitives/docs")
               ;;
               (:file "conditionals/conditional-optimizations")
               ;;
               (:file "color/color-space-conversions")
               (:file "color/sets")
               (:file "color/luminance")
               ;;
               (:file "hashing/blum-blum-shub-hash")
               (:file "hashing/permutation-polynomial-hash")
               (:file "hashing/bsharpe-fast-32-hash")
               (:file "hashing/bsharpe-quick32-hash")
               (:file "hashing/docs")
               ;;
               (:file "shaping-functions/to-sort")
               (:file "shaping-functions/interpolation")
               (:file "shaping-functions/falloff")
               (:file "shaping-functions/polynominal")
               ;;
               (:file "noise/simplex-helpers")
               (:file "noise/value-noise")
               (:file "noise/perlin")
               (:file "noise/value-perlin")
               (:file "noise/cubist")
               (:file "noise/cellular")
               (:file "noise/misc")
               (:file "noise/hermite")
               (:file "noise/value-hermite")
               ;;
               (:file "easing/easing")
               (:file "random/random")
               (:file "random/hammersley")
               (:file "random/docs")
               ;;
               (:file "mesh/data/primitives")
               ;;
               (:file "normals/calculate-normals")
               ;;
               (:file "graphing/axis")
               (:file "graphing/graph")
               (:file "graphing/plot")
               ;;
               (:file "textures/sampling")
               (:file "textures/draw-texture")
               (:file "textures/dirty-blit")
               (:file "textures/cube-tex-fbos")
               (:file "textures/hdr-cross-cube-map-loader")
               ;;
               (:file "streams/buffer-streamer")
               (:file "streams/quad-streams")
               ;;
               (:file "tonemapping/operators")
               ;;
               (:file "sdf/2d/sdf")
               ;;
               (:file "vignette/vignette")
               ;;
               (:file "distortion/distortion")
               ;;
               (:file "antialiasing/fxaa2")
               (:file "antialiasing/fxaa3")
               ;;
               (:file "graphing/particle/particle-graph")
               ;;
               (:file "misc")))
