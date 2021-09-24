discard """
action: "run"
matrix: "--gc:orc --cc:vcc --passC:-std:c++17 --forceBuild:on --outdir:tests"
target: "c++"
"""

import ./tcinterop/contained
import ./tcinterop/simple

import cinterop/exprs

template should(test: static[string], body: untyped) =
  proc run() {.genSym.} = body
  run()

should "access value macro":
  assert DEFINE1 == 1

should "access const global":
  assert ConstGlobal1 == 1

should "access function":
  let instance = CppClass.init()

  assert function1(instance) == 2

should "access undeclared field of nested class":
  let nestedInstance = CppClass.CppNestedClass.init()

  assert cexpr[cint]^nestedInstance.nestedField1 == 1

should "compare undeclared field with value":
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

should "perform binary operations with undeclared field and value":
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field2 + 1 == 3
  assert cexpr[cint]^instance.field2 - 1 == 1
  assert cexpr[cint]^instance.field2 * 2 == 4
  assert cexpr[cint]^instance.field2 / 2 == 1

  assert 1 + cexpr[cint]^instance.field2 == 3
  assert 1 - cexpr[cint]^instance.field2 == -1
  assert 2 * cexpr[cint]^instance.field2 == 4
  assert 2 / cexpr[cint]^instance.field2 == 1

should "perform `+=` operation on undeclared field with value":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 += 1
  assert cexpr[cint]^instance.field2 == 3

should "perform `-=` operation on undeclared field with value":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 -= 1
  assert cexpr[cint]^instance.field2 == 1

should "perform `*=` operation on undeclared field with value":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 *= 2
  assert cexpr[cint]^instance.field2 == 4

should "perform `/=` operation on undeclared field with value":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 /= 2
  assert cexpr[cint]^instance.field2 == 1

should "assign value to undeclared field":
  var instance = CppClass.init()

  cexpr[cint]^instance.field1 = 2
  assert cexpr[cint]^instance.field1 == 2

should "mutate undeclared field through var param":
  var instance = CppClass.init()

  proc assign2(i: var cint) = i = 2

  assign2(cexpr[cint]^instance.field1)
  assert cexpr[cint]^instance.field1 == 2

should "assign undeclared field to undeclared field":
  var instance = CppClass.init()

  cexpr[cint]^instance.field1 = cexpr[cint]^instance.field2
  assert cexpr[cint]^instance.field1 == 2

should "compare undeclared field with undeclared field":
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field1 == cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field1 != cexpr[cint]^instance.field2
  assert cexpr[cint]^instance.field2 > cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field1 < cexpr[cint]^instance.field2
  assert cexpr[cint]^instance.field1 >= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field2 >= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field1 <= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field1 <= cexpr[cint]^instance.field2

should "perform binary operations with undeclared fields":
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field2 + cexpr[cint]^instance.field1 == 3
  assert cexpr[cint]^instance.field2 - cexpr[cint]^instance.field1 == 1
  assert cexpr[cint]^instance.field2 * cexpr[cint]^instance.field1 == 2
  assert cexpr[cint]^instance.field2 / cexpr[cint]^instance.field1 == 2

should "perform `+=` operation on undeclared fields":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 += cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field2 == 3

should "perform `-=` operation on undeclared fields":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 -= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field2 == 1

should "perform `*=` operation on undeclared fields":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 *= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field2 == 2

should "perform `/=` operation on undeclared fields":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 /= cexpr[cint]^instance.field1
  assert cexpr[cint]^instance.field2 == 2

should "access undeclared pointer field":
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field3[] == 3

should "assign value to undeclared pointer field":
  var instance = CppClass.init()

  cexpr[cint]^instance.field3[] = 4
  assert cexpr[cint]^instance.field3[] == 4

should "access undeclared array field":
  let instance = CppClass.init()

  assert cexpr[cint]^instance.field4[0] == 4

should "assign value to undeclared array field element":
  var instance = CppClass.init()

  cexpr[cint]^instance.field4[0] = 5
  assert cexpr[cint]^instance.field4[0] == 5

should "access method":
  let instance = CppClass.init()

  assert instance.method1(1) == 2

should "access undeclared method":
  let instance = CppClass.init()

  assert cexpr[cint]^instance.method2(1) == 3

should "access converter":
  let instance = CppClass.init()

  assert instance.method3() == 3

should "access undeclared method that returns void":
  let instance = CppClass.init()

  var value: cint
  cexpr^instance.method4(value)
  assert value == 4

should "access field of a class instance in a nim object":
  var container: Container
  container.subContainer.cppClass = CppClass.init()

  assert cexpr[cint]^container.subContainer.cppClass.field2 == 2
  assert cexpr[cint]^container.getSubContainer().cppClass.field2 == 2

should "access private field":
  let instance = CppClass.init()

  assert instance.field3Value == 3

should "access member of an enum":
  assert ord(cauto^CPP_ENUM.MEMBER_1) == 1

should "new and delete class instance":
  let newInstance = cnew CppClass.init()

  assert newInstance != nil

  cdelete newInstance

should "allow comparison of `auto` with value":
  let instance = CppClass.init()

  assert cauto^instance.field1 == 1

should "allow comparison of `auto` with `auto`":
  let instance = CppClass.init()

  assert cauto^instance.field1 < cauto^instance.field2

should "allow assignment of value to `auto`":
  var instance = CppClass.init()

  cauto^instance.field1 = 2
  assert cexpr[cint]^instance.field1 == 2

should "allow assignment of `auto` to `auto`":
  var instance = CppClass.init()

  cauto^instance.field1 = cauto^instance.field2
  assert cexpr[cint]^instance.field1 == 2

should "perform unary operation on `auto`":
  let instance = CppClass.init()

  assert -(cauto^instance.field1) == -1
  assert +(cauto^instance.field1) == +1

should "allow storage of `auto` to temporary variable":
  let instance = CppClass.init()

  let value = cauto^instance.field2
  assert value == 2

should "mutate `cref` variable":
  var instance = CppClass.init()

  let value {.cref.} = cauto^instance.field1
  cauto^instance.field1 = 2
  assert value == 2
