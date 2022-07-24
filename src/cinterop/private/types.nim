{.pragma:cabstract importcpp:"$1_should_never_be_generated" inheritable.}

type CAuto* {.importcpp:"auto".} = object

when (NimMajor, NimMinor, NimPatch) < (1, 7, 1):
  type CClass* {.cabstract completeStruct.} = object
  type CEnum* {.cabstract completeStruct.} = object
else:
  type CClass* {.cabstract.} = object
  type CEnum* {.cabstract.} = object

type CObject* = CAuto or CClass
type CAny* = CEnum or CObject
