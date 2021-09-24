# cinterop

![Testing](https://github.com/n0bra1n3r/cinterop/actions/workflows/test.yml/badge.svg)

A C/C++ interop library for the [Nim](https://nim-lang.org/) programming
language.

This project was directly inspired by the [nimline](https://github.com/sinkingsugar/nimline)
library.

## Overview

Similar to nimline, this library allows one to interop with C/C++ code without
having to create wrappers. Unlike nimline, cinterop does not depend on Nim's
experimental [dotOperators](https://nim-lang.org/docs/manual_experimental.html#special-operators)
feature and relies only on Nim's macro system to generate code.

Features include:

* No dependencies other than Nim's standard library.
* Convenience macros to declare C/C++ types and functions ([decls.nim](src/cinterop/decls.nim)).
* Conversion of a subset of Nim to its syntactical equivalent in C/C++ without
requiring forward declarations ([exprs.nim](src/cinterop/exprs.nim)).

This project **is not** a replacement for hand-written wrappers or wrapper
generators like [c2nim](https://github.com/nim-lang/c2nim). This library is
useful for **quickly prototyping** new code that depend on large C/C++
libraries, and is carefully designed so code can easily be migrated to use Nim's
[`header`](https://nim-lang.org/docs/manual.html#implementation-specific-pragmas-header-pragma)
and [`importcpp`](https://nim-lang.org/docs/manual.html#implementation-specific-pragmas-importcpp-pragma)
pragmas directly.

## Recommended compiler switches

This project uses Nim's [ARC](https://nim-lang.org/blog/2020/10/15/introduction-to-arc-orc-in-nim.html)
and C++17. It is well tested with non-trivial code using the Visual Studio
compiler on Windows. The recommended compiler switches are indicated at the top
of the main [test](tests/tcinterop.nim) file.

## Showcase

Please **see [tests](tests/)** for examples of most features. This section
provides an incomplete summary of the core functionality.

### C++ Class interop

Say you have the following C++ class:

```cpp
// simple.hpp

class CppClass1
{
public:
    int field1 = 1;

    int method1(int arg)
    {
        return 1 + arg;
    }
};
```

You simply need to declare the C++ type and the source file it resides in:

```nim
# simple.nim

import cinterop/decls

csource "simple.hpp":
  type CppClass1* = object of CClass
```

and then you can access the fields and methods of that type:

```nim
# main.nim

import cinterop/exprs

var instance1 = CppClass1.init()

echo cexpr[cint]^instance1.field1 # prints "1"

cexpr[cint]^instance1.field1 = 2

echo cexpr[cint]^instance1.method1(instance1.field1) # prints "3"
```

Notice that `cexpr[T]^` indicates the return type `T` of the whole expression,
and only needs to be used at the beginning. This means that types for members do
not need to be declared, as long as the type of the variable whose members are
accessed is known.

### Void returns

For expressions that evaluate to `void`, one can use the `cexpr^` invocation,
which is shorthand for `cexpr[void]^`:

```nim
cexpr^instance1.method1(0)
```

### Type inference

If the type of a return value does not need to be known but is used in an
operation, one can use the `cauto^` invocation like so:

```nim
cauto^instance1.field1 += 2
```

### Binary operations

A `cexpr[T]^` invocation can appear on either side of a binary operation.
`cauto^` can only be used on the right-hand side unless the left-hand side is
also a `cauto^` invocation. Examples:

```nim
cexpr[cint]^instance1.field1 += cexpr[cint]^instance1.field1

cauto^instance1.field1 += cexpr[cint]^instance1.field1 # same as above

cauto^instance1.field1 += cauto^instance1.field1 # same as above
```

### Free function interop

The following technique can be used for libraries with lots of functions that
don't hang off of classes:

```nim
# glfw3.nim

csource &"{GLFW}/glfw3.h": # header file
  type cglfw* {.cgen:"(glfw$1(@))".} = object of CClass
```

```nim
# canvas.nim
...
cauto^cglfw.GetMouseButton(self.window, button) == 1
# generates something like `glfwGetMouseButton(self.window, button) == 1`
...
```

`cglfw` here serves as a namespace that is not visible in C++. The `cgen` pragma
tells the compiler how `cglfw.GetMouseButton(self.window, button)` should be
generated and has the same semantics as Nim's `importcpp` pragma.

## Gotchas

`cauto^` can be used on the left-hand side of an initialization, but doing so
*may* cause backend compile errors:

```nim
let value = cauto^instance1.field1 # C++ backend may produce an error here
```

If this issue is encountered, the workaround is to explicitly specify the type:

```nim
let value = cexpr[cint]^instance1.field1
```

Other issues are documented in the tests.

## Installing

Thanks to @mantielero for adding initial support for nimble! The package can be
installed by following the nimble instructions [here](https://github.com/nim-lang/nimble#nimble-install).

## Usage

Typical usage is to import `cinterop/decls` in modules that declare C/C++ types,
and to import those modules along with `cinterop/exprs` to make use of them in
other modules.

## Contributing

This project is maintained during my free time, and serves as a tool for a game
engine I am writing after work hours. Contributions are welcome, and I will
merge them immediately if they serve to keep the project robust, simple, and
maintainable.

**Cheers and happy coding!** 🍺
