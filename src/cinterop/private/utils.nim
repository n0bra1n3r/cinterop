import std/enumerate
import std/macros

proc pragmaNodeIndexOf*(pragma: NimNode, name: string): int =
  result = -1
  for i, node in enumerate pragma:
    if node.kind == nnkIdent:
      if node.eqIdent(name):
        result = i
        break
    elif node.kind == nnkExprColonExpr:
      if $node[0] == name:
        result = i
        break

proc searchNodeKind*(node: NimNode, kind: NimNodeKind): NimNode =
  if node.kind == kind:
    result = node
  elif node.kind notin AtomicNodes:
    for child in node:
      result = child.searchNodeKind(kind)
      if result != nil:
        break

macro hasField*(base: typed, field: untyped): bool =
  result = newLit false
  for fieldNode in base.getTypeImpl[2]:
    if fieldNode[0].eqIdent(field):
      result = newLit true
      break

template isCallable*(base, field: untyped, args: varargs[untyped]): bool =
  when declared(field):
    # TODO: Avoid using `compiles`
    when varargsLen(args) > 0:
      compiles(field(base, args))
    else:
      compiles(field(base))
  else:
    false

macro getPragmaContainerType*(Type: type): type =
  result = Type
  if result.kind != nnkSym:
    if result.typeKind == ntyTypeDesc and
        result.kind notin {nnkStmtListExpr, nnkStmtListType}:
      result = result[1].getTypeInst
      result = getAst getPragmaContainerType(result)
    else:
      result = result[0]
