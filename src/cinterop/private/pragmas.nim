import std/macros

import ./types
import ./utils

template cgen*(ccode: string) {.pragma.}

macro cenum*(def: untyped{nkTypeDef}) =
  var name = def[0][0]
  if name.kind == nnkPostfix:
    name = name[1]

  if def[1].kind == nnkGenericParams:
    error("invalid C/C++ declaration: " &
          name.repr & " cannot be generic", name)
  if def[^1][1].kind == nnkOfInherit:
    error("invalid C/C++ declaration: " &
          name.repr & " cannot inherit", name)
  if def[^1][^1].kind == nnkRecList:
    error("invalid C/C++ declaration: " &
          name.repr & " cannot contain fields", name)

  result = def

  let cgenIndex = result[0][^1].pragmaNodeIndexOf"cgen"
  if cgenIndex == -1:
    result[0][^1].add(newColonExpr(bindSym"cgen", newLit"('*1_$1)"))

  result[0][^1].add(ident"final")
  result[^1][1] = nnkOfInherit.newTree(bindSym"CEnum")
