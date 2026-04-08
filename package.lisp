(defpackage :cxxynergy
  (:use #:cl
        #:cffi
        #:trivial-garbage
        #:alexandria)
  ;; Configuration
  (:import-from #:uiop
                #:strcat
                #:last-char
                #:with-temporary-file)
  (:export #:*cxx-compiler-executable-path*
           #:*cxx-compiler-flags*
           #:+cxx-compiler-lib-name+
           #:+cxx-compiler-wrap-cxx-path+
           #:*cxx-compiler-internal-flags*
           #:*cxx-compiler-link-libs*
           #:*cxx-type-name-to-cffi-type-symbol-alist*
           #:*cxx-auto-export*)
  ;; Conditions
  (:export #:cxx-error
           #:cxx-compile-error
           #:cxx-runtime-error
           #:cxx-error-message)
  ;; Core API
  (:export #:with-cxx)
  ;; Memory management
  (:export #:delete-cxx-object
           #:with-cxx-string))
