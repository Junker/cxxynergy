# CXXynergy - Common Lisp C++ JIT for exposing C++ functions

This library provides an interface to C++ from Common Lisp. It compiles C++ code, then loads it into Lisp. This project is a fork of [CL-CXX-JIT](https://github.com/Islam0mar/CL-CXX-JIT).

## Installation

This system can be installed from [UltraLisp](https://ultralisp.org/) like this:

```common-lisp
(ql-dist:install-dist "http://dist.ultralisp.org/"
                      :prompt nil)
(ql:quickload :cxxynergy)
```

## Quick Start

```common-lisp
(in-package :cxxynergy)

;; Simple function import
(with-cxx ("<cmath>")
  (defcxxfun cpp-sin
      "static_cast<double(*)(double)>(std::sin)"))

(cpp-sin 0.0d0)  ; => 0.0d0
(cpp-sin (/ pi 2))  ; => 1.0d0

;; String manipulation
(with-cxx ("<string>")
  (defcxxfun hi "[](std::string x){return \"Hi, \"+x;}"))
(hi "there!")  ; => "Hi, there!"
```

## API Reference

### Core Macros

#### `with-cxx`

Import C++ functions into Lisp.
This is an atomic macro, meaning that all functions defined within it will be accessible after the macro is executed, not during its execution.

```common-lisp
(with-cxx (headers...)
  (cxx-include "additional-header")
  (cxx-raw "raw C++ code")
  (defcxxfun lisp-name "cpp-expression"))
```

**Examples:**

```common-lisp
;; Import multiple functions
(with-cxx ("<cmath>")
  (defcxxfun sin-cpp "static_cast<double(*)(double)>(std::sin)")
  (defcxxfun cos-cpp "static_cast<double(*)(double)>(std::cos)"))

;; Define helper functions inline
(with-cxx ("<string>")
  (cxx-raw "inline std::string prefix(const std::string& s) { return \"[PREFIX] \" + s; }")
  (defcxxfun prefixed
     "[](const std::string& s){return prefix(s);}"))
```

### Memory Management

#### `delete-cxx-object`

Delete a C++ object allocated on the C++ side.

```common-lisp
(delete-cxx-object pointer &optional string-p)
```

### Configuration Variables

| Variable                        | Default Value                                      |
| ------------------------------- | -------------------------------------------------- |
| `*cxx-compiler-executable-path*` | `/usr/bin/g++`                                     |
| `*cxx-compiler-flags*`          | `-std=c++17 -Wall -Wextra -I/usr/include/eigen3`   |
| `+cxx-compiler-wrap-cxx-path+`  | Path to wrap-cxx.cpp (auto-detected)               |
| `*cxx-compiler-internal-flags*` | `-shared -fPIC -Wl,--no-undefined -Wl,--no-allow-shlib-undefined` |
| `*cxx-compiler-link-libs*`      | `-lm`                                              |
| `*cxx-type-name-to-cffi-type-symbol-alist*` | Alist mapping C++ types to CFFI types        |

### Conditions

- `cxx-error`: Base condition for all CXXynergy errors
- `cxx-compile-error`: Signaled when C++ compilation fails
- `cxx-runtime-error`: Signaled when C++ code throws an exception

## Examples

### SDL2 Example

![SDL2 Example](sdl2.gif)

```common-lisp
(ql:quickload :cxxynergy)
(in-package :cxxynergy)

(setf *cxx-compiler-link-libs* "-lGL -lSDL2 -lSDL2main")

(with-cxx ("<SDL2/SDL.h>")
  (defcxxfun sdl-init "[](){return SDL_Init(SDL_INIT_VIDEO);}")
  (defcxxfun create-window "SDL_CreateWindow")
  (defcxxfun create-renderer "SDL_CreateRenderer")
  (defcxxfun set-color "SDL_SetRenderDrawColor")
  (defcxxfun destroy-window "SDL_DestroyWindow")
  (defcxxfun clear-renderer "SDL_RenderClear")
  (defcxxfun renderer-render "SDL_RenderPresent")
  (defcxxfun sdl-quit "SDL_Quit"))

(sdl-init)
(defparameter *window* (create-window "My Window" 0 0 600 700 0))
(defparameter *renderer* (create-renderer *window* -1 0))

(loop for x to (* 255 3)
      for r = (if (> x 255) 255 x)
      for g = (if (> x 255) (if (> x (* 2 255)) 255 (rem x 256)) 0)
      for b = (if (> x (* 2 255)) (rem x 256) 0)
      do (set-color *renderer* r g b 255)
         (clear-renderer *renderer*)
         (renderer-render *renderer*)
         (sleep 0.01))

(destroy-window *window*)
(sdl-quit)
```

### Class Methods Example

```common-lisp
(with-cxx ()
  (cxx-raw "struct C { auto hi(){return \"Hello, World\\n\";} auto bye(){return \"Bye\";}; };")
  (defcxxfun hi "&C::hi")
  (defcxxfun bye "&C::bye")
  (defcxxfun get-c "[](){static C x; return x;}"))

(defparameter *obj* (get-c))
(hi *obj*)   ; => "Hello, World\n"
(bye *obj*)  ; => "Bye"
```

### Eigen Library Example

```common-lisp
(with-cxx ("<Eigen/Core>")
  (defcxxfun print-matrix
      "[](Eigen::CwiseNullaryOp<Eigen::internal::scalar_identity_op<double>,Eigen::Matrix<double, 3, 3>> x){ std::stringstream s; s << x; return s.str();}")
  (defcxxfun identity-matrix
      "static_cast<const Eigen::CwiseNullaryOp<Eigen::internal::scalar_identity_op<double>,Eigen::Matrix<double, 3, 3>> (*)()> (&Eigen::Matrix3d::Identity)"))

(print-matrix (identity-matrix))
```

## Prerequisites

- Common Lisp implementation supporting CFFI
- Working C++17 compiler (g++ or clang++)
- The compiler should support the flags specified in `*cxx-compiler-internal-flags*`

## Installation

Clone into `~/common-lisp/` or `~/quicklisp/local-projects/`:

```bash
cd ~/common-lisp
git clone https://github.com/Junker/cxxynergy.git
```

Then:

```common-lisp
(ql:quickload :cxxynergy-test)
```

## Supported Types

| C++ type           | Lisp CFFI type |
|--------------------|----------------|
| fundamental        | same           |
| string             | `:string`      |
| class              | `:pointer`     |
| `std::is_function` | `:pointer`     |
| other              | `:pointer`     |


## TODO List

- [ ] Add redirect stdout
- [ ] Use trivial-garbage with `ClCxxDeleteObject`
- [ ] Add non-polling `from`
- [ ] Benchmark
- [ ] Better class interface

## Warning

This software is in active development. The APIs may change.
