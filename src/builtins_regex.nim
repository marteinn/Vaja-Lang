import tables
import sequtils
import nre
from obj import
  Obj,
  ObjType,
  ApplyFunction,
  newBuiltin,
  newBuiltinModule,
  newError,
  newInteger,
  newArray,
  newStr,
  newRegex,
  Env,
  newEnv,
  OBJ_TRUE,
  OBJ_FALSE,
  inspect
import test_utils

proc regexFromString(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTString)

  newRegex(re(arguments[0].strvalue))

proc regexContains(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, regexContains)
  requireArgOfType(arguments, 0, ObjType.OTRegex)
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    regex: Regex = arguments[0].regexValue
    source: string = arguments[1].strvalue
  if contains(source, regex): OBJ_TRUE else: OBJ_FALSE

proc regexFind(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, regexFind)
  requireArgOfType(arguments, 0, ObjType.OTRegex)
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    regex: Regex = arguments[0].regexValue
    source: string = arguments[1].strvalue
    matchRes = match(source, regex)
  if matchRes.isNone:
    return newArray(@[])

  var captures: seq[string] = @[]
  for x in matchRes.get.captures:
    if not x.isSome:
      continue
    captures.add(x.get())

  let captureObjs: seq[Obj] = map(captures, proc(x: string): Obj = newStr(x))
  return newArray(captureObjs)

let functions*: OrderedTable[string, Obj] = {
  "fromString": newBuiltin(builtinFn=regexFromString),
  "contains": newBuiltin(builtinFn=regexContains),
  "find": newBuiltin(builtinFn=regexFind),
}.toOrderedTable

let regexModule*: Obj = newBuiltinModule(moduleFns=functions)
