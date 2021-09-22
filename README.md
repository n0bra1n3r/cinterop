# cinterop

A C/C++ interop library for the [Nim](https://nim-lang.org/) programming
language.

Similar to the [`nimline`](https://github.com/sinkingsugar/nimline) library,
this library allows one to interop with C/C++ code without having to generate
wrappers with tools like [`nimterop`](https://github.com/nimterop/nimterop).
Unlike `nimline`, `cinterop` does not depend on Nim's experimental
[`dotOperators`](https://nim-lang.org/docs/manual_experimental.html#special-operators)
feature and relies only on Nim's macro system to generate code.

## Overview

* Provides convenience macros to declare C/C++ types and functions
(`decls.nim`).
* Converts a subset of Nim to its syntactical equivalent in C/C++ without
requiring forward declarations for all types and functions involved in the
expression (`exprs.nim`).

## Showcase

**See tests** for examples of most features. This section provides an
incomplete summary of the core functionality.

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

csource "simple.hpp":
  type CppClass1* = object of CClass
```

and then you can access the fields and methods of that type:

```nim
# main.nim

var instance1 = CppClass1.init()

echo cexpr[cint]^instance1.field1 # prints "1"

cexpr[cint]^instance1.field1 = 2

echo cexpr[cint]^instance1.method1(instance1.field1) # prints "3"
```

Notice that `cexpr[T]^` indicates the return type `T` of the whole expression,
and only needs to be used at the beginning. This means that types for members do
not need to be declared, as long as the type of the variable whose members are
accessed is known.

Nim requires that the result of a function all with a return type must be used,
so if the result of a method is to be discarded, one can use the `cexpr^`
invocation, which is shorthand for `cexpr[void]^`:

```nim
cexpr^instance1.method1(0)
```

If the type of a return value does not need to be known but is used in an
operation, one can use the `cexpr^!` invocation like so:

```nim
cexpr^!instance1.field1 += 2
```

To simply the mechanics of `cexpr[T]^`, it is required on both sides of a binary
operation if both sides are C/C++ expressions:

```nim
cexpr[cint]^!instance1.field1 += cexpr[cint]^!instance1.field1

cexpr^!instance1.field1 += cexpr[cint]^!instance1.field1 # same as above

cexpr^!instance1.field1 += cexpr^!instance1.field1 # same as above
```

## Contributing

This project is maintained during my free time, and serves as a tool for a game
engine I am writing after work hours. Contributions are welcome, and will
merge them immediately if they serve to keep the project robust, simple, and
maintainable.

Cheers and happy coding! 🍺
