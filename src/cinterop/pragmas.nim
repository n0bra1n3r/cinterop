import std/macros

import ./ctypes

# This can be used to "unwrap" C++ references so Nim functions can operate on them.
macro cref*(def: untyped{nkLetSection|nkVarSection}) =
  result = def

  let code = if def.kind == nnkLetSection:
      "const $#& $#"
    else:
      "$#& $#"

  let pragma = newColonExpr(ident"codegenDecl", newLit code)

  let pragmaExprOrIdent = result[0][0]
  if pragmaExprOrIdent.kind == nnkPragmaExpr:
    pragmaExprOrIdent[1].add pragma
  else:
    result[0][0] = nnkPragmaExpr.newTree(pragmaExprOrIdent, nnkPragma.newTree pragma)

  proc constToNim[T](obj: CConst[T]): T {.importcpp:"(#)".}
  proc constToNim[T](obj: CConst[CRef[T]]): T {.importcpp:"(#)".}
  template constToNim[T](obj: T): T = obj
  proc refToNim[T](obj: CRef[T]): T {.importcpp:"(#)".}
  template refToNim[T](obj: T): T = obj

  if def.kind == nnkLetSection:
    result[0][2] = newCall(bindSym"constToNim", result[0][2])
  else:
    result[0][2] = newCall(bindSym"refToNim", result[0][2])
