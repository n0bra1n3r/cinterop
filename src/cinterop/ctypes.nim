import std/macros 

type CConst*[T] {.importcpp:"const '0" bycopy.} = object
type CRef*[T: not CConst] {.importcpp:"'0&" bycopy.} = object

type CArray*[T] = ptr[UncheckedArray[T]]
type CString* = CConst[CArray[char]]

# This can be used to "unwrap" C++ references so Nim functions can operate on them.
when (NimMajor, NimMinor, NimPatch) < (1, 7, 1):
  # BUG: This macro does not allow `var` variables to be mutated
  # TODO: Remove this when https://github.com/nim-lang/RFCs/issues/220 is in stable
  macro cref*(name: untyped{nkIdent|nkAccQuoted}, Type, value: untyped) =
    if value.kind == nnkEmpty:
      error("C/C++ forwarding reference must be initialized", name)

    template variableAst(name, value) =
      let name {.codegenDecl:"const $#& $#".} = value

    template variableAst(name, Type, value) =
      let name {.codegenDecl:"const $#& $#".}: Type = value

    result = if Type.kind == nnkNilLit:
        getAst variableAst(name, value)
      else:
        getAst variableAst(name, Type, value)
else:
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
