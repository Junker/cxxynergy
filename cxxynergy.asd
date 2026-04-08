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
  #.(uiop:read-file-string (merge-pathnames #p"README.org"
                                            (or *load-pathname*
                                                *compile-file-pathname*))
                           :if-does-not-exist nil)
  :in-order-to ((test-op (test-op "cxxynergy-test"))))
