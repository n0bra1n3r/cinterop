discard """
action: "run"
matrix: "--gc:orc --cc:vcc --passC:-std:c++17 --forceBuild:on --outdir:tests"
target: "c++"
"""

import ./tcinterop/contained
import ./tcinterop/simple

import cinterop/exprs

template should(description: static string, body: untyped) =
  proc test() {.genSym.} = body
  test()

should "access value macro":
  doAssert DEFINE1 == 1

should "access const global":
  doAssert ConstGlobal1 == 1

should "access function":
  let instance = CppClass.init()

  doAssert function1(instance) == 2

should "access undeclared field of nested class":
  let nestedInstance = CppClass.CppNestedClass.init()

  doAssert cexpr[cint]^nestedInstance.nestedField1 == 1

should "compare undeclared field with value":
  let instance = CppClass.init()

  doAssert cexpr[cint]^instance.field1 == 1
  doAssert cexpr[cint]^instance.field1 != 2
  doAssert cexpr[cint]^instance.field1 > 0
  doAssert cexpr[cint]^instance.field1 < 2
  doAssert cexpr[cint]^instance.field1 >= 1
  doAssert cexpr[cint]^instance.field1 >= 0
  doAssert cexpr[cint]^instance.field1 <= 1
  doAssert cexpr[cint]^instance.field1 <= 2

  doAssert 1 == cexpr[cint]^instance.field1
  doAssert 2 != cexpr[cint]^instance.field1
  doAssert 2 > cexpr[cint]^instance.field1
  doAssert 0 < cexpr[cint]^instance.field1
  doAssert 1 >= cexpr[cint]^instance.field1
  doAssert 2 >= cexpr[cint]^instance.field1
  doAssert 1 <= cexpr[cint]^instance.field1
  doAssert 0 <= cexpr[cint]^instance.field1

should "perform binary operations with undeclared field and value":
  let instance = CppClass.init()

  doAssert cexpr[cint]^instance.field2 + 1 == 3
  doAssert cexpr[cint]^instance.field2 - 1 == 1
  doAssert cexpr[cint]^instance.field2 * 2 == 4
  doAssert cexpr[cint]^instance.field2 / 2 == 1

  doAssert 1 + cexpr[cint]^instance.field2 == 3
  doAssert 1 - cexpr[cint]^instance.field2 == -1
  doAssert 2 * cexpr[cint]^instance.field2 == 4
  doAssert 2 / cexpr[cint]^instance.field2 == 1

should "perform `+=` operation on undeclared field with value":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 += 1
  doAssert cexpr[cint]^instance.field2 == 3

should "perform `-=` operation on undeclared field with value":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 -= 1
  doAssert cexpr[cint]^instance.field2 == 1

should "perform `*=` operation on undeclared field with value":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 *= 2
  doAssert cexpr[cint]^instance.field2 == 4

should "perform `/=` operation on undeclared field with value":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 /= 2
  doAssert cexpr[cint]^instance.field2 == 1

should "assign value to undeclared field":
  var instance = CppClass.init()

  cexpr[cint]^instance.field1 = 2
  doAssert cexpr[cint]^instance.field1 == 2

should "mutate undeclared field through var param":
  var instance = CppClass.init()

  proc assign2(i: var cint) = i = 2

  assign2(cexpr[cint]^instance.field1)
  doAssert cexpr[cint]^instance.field1 == 2

should "assign undeclared field to undeclared field":
  var instance = CppClass.init()

  cexpr[cint]^instance.field1 = cexpr[cint]^instance.field2
  doAssert cexpr[cint]^instance.field1 == 2

should "compare undeclared field with undeclared field":
  let instance = CppClass.init()

  doAssert cexpr[cint]^instance.field1 == cexpr[cint]^instance.field1
  doAssert cexpr[cint]^instance.field1 != cexpr[cint]^instance.field2
  doAssert cexpr[cint]^instance.field2 > cexpr[cint]^instance.field1
  doAssert cexpr[cint]^instance.field1 < cexpr[cint]^instance.field2
  doAssert cexpr[cint]^instance.field1 >= cexpr[cint]^instance.field1
  doAssert cexpr[cint]^instance.field2 >= cexpr[cint]^instance.field1
  doAssert cexpr[cint]^instance.field1 <= cexpr[cint]^instance.field1
  doAssert cexpr[cint]^instance.field1 <= cexpr[cint]^instance.field2

should "perform binary operations with undeclared fields":
  let instance = CppClass.init()

  doAssert cexpr[cint]^instance.field2 + cexpr[cint]^instance.field1 == 3
  doAssert cexpr[cint]^instance.field2 - cexpr[cint]^instance.field1 == 1
  doAssert cexpr[cint]^instance.field2 * cexpr[cint]^instance.field1 == 2
  doAssert cexpr[cint]^instance.field2 / cexpr[cint]^instance.field1 == 2

should "perform `+=` operation on undeclared fields":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 += cexpr[cint]^instance.field1
  doAssert cexpr[cint]^instance.field2 == 3

should "perform `-=` operation on undeclared fields":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 -= cexpr[cint]^instance.field1
  doAssert cexpr[cint]^instance.field2 == 1

should "perform `*=` operation on undeclared fields":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 *= cexpr[cint]^instance.field1
  doAssert cexpr[cint]^instance.field2 == 2

should "perform `/=` operation on undeclared fields":
  let instance = CppClass.init()

  cexpr[cint]^instance.field2 /= cexpr[cint]^instance.field1
  doAssert cexpr[cint]^instance.field2 == 2

should "access undeclared pointer field":
  let instance = CppClass.init()

  doAssert cexpr[cint]^instance.field3[] == 3

should "assign value to undeclared pointer field":
  var instance = CppClass.init()

  cexpr[cint]^instance.field3[] = 4
  doAssert cexpr[cint]^instance.field3[] == 4

should "access undeclared array field":
  let instance = CppClass.init()

  doAssert cexpr[cint]^instance.field4[0] == 4

should "assign value to undeclared array field element":
  var instance = CppClass.init()

  cexpr[cint]^instance.field4[0] = 5
  doAssert cexpr[cint]^instance.field4[0] == 5

should "access method":
  let instance = CppClass.init()

  doAssert instance.method1(1) == 2

should "access undeclared method":
  let instance = CppClass.init()

  doAssert cexpr[cint]^instance.method2(1) == 3

should "access converter":
  let instance = CppClass.init()

  doAssert instance.method3() == 3

should "access undeclared method that returns void":
  let instance = CppClass.init()

  var value: cint
  cexpr^instance.method4(value)
  doAssert value == 4

should "access field of a class instance in a nim object":
  var container: Container
  container.subContainer.cppClass = CppClass.init()

  doAssert cexpr[cint]^container.subContainer.cppClass.field2 == 2
  doAssert cexpr[cint]^container.getSubContainer().cppClass.field2 == 2

should "access private field":
  let instance = CppClass.init()

  doAssert instance.field3Value == 3

should "access member of an enum":
  doAssert ord(cauto^CPP_ENUM.MEMBER_1) == 1

should "new and delete class instance":
  let newInstance = cnew CppClass.init()

  doAssert newInstance != nil

  cdelete newInstance

should "allow comparison of `auto` with value":
  let instance = CppClass.init()

  doAssert cauto^instance.field1 == 1

should "allow comparison of `auto` with `auto`":
  let instance = CppClass.init()

  doAssert cauto^instance.field1 < cauto^instance.field2

should "allow assignment of value to `auto`":
  var instance = CppClass.init()

  cauto^instance.field1 = 2
  doAssert cexpr[cint]^instance.field1 == 2

should "allow assignment of `auto` to `auto`":
  var instance = CppClass.init()

  cauto^instance.field1 = cauto^instance.field2
  doAssert cexpr[cint]^instance.field1 == 2

should "perform unary operation on `auto`":
  let instance = CppClass.init()

  doAssert -(cauto^instance.field1) == -1
  doAssert +(cauto^instance.field1) == +1

should "allow storage of `auto` to temporary variable":
  let instance = CppClass.init()

  let value = cauto^instance.field2
  doAssert value == 2

should "mutate `cref` variable":
  var instance = CppClass.init()

  let value {.cref.} = cauto^instance.field1
  cauto^instance.field1 = 2
  doAssert value == 2

should "have bitwise operators for enum flags":
  doAssert ord(not (cauto^CPP_ENUM.MEMBER_1)) == -2
  doAssert ord(cauto^CPP_ENUM.MEMBER_1 and cauto^CPP_ENUM.MEMBER_2) == 0
  doAssert ord(cauto^CPP_ENUM.MEMBER_1 or cauto^CPP_ENUM.MEMBER_2) == 3
  doAssert ord(not (cauto^CPP_ENUM.MEMBER_1) xor cauto^CPP_ENUM.MEMBER_2) == -4
