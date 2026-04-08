(defsystem :cxxynergy-test
  :author "Islam Omar, Dmitrii Kosenkov"
  :license "MIT"
  :depends-on (:cxxynergy
               :rove)
  :components ((:module "tests"
                :components
                ((:file "functions-test"))))
  :description "Test system for cxxynergy"
  :perform (test-op (op c) (symbol-call :rove '#:run c)))
