(defpackage cxxynergy/test
  (:use #:cl
        #:rove
        #:cxxynergy))
(in-package :cxxynergy/test)

(with-cxx ("<string>")
  (defcxxfun hi "[](std::string x){return \"Hi, \"+x;}" ))

(deftest string-example
  (testing "string manipulation"
    (ok (string= (hi "there!") "Hi, there!"))))

(with-cxx ("<cmath>")
  (defcxxfun cpp-sin "static_cast<double(*)(double)>(std::sin)"))

(deftest math-example
  (testing "math functions"
    (ok (= (cpp-sin 0d0) 0d0))
    (ok (= (cpp-sin (/ pi 2)) 1d0))))

(with-cxx ("<cmath>")
  (defcxxfun cpp-sqrt "static_cast<double(*)(double)>(std::sqrt)")
  (defcxxfun cpp-exp "static_cast<double(*)(double)>(std::exp)")
  (defcxxfun cpp-log "static_cast<double(*)(double)>(std::log)"))

(deftest multiple-functions
  (testing "importing multiple functions"
    (ok (= (cpp-sqrt 4d0) 2d0))
    (ok (> (cpp-exp 1d0) 2.717d0))
    (ok (< (cpp-exp 1d0) 2.719d0))))

(with-cxx ()
  (cxx-raw "struct C { auto hi(){return \"Hello World!\";} auto bye(){return \"Bye\";}; };")
  (defcxxfun chi "&C::hi")
  (defcxxfun cbye "&C::bye")
  (defcxxfun get-c "[](){static C x; return x;}"))

(deftest raw-code-injection
  (testing "raw C++ code injection"
    (let ((obj (get-c)))
      (ok (string= (chi obj) "Hello World!")))))
