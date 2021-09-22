discard """
action: "run"
matrix: "--gc:orc --cc:vcc --passC:-std:c++17 --forceBuild:on --outdir:tests"
target: "c++"
"""

import ./tcinterop/contained
import ./tcinterop/simple

import ../exprs

block: # access value macro
  assert DEFINE1 == 1

block: # access const global
  assert ConstGlobal1 == 1

block: # access function
  let instance = CppClass.init()

  assert function1(instance) == 2

block: # access undeclared field of nested class
  let nestedInstance = CppClass.CppNestedClass.init()

  assert cexpr[cint]^nestedInstance.nestedField1 == 1

block: # compare undeclared field with value
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field1 == 1
  assert cexpr[cint]^instance.field1 != 2
  assert cexpr[cint]^instance.field1 > 0
  assert cexpr[cint]^instance.field1 < 2
  assert cexpr[cint]^instance.field1 >= 1
  assert cexpr[cint]^instance.field1 >= 0
  assert cexpr[cint]^instance.field1 <= 1
  assert cexpr[cint]^instance.field1 <= 2

  assert 1 == cexpr[cint]^instance.field1
  assert 2 != cexpr[cint]^instance.field1
  assert 2 > cexpr[cint]^instance.field1
  assert 0 < cexpr[cint]^instance.field1
  assert 1 >= cexpr[cint]^instance.field1
  assert 2 >= cexpr[cint]^instance.field1
  assert 1 <= cexpr[cint]^instance.field1
  assert 0 <= cexpr[cint]^instance.field1

block: # perform binary operations with undeclared field and value
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field2 + 1 == 3
  assert cexpr[cint]^instance.field2 - 1 == 1
  assert cexpr[cint]^instance.field2 * 2 == 4
  assert cexpr[cint]^instance.field2 / 2 == 1

  assert (1 + cexpr[cint]^instance.field2) == 3
  assert (1 - cexpr[cint]^instance.field2) == -1
  assert (2 * cexpr[cint]^instance.field2) == 4
  assert (2 / cexpr[cint]^instance.field2) == 1

block: # perform `+=` operation on undeclared field with value
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 += 1
  assert cexpr[cint]^instance.field2 == 3

block: # perform `-=` operation on undeclared field with value
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 -= 1
  assert cexpr[cint]^instance.field2 == 1

block: # perform `*=` operation on undeclared field with value
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 *= 2
  assert cexpr[cint]^instance.field2 == 4

block: # perform `/=` operation on undeclared field with value
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 /= 2
  assert cexpr[cint]^instance.field2 == 1

block: # assign value to undeclared field
  var instance = CppClass.init()

  cexpr[cint]^instance.field1 = 2
  assert cexpr[cint]^instance.field1 == 2

block: # mutate undeclared field through var param
  var instance = CppClass.init()

  proc assign2(i: var cint) = i = 2

  assign2(cexpr[cint]^instance.field1)
  assert cexpr[cint]^instance.field1 == 2

block: # assign undeclared field to undeclared field
  var instance = CppClass.init()

  cexpr[cint]^instance.field1 = cexpr[cint]^instance.field2
  assert cexpr[cint]^instance.field1 == 2

block: # compare undeclared field with undeclared field
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field1 == cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field1 != cexpr[cint]^instance.field2
  assert cexpr[cint]^instance.field2 > cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field1 < cexpr[cint]^instance.field2
  assert cexpr[cint]^instance.field1 >= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field2 >= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field1 <= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field1 <= cexpr[cint]^instance.field2

block: # perform binary operations with undeclared fields
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field2 + cexpr[cint]^instance.field1 == 3
  assert cexpr[cint]^instance.field2 - cexpr[cint]^instance.field1 == 1
  assert cexpr[cint]^instance.field2 * cexpr[cint]^instance.field1 == 2
  assert cexpr[cint]^instance.field2 / cexpr[cint]^instance.field1 == 2

block: # perform `+=` operation on undeclared fields
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 += cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field2 == 3

block: # perform `-=` operation on undeclared fields
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 -= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field2 == 1

block: # perform `*=` operation on undeclared fields
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 *= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field2 == 2

block: # perform `/=` operation on undeclared fields
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 /= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field2 == 2

block: # access undeclared pointer field
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field3[] == 3

block: # assign value to undeclared pointer field
  var instance = CppClass.init()

  cexpr[cint]^instance.field3[] = 4
  assert cexpr[cint]^instance.field3[] == 4

block: # access undeclared array field
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field4[0] == 4

block: # assign value to undeclared array field element
  var instance = CppClass.init()

  cexpr[cint]^instance.field4[0] = 5
  assert cexpr[cint]^instance.field4[0] == 5

block: # access method
  let instance = CppClass.init()

  assert instance.method1(1) == 2

block: # access undeclared method
  let instance = CppClass.init()

  assert cexpr[cint]^instance.method2(1) == 3

block: # access converter
  let instance = CppClass.init()

  assert instance.method3() == 3

block: # access undeclared method that returns void
  let instance = CppClass.init()

  var value: cint
  cexpr^instance.method4(value)
  assert value == 4

block: # access field of a class instance in a nim object
  when false:
    # BUG: This generates bad C++ initialization code
    let container = Container()
  else:
    var container: Container

  assert cexpr[cint]^container.subContainer.cppClass.field2 == 2
  assert cexpr[cint]^container.getSubContainer().cppClass.field2 == 2

block: # access private field
  let instance = CppClass.init()

  assert instance.field3Value == 3

block: # access member of an enum
  assert ord(cauto^CPP_ENUM.MEMBER_1) == 1

block: # new and delete class instance
  let newInstance = cnew CppClass.init()

  assert newInstance != nil

  cdelete newInstance

block: # allow comparison of `auto` with value
  let instance = CppClass.init()

  assert cauto^instance.field1 == 1

block: # allow comparison of `auto` with `auto`
  let instance = CppClass.init()

  assert cauto^instance.field1 < cauto^instance.field2

block: # allow assignment of value to `auto`
  var instance = CppClass.init()

  cauto^instance.field1 = 2
  assert cexpr[cint]^instance.field1 == 2

block: # allow assignment of `auto` to `auto`
  var instance = CppClass.init()

  cauto^instance.field1 = cauto^instance.field2
  assert cexpr[cint]^instance.field1 == 2

block: # perform unary operation on `auto`
  let instance = CppClass.init()

  assert -(cauto^instance.field1) == -1
  assert +(cauto^instance.field1) == +1

when false:
  # BUG: These tests don't work because auto variables are not initialized in
  # the generated code

  block: # allow storage of `auto` to temporary variable
    let instance = CppClass.init()

    let value = cauto^instance.field2
    assert value == 2

  block: # should mutate `cref` variable
    var instance = CppClass.init()

    let value {.cref.} = cauto^instance.field1
    cauto^instance.field1 = 2
    assert value == 2
