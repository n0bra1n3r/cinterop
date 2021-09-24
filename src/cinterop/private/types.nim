{.pragma:cabstract importcpp:"$1_should_never_be_generated" inheritable.}

type CAuto* {.importcpp:"auto".} = object

type CClass* {.cabstract.} = object
type CEnum* {.cabstract.} = object

type CObject* = CAuto or CClass
type CAny* = CEnum or CObject

type CArray*[T] = ptr[UncheckedArray[T]]
type CConst*[T] {.importcpp:"const '0" bycopy.} = object
type CRef*[T] {.importcpp:"'0&" bycopy.} = object
type CString* = CConst[CArray[char]]
