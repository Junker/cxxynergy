(defpackage cxxynergy/test
  (:use :cl :rove :cxxynergy))
(in-package :cxxynergy/test)

(deftest string-example
  (testing "string manipulation"
           (with-cxx ("<string>")
             (defcxxfun hi "[](std::string x){return \"Hi, \"+x;}" ))
           (ok (string= (hi "there!") "Hi, there!"))))

(deftest math-example
  (testing "math functions"
           (with-cxx ("<cmath>")
             (defcxxfun cpp-sin "static_cast<double(*)(double)>(std::sin)"))
           (ok (= (cpp-sin 0d0) 0d0))
           (ok (= (cpp-sin (/ pi 2)) 1d0))))

(deftest multiple-functions
  (testing "importing multiple functions"
           (with-cxx ("<cmath>")
             (defcxxfun cpp-sqrt "static_cast<double(*)(double)>(std::sqrt)")
             (defcxxfun cpp-exp "static_cast<double(*)(double)>(std::exp)")
             (defcxxfun cpp-log "static_cast<double(*)(double)>(std::log)"))
           (ok (= (cpp-sqrt 4d0) 2d0))
           (ok (> (cpp-exp 1d0) 2.717d0))
           (ok (< (cpp-exp 1d0) 2.719d0))))

(deftest raw-code-injection
  (testing "raw C++ code injection"
    (with-cxx ()
      (cxx-raw "struct C { auto hi(){return \"Hello World!\";} auto bye(){return \"Bye\";}; };")
      (defcxxfun hi "&C::hi")
      (defcxxfun bye "&C::bye")
      (defcxxfun get-c "[](){static C x; return x;}"))
    (let ((obj (get-c)))
      (ok (string= (hi obj) "Hello World!")))))

(run-suite *package*)
