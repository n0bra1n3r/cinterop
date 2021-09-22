import ./simple

type
  Container* = object
    subContainer*: SubContainer

  SubContainer* = object
    cppClass*: CppClass

when false:
  # BUG: Causes linker error with globals declared in simple.cpp if not inlined
  proc getSubContainer*(self: Container): SubContainer =
    self.subContainer
else:
  proc getSubContainer*(self: Container): SubContainer {.inline.} =
    self.subContainer
