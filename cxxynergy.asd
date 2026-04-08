#|
  This file is a part of cl-cxx-jit project.
  Copyright (c) 2021 Islam Omar (io1131@fayoum.edu.eg)
|#

(defsystem :cxxynergy
  :version "1.0"
  :author "Islam Omar"
  :license "MIT"
  :depends-on (:cffi :uiop :trivial-garbage :alexandria)
  :components ((:file "package")
               (:module "src"
                :components ((:file "cxxynergy"))))
  :description "Common Lisp Cxx Interoperation"
  :long-description
  #.(with-open-file (stream (merge-pathnames
                             #p"README.org"
                             (or *load-pathname* *compile-file-pathname*))
                            :if-does-not-exist nil
                            :direction :input)
      (when stream
        (let ((seq (make-array (file-length stream)
                               :element-type 'character
                               :fill-pointer t)))
          (setf (fill-pointer seq) (read-sequence seq stream))
          seq)))
  :in-order-to ((test-op (test-op "cxx-jit-test"))))
