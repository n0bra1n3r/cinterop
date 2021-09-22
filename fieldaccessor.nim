import std/macros

const MemberAccessorImpl = staticRead"fieldaccessor.hpp"

type MemberWrapper[C, R] {.importcpp:"$1<'0, '1>".} = object

macro firstParamType(def: typed): type =
  def.params[1][0].getTypeInst

macro cfield*(def: untyped{nkProcDef}) =
  if def.params.len != 2:
    error("C/C++ field accessor must be associated with a class", def)

  template accessorAst(decl, field, Ret) =
    type B = firstParamType(decl)
    type W = MemberWrapper[B, Ret]

    when not declared(IsMemberAccessorImplEmitted):
      const IsMemberAccessorImplEmitted {.inject used.} = true

      {.emit:["/*TYPESECTION*/\n",
        MemberAccessorImpl].}

    {.emit:["/*TYPESECTION*/\n",
      "template class MakeProxy<", W, ", &", B, "::", astToStr(field), ">;"].}

    proc field*(self: B): auto {.cdecl noinit.} =
      proc impl(Wrapper: type[W], self: auto): Ret
        {.importcpp:"(@.*(Proxy<'*1, '*1>::value))".}

      impl(W, self)

  let decl = copy def
  decl.name = genSym nskProc
  decl.pragma = newEmptyNode()

  result = getAst accessorAst(decl, def.name, def.params[0])
