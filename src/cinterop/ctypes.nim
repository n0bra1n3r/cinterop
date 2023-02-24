type CRef*[T] {.importcpp:"'0&" bycopy.} = object
type CConst*[T: not CRef] {.importcpp:"const '0" bycopy.} = object

type CArray*[T] = ptr[UncheckedArray[T]]
type CString* = CConst[CArray[char]]

proc toUnqual*[T](obj: CConst[T]|CRef[T]|CRef[CConst[T]]): T {.importcpp:"(#)".}

proc `$`*[T](obj: CConst[T]|CRef[T]|CRef[CConst[T]]): string {.inline.} =
  $obj.toUnqual
