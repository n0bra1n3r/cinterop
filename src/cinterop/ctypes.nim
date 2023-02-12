type CConst*[T] {.importcpp:"const '0" bycopy.} = object
type CRef*[T: not CConst] {.importcpp:"'0&" bycopy.} = object

type CArray*[T] = ptr[UncheckedArray[T]]
type CString* = CConst[CArray[char]]

proc toUnqual*[T](obj: CConst[T]|CRef[T]|CConst[CRef[T]]): T {.importcpp:"(#)".}
