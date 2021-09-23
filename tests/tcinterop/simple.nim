import std/os

import cinterop

const CurrentDir = currentSourcePath.parentDir

csource CurrentDir & "/simple.hpp":
  let DEFINE1*: cint # c macros *must* be declared outside of namespaces

  cnamespace Simple:
    let ConstGlobal1*: cint

    type CppClass* = object of CClass

    cscope CppClass:
      type CppNestedClass* = object of CClass

    type CPP_ENUM* {.cgen:"'*1_$1".} = object of CEnum

    proc method1*(self: CppClass, arg: cint): cint
    converter method3*(self: CppClass): cint
    proc field3Value*(self: CppClass): cint {.cfield.}

    proc function1*(instance: CppClass): cint
