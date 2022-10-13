import std/macros
import std/os
import std/strformat
import std/strutils

import ./private/pragmas
import ./private/types
import ./private/utils
import ./ctypes

export CClass
export ctypes except cref
export pragmas

proc errorCDecl(sym: NimNode) {.compileTime.} =
  error("invalid C/C++ declaration: " & sym.repr, sym)

proc genDecl[T](
      code: NimNode,
      data: T,
      allowedSections: openArray[string],
      each: proc(node, pragma: NimNode; data: T)): NimNode =
  result = newStmtList()

  for node in code:
    case node.kind
    of nnkConverterDef, nnkProcDef:
      if node.body.kind == nnkEmpty:
        if node.pragma.kind != nnkPragma:
          node.pragma = newNimNode nnkPragma
        each(node, node.pragma, data)
    of nnkLetSection, nnkTypeSection, nnkVarSection:
      for def in node:
        if def[0].kind != nnkPragmaExpr:
          def[0] = nnkPragmaExpr.newTree(def[0], newNimNode nnkPragma)
        each(def, def[0][1], data)
    of nnkIteratorDef, nnkTemplateDef, nnkUsingStmt:
      discard
    elif node.kind in {nnkCall, nnkCommand} and
          $node[0] in allowedSections:
      node[2] = genDecl(node[2], data, allowedSections, each)
    else:
      errorCDecl(node)

    result.add(node)

macro concatHeaderStrings(str1, str2: static string): string =
  let str1 = if not str1.startsWith("<"):
      "#include \"" & str1 & "\""
    else:
      "#include " & str1

  var str2 = str2
  if not str2.startsWith("#include"):
    if not str2.startsWith("<"):
      str2 = "#include \"" & str2 & "\""
    else:
      str2 = "#include " & str2

  result = newLit str2 & "\n" & str1

proc addPathToHeaderNode(node: NimNode, path: string) =
  node[1] = newCall(bindSym"concatHeaderStrings", newLit path, node[1])

proc applyHeaderPragmaNode(pragma: NimNode, path: string) =
  let headerIdx = pragma.pragmaNodeIndexOf"header"

  if headerIdx == -1:
    pragma.add(newColonExpr(ident"header", newLit path))
  else:
    addPathToHeaderNode(pragma[headerIdx], path)

macro concatImportStrings(str1, str2: static string): string =
  if not str2.startsWith('('):
    # add scope iff C code is not parenthesized
    var importParts = split(str2, "::")
    importParts[^1] = str1 & importParts[^1]
    result = newLit join(importParts, "::")
  else:
    result = newLit str2

proc addScopeToPragmaNode(node: NimNode, scope: string) =
  node[1] = newCall(bindSym"concatImportStrings", newLit scope, node[1])

proc applyImportPragmaNode(pragma, node: NimNode; cscope = "") =
  var importCode = "$1"
  if node.kind in {nnkConverterDef, nnkProcDef}:
    case $node.name:
    of "[]":
      if node.params.len == 2:
        importCode = "(*#)"
      elif node.params.len > 2:
        importCode = "(#[@])"
      else:
        errorCDecl(node)
    elif node.params.len > 1:
      var firstParam = node.params[1][0]
      if firstParam.kind == nnkIdent:
        if firstParam.eqIdent("self"):
          importCode = "(#.$1(@))"
        else:
          importCode = "$1(@)"
      else:
        errorCDecl(node)
    else:
      importCode = "$1(@)"

  let importIdx = pragma.pragmaNodeIndexOf"importcpp"

  var pragmaNode: NimNode
  if importIdx == -1:
    pragmaNode = newColonExpr(ident"importcpp", newLit importCode)
    pragma.add(pragmaNode)
  else:
    pragmaNode = pragma[importIdx]
    if pragmaNode.kind == nnkIdent:
      pragmaNode = newColonExpr(pragmaNode, newLit importCode)
      pragma[importIdx] = pragmaNode

  addScopeToPragmaNode(pragmaNode, cscope)

macro csource*(path: static string, code: untyped{nkStmtList}) =
  genDecl(code, path, ["cnamespace", "cscope"]) do (
      node, pragma: NimNode,
      path: string) -> void:
    applyHeaderPragmaNode(pragma, path)
    applyImportPragmaNode(pragma, node)

macro cnamespace*(name: untyped{nkIdent}, code: untyped{nkStmtList}) =
  genDecl(code, $name, ["cnamespace", "csource", "cscope"]) do (
      node, pragma: NimNode,
      name: string) -> void:
    applyImportPragmaNode(pragma, node, &"{name}::")

macro cscope*(Class: type[CClass], body: untyped{nkStmtList}) =
  let classType = Class
  var accessors = newStmtList()

  result = genDecl(body, $classType, ["cscope"]) do (
      node, pragma: NimNode,
      name: string) -> void:
    applyImportPragmaNode(pragma, node, &"{name}::")

    if node.kind == nnkTypeDef:
      var name = node[0][0]
      if name.kind == nnkPostfix:
        node[0][0] = nskType.genSym($name[1])
      else:
        node[0][0] = nskType.genSym($name)

      template getterAst(name, Class, Parent) =
        template name(self: type[Parent]): type = Class

      accessors.add(getAst getterAst(name, node[0][0], classType))
    else:
      error("`cscope` may contain only type declarations; " &
        "use procs to declare static class members", node)

  result.add(accessors)
