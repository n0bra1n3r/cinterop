import std/macros
import std/strutils

import ./pragmas
import ./types
import ./utils

export CArray

proc init*[T: CClass](Class: type[T]): T
  {.importcpp:"'*1(@)" varargs constructor.}
proc init*[T: CEnum](Enum: type[T], value: cint): T
  {.importcpp:"'*1(@)" constructor.}

proc cnew*[T](instance: T): ptr[T] {.importcpp:"(new #)".}
# useful for overriding `cnew` in custom interop modules
# WARNING: This does not call the C++ constructor!
proc cnew*(T: type): ptr[T] {.importcpp:"(('0) ::operator new (sizeof('*1)))".}

proc cdelete*(pt: ptr) {.importcpp:"(delete #)".}

macro errorConstruct(ctor: CClass{nkObjConstr}) =
  error("invalid C/C++ object construction; use `" &
    repr(ctor[0]) & ".init`", ctor)

macro errorConstruct(sym: typed) =
  error("this code is incompatible with term-rewriting macros; " &
    "disable init check for C/C++ interop or refactor this code", sym)

when not defined(CINTEROP_DISABLE_INIT_CHECK):
  # disallow normal constructors to avoid backend compile errors
  # BUG: These TRMs match `{.emit:"".}`; `{.emit:[].}` must be used instead
  template initCheck*{ctor}(ctor: CClass{nkObjConstr}) = errorConstruct(ctor)
  template initCheck*{ctor}(ctor: CEnum{nkObjConstr}) = errorConstruct(ctor)

converter toCFloat*(value: float): cfloat {.importcpp:"(#)".}
converter toCFloat*(value: int): cfloat {.importcpp:"(#)".}
converter toCInt*(value: int): cint {.importcpp:"(#)".}

converter toCAuto*[T: not string](value: T): CAuto {.importcpp:"(#)".}
converter toCAuto*(value: string): CAuto
  {.inline noinit codegenDecl:"N_INLINE(NCSTRING, $2)$3".} =
  proc impl(): CAuto
    {.importcpp:"(#)" varargs.}
  # required for implicit conversion from Nim strings to C strings
  result = impl(value)

converter toCConst*[T: not string](value: T): CConst[T] {.importcpp:"(#)".}
converter toCConst*(value: string): CConst[string] {.inline noinit.} =
  proc impl(): CConst[string]
    {.importcpp:"(#)" varargs.}
  result = impl(value)

converter toCString*(value: string): CString {.inline noinit.} =
  proc impl(): CString
    {.importcpp:"(#)" varargs.}
  result = impl(value)

converter toCRef*[T: not string](value: T): CRef[T] {.importcpp:"(#)".}
converter toCRef*(value: string): CRef[string] {.inline noinit.} =
  proc impl(): CRef[string]
    {.importcpp:"(#)" varargs.}
  result = impl(value)

macro getPragmaContainerType(Type: type): type =
  result = Type
  if result.kind != nnkSym:
    if result.typeKind == ntyTypeDesc and
        result.kind != nnkStmtListType:
      result = result[1].getTypeInst
      result = getAst getPragmaContainerType(result)
    else:
      result = result[0]

macro getTypeCGenCodeString(Type: type): string =
  result = getAst getCustomPragmaVal(Type, cgen)
  if not startsWith($result, '(') and not startsWith($result, "\'*1"):
    let pragma = Type.getImpl[0][1]
    let pragmaIndex = pragma.pragmaNodeIndexOf"cgen"
    let pragmaNode = pragma[pragmaIndex]
    warning("may not generate correct C++ code; " &
      "consider prepending \"'*1\" to specify scope", pragmaNode)

# `'1` forces `#include` to always be generated for the first parameter of a
# cinterop-generated proc
const cgenCodeTag = "/*'1*/"

template getCCode(Type: type, default: string): string =
  when hasCustomPragma(getPragmaContainerType(Type), cgen):
    cgenCodeTag & getTypeCGenCodeString(getPragmaContainerType(Type))
  else:
    cgenCodeTag & default

template getCCode[T](base: T, default: string): string =
  getCCode(type[T], default)

type CAccessKind = enum Val, Var

macro cAccess(
        ccode: static[string],
        accessKind: static[CAccessKind],
        base: auto or type,
        field: untyped,
        Any: type,
        args: varargs[untyped]): auto =
  template valFieldAst(ccode, base, field, Any) =
    proc field(self: auto or type): Any
      {.importcpp:getCCode(base, ccode) varargs.}

  template varFieldAst(ccode, base, field, Any) =
    proc field(self: auto or type): var Any
      {.importcpp:getCCode(base, ccode) varargs.}

  var fieldName: string

  if field.kind == nnkAccQuoted:
    for node in field:
      fieldName &= $node
  else:
    fieldName = $field

  let field = nskProc.genSym(fieldName)
  let returnType = Any.getTypeInst[1] # needed to show type in error messages

  let cgen = case accessKind
    of Val: getAst valFieldAst(ccode, base, field, returnType)
    of Var: getAst varFieldAst(ccode, base, field, returnType)

  let call = newCall(field, base)
  for arg in args: call.add(arg)

  result = newStmtList(cgen, call)

template isCallable(base, field: untyped, args: varargs[untyped]): bool =
  when declared(field):
    # TODO: Avoid using `compiles`
    when varargsLen(args) > 0:
      compiles(field(base, args))
    else:
      compiles(field(base))
  else:
    false

macro hasField(base: CObject, field: untyped): bool =
  result = newLit false
  for fieldNode in base.getTypeImpl[2]:
    if fieldNode[0].eqIdent(field):
      result = newLit true
      break

template isVar(base: var auto): bool = true
template isVar(base: auto or type): bool = false

template dotImpl(Any: type, field: untyped, base: CObject): auto =
  when hasField(base, field) or isCallable(base, field):
    base . field
  elif isVar(base) and Any isnot void:
    cAccess("(#.$1)", Var, base, field, Any)
  else:
    cAccess("(#.$1)", Val, base, field, Any)

template dotImpl[T: CObject](Any: type, field: untyped, Class: type[T]): auto =
  when isCallable(Class, field):
    Class . field
  else:
    cAccess("'*1::$1", Val, Class, field, Any)

template dotImpl[T: CEnum](Any: type, field: untyped, Enum: type[T]): auto =
  when isCallable(Enum, field):
    Enum . field
  else:
    cAccess("'*1::$1", Val, Enum, field, Enum)

template dotImpl(Any: type, field: untyped, base: not CObject): auto =
  base . field

template callImpl(
          Any: type,
          field: untyped,
          base: CObject,
          args: varargs[untyped]): auto =
  when hasField(base, field) or isCallable(base, field, args):
    unpackVarargs(base . field, args)
  elif isVar(base) and Any isnot void:
    cAccess("(#.$1(@))", Var, base, field, Any, args)
  else:
    cAccess("(#.$1(@))", Val, base, field, Any, args)

template callImpl[T: CObject](
          Any: type,
          field: untyped,
          Class: type[T],
          args: varargs[untyped]): auto =
  when isCallable(Class, field, args):
    unpackVarargs(Class . field, args)
  else:
    cAccess("'*1::$1(@)", Val, Class, field, Any, args)

template callImpl(
          Any: type,
          field: untyped,
          base: not CObject,
          args: varargs[untyped]): auto =
  unpackVarargs(base . field, args)

template derefImpl(Any: type, base: CObject, args: varargs[untyped]): auto =
  when isCallable(base, `[]`, args):
    when varargsLen(args) > 0:
      `[]`(base, args)
    else:
      `[]`(base)
  elif isVar(base):
    when varargsLen(args) > 0:
      cAccess("(#[@])", Var, base, `[]`, Any, args)
    else:
      cAccess("(*#)", Var, base, `[]`, Any)
  else:
    when varargsLen(args) > 0:
      cAccess("(#[@])", Val, base, `[]`, Any, args)
    else:
      cAccess("(*#)", Var, base, `[]`, Any)

template derefImpl(Any: type, base: not CObject, args: varargs[untyped]): auto =
  when varargsLen(args) > 0:
    `[]`(base, args)
  else:
    `[]`(base)

macro isCCall(node: typed): bool =
  var node = node
  while node.kind in {nnkHiddenDeref, nnkStmtList, nnkStmtListExpr}:
    node = node[0]

  if node.kind != nnkProcDef:
    result = newLit false
  else:
    let index = node.pragma.pragmaNodeIndexOf"importcpp"
    if index == -1:
      result = newLit false
    else:
      let node = node.pragma[index]
      if node.kind != nnkExprColonExpr:
        result = newLit false
      else:
        result = newLit startsWith($node[1], cgenCodeTag)

proc searchNodeKind(node: NimNode, kind: NimNodeKind): NimNode =
  if node.kind == kind:
    result = node
  elif node.kind notin AtomicNodes:
    for child in node:
      result = searchNodeKind(child, kind)
      if result != nil:
        break

macro warnCExpr(res: typed) =
  warning("did not generate C/C++ expression; " &
    "you may not need `cexpr` here", searchNodeKind(res, nnkSym))

template toResult[T](res: T): auto = res
# always return the enum type for CEnums
template toResult[T](res: CEnum): auto = res

template cResult[T](Any: type[T], res: auto): auto =
  when not isCCall(res):
    warnCExpr(res)
  # required to avoid AST nodes for implicit conversions (e.g. nnkHiddenConv)
  # from interfering with the `isCCall` logic
  toResult[T](res)

proc genCExpr(code, returnType, CAuto: NimNode; isResult = false): NimNode =
  case code.kind
  of AtomicNodes:
    result = code
  of nnkBracketExpr:
    result = newCall(bindSym"derefImpl", returnType)
    for arg in code:
      result.add(genCExpr(arg, CAuto, CAuto))
  of nnkCall:
    let node = code[0]
    if node.len == 2 and node[1].kind in {nnkAccQuoted, nnkIdent}:
      # TODO: Support C++ member function templates
      result = newCall(
        bindSym"callImpl",
        returnType,
        node[1],
        genCExpr(node[0], CAuto, CAuto))
    elif node.eqIdent("[]"):
      result = newCall(bindSym"derefImpl", returnType)
    else:
      result = newCall(node)

    if code.len > 1:
      for arg in code[1..^1]:
        result.add(genCExpr(arg, CAuto, CAuto))
  of nnkDotExpr:
    result = newCall(
      bindSym"dotImpl",
      returnType,
      code[1],
      genCExpr(code[0], CAuto, CAuto))
  else:
    result = newNimNode code.kind
    for node in code:
      result.add(genCExpr(node, CAuto, CAuto))

  # add a check to make sure the result type is expected
  if isResult: result = newCall(bindSym"cResult", returnType, result)

macro cexprImpl(code: untyped, Any: type, CAuto = CAuto): auto =
  genCExpr(code, Any, CAuto, true)

# used to create an overload for the `^` operator so it does not conflict with
# other modules
type cexpr*[T] = distinct object
type cauto* = distinct object

template cexprType[T](Expr: type[cexpr[T]]): type[T] = T

macro checkTypeSize(Expr: type[cexpr], Type: type) =
  warning("type size may be unexpected; " &
    "did you mean `c" & $Type.getType[1] & "`?", Expr)

template `^`*(Expr: type[cexpr], code: untyped{~nkStmtList}): auto =
  when cexpr is Expr:
    cexprImpl(code, void)
  else:
    type Type = cexprType(Expr)

    when Type is (float or int):
      checkTypeSize(Expr, Type)

    cexprImpl(code, Type)

template `^`*(Expr: type[cauto], code: untyped{~nkStmtList}): auto =
  cexprImpl(code, CAuto)

# BUG: This macro does not allow `var` variables to be mutated
# TODO: Fix this when https://github.com/nim-lang/RFCs/issues/220 is done
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

proc `==`*(lhs, rhs: CAny): bool {.importcpp:"(# $1 #)".}
proc `!=`*(lhs, rhs: CAny): bool {.importcpp:"(# $1 #)".}

proc `<`*(lhs, rhs: CObject): bool {.importcpp:"(# $1 #)".}
proc `>`*(lhs, rhs: CObject): bool {.importcpp:"(# $1 #)".}
proc `<=`*(lhs, rhs: CObject): bool {.importcpp:"(# $1 #)".}
proc `>=`*(lhs, rhs: CObject): bool {.importcpp:"(# $1 #)".}

proc `+`*(lhs, rhs: CObject): CAuto {.importcpp:"(# $1 #)".}
proc `-`*(lhs, rhs: CObject): CAuto {.importcpp:"(# $1 #)".}
proc `*`*(lhs, rhs: CObject): CAuto {.importcpp:"(# $1 #)".}
proc `/`*(lhs, rhs: CObject): CAuto {.importcpp:"(# $1 #)".}
proc `+=` *(lhs, rhs: CObject) {.importcpp:"(# $1 #)".}
proc `-=` *(lhs, rhs: CObject) {.importcpp:"(# $1 #)".}
proc `*=` *(lhs, rhs: CObject) {.importcpp:"(# $1 #)".}
proc `/=` *(lhs, rhs: CObject) {.importcpp:"(# $1 #)".}

proc `-`*(value: CObject): CAuto {.importcpp:"($1#)".}
proc `+`*(value: CObject): CAuto {.importcpp:"($1#)".}

proc ord*(value: CEnum): cint {.importcpp:"(static_cast<'0>(#))".}

proc `$`*[T: CEnum](value: T): string = $value.ord
