(in-package :cxxynergy)

;;; ============================================================================
;;; Configuration Variables
;;; ============================================================================

(defparameter *cxx-compiler-executable-path* "/usr/bin/g++"
  "Path to the C++ compiler executable.")

(defparameter *cxx-compiler-flags* "-std=c++17 -Wall -Wextra -I/usr/include/eigen3"
  "Compiler flags passed to the C++ compiler.")

(defconstant +cxx-compiler-wrap-cxx-path+
  (uiop:merge-pathnames* "src/wrap-cxx.cpp" (asdf:system-source-directory :cxxynergy))
  "Path to the C++ wrapper code.")

(defparameter *cxx-compiler-internal-flags*
  "-shared -fPIC -Wl,--no-undefined -Wl,--no-allow-shlib-undefined"
  "Internal compiler flags for shared library creation.
For clang++ use: -shared -fPIC -Wl,-undefined,error -Wl,-flat_namespace")

(defparameter *cxx-compiler-link-libs* "-lm"
  "Linker flags for external libraries (added after -o output).")

;;; ============================================================================
;;; Type Mapping
;;; ============================================================================

(defparameter *cxx-type-name-to-cffi-type-symbol-alist*
  '(("const char*" . :string)
    ("char*" . :string)
    ("const char *" . :string)
    ("char *" . :string)
    ("void" . :void)
    ("char" . :char)
    ("signed char" . :char)
    ("unsigned char" . :uchar)
    ("short" . :short)
    ("short int" . :short)
    ("signed short int" . :short)
    ("short signed int" . :short)
    ("unsigned short" . :ushort)
    ("unsigned short int" . :ushort)
    ("short unsigned int" . :ushort)
    ("int" . :int)
    ("signed" . :int)
    ("signed int" . :int)
    ("unsigned" . :uint)
    ("unsigned int" . :uint)
    ("long" . :long)
    ("long int" . :long)
    ("signed long" . :long)
    ("signed long int" . :long)
    ("long signed int" . :long)
    ("unsigned long" . :ulong)
    ("unsigned long int" . :ulong)
    ("long unsigned int" . :ulong)
    ("long long" . :llong)
    ("long long int" . :llong)
    ("signed long long" . :llong)
    ("signed long long int" . :llong)
    ("unsigned long long" . :ullong)
    ("unsigned long long int" . :ullong)
    ("float" . :float)
    ("double" . :double)
    ("long double" . :long-double)
    ("bool" . :bool)
    ("size_t" . :size)
    ("ssize_t" . :ssize)
    ("int8_t" . :int8)
    ("uint8_t" . :uint8)
    ("int16_t" . :int16)
    ("uint16_t" . :uint16)
    ("int32_t" . :int32)
    ("uint32_t" . :uint32)
    ("int64_t" . :int64)
    ("uint64_t" . :uint64))
  "Alist mapping C++ type names to CFFI type keywords.")

;;; ============================================================================
;;; Conditions
;;; ============================================================================

(define-condition cxx-error (error)
  ((message :initarg :message
            :reader cxx-error-message))
  (:documentation "Base condition for CXXynergy errors."))

(define-condition cxx-compile-error (cxx-error)
  ()
  (:report (lambda (condition stream)
             (format stream "C++ compilation error: ~A"
                     (cxx-error-message condition))))
  (:documentation "Condition signaled when C++ compilation fails."))

(define-condition cxx-runtime-error (cxx-error)
  ()
  (:report (lambda (condition stream)
             (format stream "C++ runtime error: ~A"
                     (cxx-error-message condition))))
  (:documentation "Condition signaled when C++ code throws an exception."))

;;; ============================================================================
;;; Foreign Interface
;;; ============================================================================

(cffi:defcallback lisp-error :void ((err :string))
  "Callback for handling C++ exceptions."
  (error 'cxx-runtime-error :message err))

(cffi:defcstruct meta-data
  (func-name :string)
  (func-ptr :pointer)
  (method-p :bool)
  (arg-types (:pointer :string))
  (types-size :int8))

(cffi:defcallback reg-data :void ((meta-ptr :pointer))
  "Callback to register a C++ function from its metadata."
  (cffi:with-foreign-slots ((func-name func-ptr method-p arg-types types-size)
                            meta-ptr (:struct meta-data))
    (let* ((name (intern func-name))
           (args (loop :for i :below types-size
                       :collect (cffi:mem-aref arg-types :string i)))
           (return-type (car args))
           (param-types (cdr args))
           (arg-syms (generate-arg-symbols (length param-types) method-p)))
      ;; Build the function definition
      (eval
       `(defun ,name ,arg-syms
          (cffi:foreign-funcall-pointer
           ,func-ptr nil
           ,@(append
              (when method-p `(:pointer ,(car arg-syms)))
              (mapcan #'list
                      (mapcar #'cffi-type param-types)
                      (if method-p (cdr arg-syms) arg-syms))
              (list (cffi-type return-type)))))))))

;;; ============================================================================
;;; Utilities
;;; ============================================================================

(defun string-replace-first (str old new)
  "Replace the first occurrence of OLD with NEW in STR."
  (if-let ((pos (search old str)))
    (strcat (subseq str 0 pos)
            new
            (subseq str (+ pos (length old))))
    str))

(defun cffi-type (type)
  "Convert a C++ type name string to a CFFI type keyword.
Unknown types default to :pointer."
  (declare (type string type))
  (or (cdr (assoc type *cxx-type-name-to-cffi-type-symbol-alist*
                  :test #'string-equal))
      (prog1
          :pointer
        (when (char/= #\* (last-char type))
          (format t "Warning: Unknown C++ type ~S, defaulting to :pointer~%" type)))))

(defun generate-arg-symbols (count &optional method-p)
  "Generate a list of argument symbols (V0 V1 V2 ...).
For methods, prepends OBJ as the first argument."
  (let ((syms (loop :for i :below count
                    :collect (intern (format nil "V~A" i)))))
    (if method-p (cons (intern "OBJ") syms) syms)))

(defun parse-foreign-args (arg-types method-p)
  "Parse argument types into CFFI declaration form.
Returns a list suitable for use in foreign-funcall-pointer."
  (when arg-types
    (let ((syms (generate-arg-symbols (length arg-types) method-p)))
      (mapcan #'list
              (mapcar #'cffi-type arg-types)
              syms))))

(defun format-includes (headers)
  "Format a list of headers as C++ #include directives."
  (with-output-to-string (stream)
    (dolist (header headers)
      (format stream (strcat "#include "
                             (if (member (char header 0) '(#\< #\")) "~A" "~S")
                             "~%")
              header))))

;;; ============================================================================
;;; Compilation
;;; ============================================================================

(defun compile-and-load-code (code)
  "Compile C++ source CODE string to a shared library.
Returns T on success, signals CXX-COMPILE-ERROR on failure."
  (with-temporary-file (:stream source-stream
                        :prefix "cxxynergy"
                        :pathname source-path
                        :type "cpp"
                        :direction :output)
    (write-string code source-stream)
    (finish-output source-stream)
    (with-temporary-file (:prefix "cxxynergy"
                          :type "so"
                          :pathname output-path)
      (let ((cmd (format nil "~A ~A ~A ~A -o ~A ~A"
                         *cxx-compiler-executable-path*
                         *cxx-compiler-internal-flags*
                         *cxx-compiler-flags*
                         source-path
                         output-path
                         *cxx-compiler-link-libs*)))
        (multiple-value-bind (stdout stderr code)
            (uiop:run-program cmd :output :string
                                  :error-output :string
                                  :ignore-error-status t)
          (declare (ignore stdout))
          (if (/= code 0)
              (error 'cxx-compile-error :message stderr)
              (cffi:load-foreign-library output-path))
          t)))))

;;; ============================================================================
;;; High-Level API
;;; ============================================================================

(defun %from (includes imports)
  "Internal: Compile and import C++ functions.
INCLUDES is a list of header files.
IMPORTS is a list of (C++-EXPR . LISP-NAME) pairs or raw C++ code strings."
  (let* ((header-code (format-includes includes))
         (pack-name (symbol-name (gensym "RegisterPackage")))
         (import-code (with-output-to-string (stream)
                        (dolist (item imports)
                          (if (consp item)
                              (format stream "~%IMPORT(~A, ~A);"
                                      (cdr item) (car item))
                              (format stream "~A~%" item)))))
         (wrap-code (uiop:read-file-string +cxx-compiler-wrap-cxx-path+))
         (cxx-code (string-replace-first
                    (string-replace-first wrap-code "$" pack-name)
                    "// BlaBlaBla;" import-code)))
    (compile-and-load-code (strcat header-code cxx-code))
    ;; Register functions
    (let ((*cxx--fun-names* (mappend (lambda (item)
                                       (when (consp item)
                                         (list (cdr item))))
                                     imports)))
      (eval `(cffi:foreign-funcall ,pack-name
                                   :pointer (cffi:callback lisp-error)
                                   :pointer (cffi:callback reg-data))))))

(defmacro with-cxx (includes &body body)
  "Import C++ functions into Lisp.

Syntax:
  (with-cxx (\"<header1>\" \"<header2>\" ...)
    (defcxxfun lisp-name \"cpp-expression\" )
    ...
    (cxx-raw \"raw C++ code\"))"
  (with-gensyms (includes-var imports-var)
    `(let ((,includes-var (list ,@includes))
           (,imports-var '()))
       (macrolet
           ((defcxxfun (lisp-name cpp-expr)
              `(push (cons ,cpp-expr (quote ,lisp-name)) ,',imports-var)))
         (flet ((cxx-raw (raw-code)
                  (push raw-code ,imports-var))
                (cxx-include (include)
                  (push include ,imports-var)))
           ,@body))
       (%from ,includes-var (nreverse ,imports-var)))))

(defun delete-cxx-object (ptr &optional string-p)
  "Delete a C++ object allocated by the C++ side.
If STRING-P is non-nil, treat PTR as a char* allocated by new[].
Otherwise, treat it as a std::any* containing a C++ object."
  (cffi:foreign-funcall "ClCxxDeleteObject"
                        :pointer ptr
                        :bool string-p
                        :bool))

(defmacro with-cxx-string ((var cxx-string-ptr) &body body)
  "Execute BODY with VAR bound to a C++ string, then free it."
  `(let ((,var ,cxx-string-ptr))
     (unwind-protect (progn ,@body)
       (when ,var (delete-cxx-object ,var t)))))
