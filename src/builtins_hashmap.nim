import tables
from obj import
  Obj,
  ObjType,
  ApplyFunction,
  newBuiltin,
  newHashMap,
  newStr,
  newError,
  newInteger,
  newArray,
  Env,
  newEnv,
  NIL,
  inspect,
  inspectEnv
import test_utils

proc hashMapLen(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)

  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTHashMap:
    return newError(errorMsg="Argument arr was " & $(obj.objType) & ", want HashMap")
  return newInteger(intValue=len(obj.hashMapElements))

proc hashMapMap(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 2)

  let
    fn: Obj = arguments[0]
    source: Obj = arguments[1]
  if source.objType != ObjType.OTHashMap:
    return newError(errorMsg="Argument hashMap was " & $(fn.objType) & ", want HashMap")
  if fn.objType != ObjType.OTFunction and fn.objType != ObjType.OTFunctionGroup:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")

  var mapped: OrderedTable[string, Obj] = initOrderedTable[string, Obj]()
  for key, val in source.hashMapElements:
    var env: Env = newEnv()
    mapped[key] = applyFn(fn, @[newStr(strValue=key), val], env)
  return newHashMap(hashMapElements=mapped)

proc hashMapFilter(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 2)

  let
    fn: Obj = arguments[0]
    source: Obj = arguments[1]
  if source.objType != ObjType.OTHashMap:
    return newError(errorMsg="Argument hashMap was " & $(fn.objType) & ", want HashMap")
  if fn.objType != ObjType.OTFunction and fn.objType != ObjType.OTFunctionGroup:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")

  var filtered: OrderedTable[string, Obj] = initOrderedTable[string, Obj]()
  for key, val in source.hashMapElements:
    var env: Env = newEnv()
    if applyFn(fn, @[newStr(strValue=key), val], env).boolValue:
      filtered[key] = val
  return newHashMap(hashMapElements=filtered)

proc hashMapReduce(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 3)

  let
    fn: Obj = arguments[0]
    initial: Obj = arguments[1]
    source: Obj = arguments[2]

  if fn.objType != ObjType.OTFunction and fn.objType != ObjType.OTFunctionGroup:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")
  if source.objType != ObjType.OTHashMap:
    return newError(errorMsg="Argument source was " & $(source.objType) & ", want HashMap")

  result = initial
  for key, curr in source.hashMapElements:
    var env: Env = newEnv()
    result = applyFn(fn, @[result, curr, newStr(strValue=key)], env)

proc hashMapToArray(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)

  let source: Obj = arguments[0]
  if source.objType != ObjType.OTHashMap:
    return newError(errorMsg="Argument arr was " & $(source.objType) & ", want HashMap")

  var arr: seq[Obj] = @[]
  for key, val in source.hashMapElements:
    arr.add(
      newArray(arrayElements= @[newStr(strValue=key), val])
    )

  return newArray(arrayElements=arr)

proc hashMapInsert(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 3)

  let
    keyObj: Obj = arguments[0]
    valObj: Obj = arguments[1]
    source: Obj = arguments[2]

  if keyObj.objType != ObjType.OTFunction and keyObj.objType != ObjType.OTString:
    return newError(errorMsg="Argument fn was " & $(keyObj.objType) & ", want String")
  if source.objType != ObjType.OTHashMap:
    return newError(errorMsg="Argument source was " & $(source.objType) & ", want HashMap")

  var
    hashMapElements = source.hashMapElements
  hashMapElements[keyObj.strValue] = valObj
  return newHashMap(hashMapElements=hashMapElements)

proc hashMapRemove(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 2)

  let
    keyObj: Obj = arguments[0]
    source: Obj = arguments[1]

  if keyObj.objType != ObjType.OTFunction and keyObj.objType != ObjType.OTString:
    return newError(errorMsg="Argument fn was " & $(keyObj.objType) & ", want String")
  if source.objType != ObjType.OTHashMap:
    return newError(errorMsg="Argument source was " & $(source.objType) & ", want HashMap")

  var
    hashMapElements = source.hashMapElements
  hashMapElements.del(keyObj.strValue)
  return newHashMap(hashMapElements=hashMapElements)

proc hashMapUpdate(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 3)

  let
    keyObj: Obj = arguments[0]
    valObj: Obj = arguments[1]
    source: Obj = arguments[2]

  if keyObj.objType != ObjType.OTFunction and keyObj.objType != ObjType.OTString:
    return newError(errorMsg="Argument fn was " & $(keyObj.objType) & ", want String")
  if source.objType != ObjType.OTHashMap:
    return newError(errorMsg="Argument source was " & $(source.objType) & ", want HashMap")

  if not contains(source.hashMapElements, keyObj.strValue):
    return newError(errorMsg="Key " & $(keyObj.strValue) & " not found")

  var
    hashMapElements = source.hashMapElements
  hashMapElements[keyObj.strValue] = valObj
  return newHashMap(hashMapElements=hashMapElements)

proc hashMapEmpty(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 0)

  return newHashMap(
    hashMapElements=initOrderedTable[string, Obj]()
  )

let functions*: OrderedTable[string, Obj] = {
  "len": newBuiltin(builtinFn=hashMapLen),
  "map": newBuiltin(builtinFn=hashMapMap),
  "filter": newBuiltin(builtinFn=hashMapFilter),
  "reduce": newBuiltin(builtinFn=hashMapReduce),
  "toArray": newBuiltin(builtinFn=hashMapToArray),
  "insert": newBuiltin(builtinFn=hashMapInsert),
  "remove": newBuiltin(builtinFn=hashMapRemove),
  "update": newBuiltin(builtinFn=hashMapUpdate),
  "empty": newBuiltin(builtinFn=hashMapEmpty),
  # TODO: Implement keys
  # TODO: Implement values
  # TODO: Implement fromArray
}.toOrderedTable

let hashMapModule*: Obj = newHashMap(hashMapElements=functions)
