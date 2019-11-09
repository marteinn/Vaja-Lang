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
  OBJ_TRUE,
  OBJ_FALSE,
  inspect,
  inspectEnv
import test_utils

proc hashMapLen(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTHashMap)

  let obj: Obj = arguments[0]
  return newInteger(intValue=len(obj.hashMapElements))

proc hashMapMap(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, hashMapMap)
  requireArgOfTypes(arguments, 0, @[
    ObjType.OTFunction, ObjType.OTFunctionGroup, ObjType.OTBuiltin
  ])
  requireArgOfType(arguments, 1, ObjType.OTHashMap)

  let
    fn: Obj = arguments[0]
    source: Obj = arguments[1]
  var mapped: OrderedTable[string, Obj] = initOrderedTable[string, Obj]()
  for key, val in source.hashMapElements:
    var env: Env = newEnv()
    mapped[key] = applyFn(fn, @[newStr(strValue=key), val], env)
  return newHashMap(hashMapElements=mapped)

proc hashMapFilter(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, hashMapFilter)
  requireArgOfTypes(arguments, 0, @[
    ObjType.OTFunction, ObjType.OTFunctionGroup, ObjType.OTBuiltin
  ])
  requireArgOfType(arguments, 1, ObjType.OTHashMap)

  let
    fn: Obj = arguments[0]
    source: Obj = arguments[1]
  var filtered: OrderedTable[string, Obj] = initOrderedTable[string, Obj]()
  for key, val in source.hashMapElements:
    var env: Env = newEnv()
    if applyFn(fn, @[newStr(strValue=key), val], env).boolValue:
      filtered[key] = val
  return newHashMap(hashMapElements=filtered)

proc hashMapReduce(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 3, hashMapReduce)
  requireNumArgs(arguments, 3)
  requireArgOfTypes(arguments, 0, @[
    ObjType.OTFunction, ObjType.OTFunctionGroup, ObjType.OTBuiltin
  ])
  requireArgOfType(arguments, 2, ObjType.OTHashMap)

  let
    fn: Obj = arguments[0]
    initial: Obj = arguments[1]
    source: Obj = arguments[2]
  result = initial
  for key, curr in source.hashMapElements:
    var env: Env = newEnv()
    result = applyFn(fn, @[result, curr, newStr(strValue=key)], env)

proc hashMapToArray(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTHashMap)

  let source: Obj = arguments[0]
  var arr: seq[Obj] = @[]
  for key, val in source.hashMapElements:
    arr.add(
      newArray(arrayElements= @[newStr(strValue=key), val])
    )

  return newArray(arrayElements=arr)

proc hashMapInsert(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 3, hashMapInsert)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 2, ObjType.OTHashMap)

  let
    keyObj: Obj = arguments[0]
    valObj: Obj = arguments[1]
    source: Obj = arguments[2]
  var
    hashMapElements = source.hashMapElements
  hashMapElements[keyObj.strValue] = valObj
  return newHashMap(hashMapElements=hashMapElements)

proc hashMapRemove(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, hashMapRemove)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 1, ObjType.OTHashMap)

  let
    keyObj: Obj = arguments[0]
    source: Obj = arguments[1]
  var
    hashMapElements = source.hashMapElements
  hashMapElements.del(keyObj.strValue)
  return newHashMap(hashMapElements=hashMapElements)

proc hashMapUpdate(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 3, hashMapUpdate)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 2, ObjType.OTHashMap)

  let
    keyObj: Obj = arguments[0]
    valObj: Obj = arguments[1]
    source: Obj = arguments[2]
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

proc hashMapHasKey(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, hashMapHasKey)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 1, ObjType.OTHashMap)

  let
    keyObj: Obj = arguments[0]
    source: Obj = arguments[1]

  if contains(source.hashMapElements, keyObj.strValue):
    return OBJ_TRUE
  else:
    return OBJ_FALSE

proc hashMapGet(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, hashMapHasKey)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 2, ObjType.OTHashMap)

  let
    keyObj: Obj = arguments[0]
    defaultValue: Obj = arguments[1]
    source: Obj = arguments[2]

  if contains(source.hashMapElements, keyObj.strValue):
    return source.hashMapElements[keyObj.strValue]
  else:
    return defaultValue

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
  "hasKey": newBuiltin(builtinFn=hashMapHasKey),
  "get": newBuiltin(builtinFn=hashMapGet),
  # TODO: Implement keys
  # TODO: Implement values
  # TODO: Implement fromArray
}.toOrderedTable

let hashMapModule*: Obj = newHashMap(hashMapElements=functions)
