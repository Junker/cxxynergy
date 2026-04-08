#|
  This file is a part of lcm project.
  Copyright (c) 2021 Islam Omar (io1131@fayoum.edu.eg)
|#

(defpackage :cxxynergy/test/system
  (:use :cl :asdf :uiop))

(in-package :cxxynergy/test/system)

(defsystem :cxxynergy-test
  :author "Islam Omar"
  :license "MIT"
  :depends-on (:cxxynergy
               :rove)
  :components ((:module "tests"
                :components
                ((:file "functions-test"))))
  :description "Test system for cxxynergy"

  :perform (test-op (op c) (symbol-call :rove '#:run c)))
