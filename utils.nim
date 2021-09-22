import std/enumerate
import std/macros

proc pragmaNodeIndexOf*(pragma: NimNode, name: string): int =
  result = -1
  for i, node in enumerate(pragma.children):
    if node.kind == nnkIdent:
      if node.eqIdent(name):
        result = i
        break
    elif node.kind == nnkExprColonExpr:
      if $node[0] == name:
        result = i
        break
