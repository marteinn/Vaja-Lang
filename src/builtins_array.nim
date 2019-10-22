import tables
import sequtils
from obj import
  Obj,
  ObjType,
  ApplyFunction,
  newBuiltin,
  newHashMap,
  newError,
  newInteger,
  newArray,
  Env,
  newEnv,
  NIL,
  inspect

proc arrayLen(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) == 0:
    return newError(errorMsg="Missing arguments")
  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTArray:
    return newError(errorMsg="Argument is not an array")
  return newInteger(intValue=len(obj.arrayElements))

proc arrayHead(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) == 0:
    return newError(errorMsg="Missing arguments")
  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTArray:
    return newError(errorMsg="Argument is not an array")
  return obj.arrayElements[0]

proc arrayLast(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) == 0:
    return newError(errorMsg="Missing arguments")
  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTArray:
    return newError(errorMsg="Argument is not an array")
  return obj.arrayElements[high(obj.arrayElements)]

proc arrayMap(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    fn: Obj = arguments[0]
    arr: Obj = arguments[1]
  if arr.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(fn.objType) & ", want Array")
  if fn.objType != ObjType.OTFunction and fn.objType != ObjType.OTFunctionGroup:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")

  let mapped: seq[Obj] = map(arr.arrayElements, proc (x: Obj): Obj =
    var env: Env = newEnv()
    return applyFn(fn, @[x], env)
  )
  return newArray(arrayElements=mapped)

proc arrayReduce(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 3:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 3"
    )
  let
    fn: Obj = arguments[0]
    initial: Obj = arguments[1]
    arr: Obj = arguments[2]
  if fn.objType != ObjType.OTFunction and fn.objType != ObjType.OTFunctionGroup:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")
  if arr.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(arr.objType) & ", want Array")

  result = initial
  for curr in arr.arrayElements:
    var env: Env = newEnv()
    result = applyFn(fn, @[result, curr], env)

proc arrayFilter(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    fn: Obj = arguments[0]
    arr: Obj = arguments[1]
  if fn.objType != ObjType.OTFunction and fn.objType != ObjType.OTFunctionGroup:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")
  if arr.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(arr.objType) & ", want Array")

  let filtered: seq[Obj] = filter(arr.arrayElements, proc (x: Obj): bool =
    var env: Env = newEnv()
    let res: Obj = applyFn(fn, @[x], env)
    if res.objType != OTBoolean:
      return res.boolValue
    return res.boolValue
  )
  return newArray(arrayElements=filtered)

proc arrayPush(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    el: Obj = arguments[0]
    arr: Obj = arguments[1]
  if arr.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(arr.objType) & ", want Array")

  let arrayElements: seq[Obj] = concat(arr.arrayElements, @[el])
  return newArray(arrayElements=arrayElements)

proc arrayDeleteAt(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    index: Obj = arguments[0]
    arr: Obj = arguments[1]
  if index.objType != ObjType.OTInteger:
    return newError(errorMsg="Argument index was " & $(index.objType) & ", want Integer")
  if arr.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(arr.objType) & ", want Array")
  var arrayElements: seq[Obj] = arr.arrayElements
  arrayElements.delete(index.intValue, index.intValue)
  return newArray(arrayElements=arrayElements)

proc arrayAppend(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    elements: Obj = arguments[0]
    arr: Obj = arguments[1]

  if elements.objType != ObjType.OTArray:
    return newError(
      errorMsg="Argument arr was " & $(elements.objType) & ", want Array"
    )
  if arr.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(arr.objType) & ", want Array")

  let arrayElements = concat(elements.arrayElements, arr.arrayElements)
  return newArray(arrayElements=arrayElements)

proc arrayReplaceAt(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    index: Obj = arguments[0]
    obj: Obj = arguments[1]
    arr: Obj = arguments[2]
  if index.objType != ObjType.OTInteger:
    return newError(errorMsg="Argument index was " & $(index.objType) & ", want Integer")
  if arr.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(arr.objType) & ", want Array")
  var arrayElements: seq[Obj] = arr.arrayElements
  arrayElements[index.intValue] = obj
  return newArray(arrayElements=arrayElements)

proc arrayTail(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) == 0:
    return newError(errorMsg="Missing arguments")
  let arr: Obj = arguments[0]
  if arr.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(arr.objType) & ", want Array")
  let arrayElements = arr.arrayElements[1..high(arr.arrayElements)]
  return newArray(arrayElements=arrayElements)

let functions*: OrderedTable[string, Obj] = {
  "len": newBuiltin(builtinFn=arrayLen),
  "head": newBuiltin(builtinFn=arrayHead),
  "last": newBuiltin(builtinFn=arrayLast),
  "map": newBuiltin(builtinFn=arrayMap),
  "filter": newBuiltin(builtinFn=arrayFilter),
  "reduce": newBuiltin(builtinFn=arrayReduce),
  "push": newBuiltin(builtinFn=arrayPush),
  "deleteAt": newBuiltin(builtinFn=arrayDeleteAt),
  "append": newBuiltin(builtinFn=arrayAppend),
  "replaceAt": newBuiltin(builtinFn=arrayReplaceAt),
  "tail": newBuiltin(builtinFn=arrayTail),
}.toOrderedTable

let arrayModule*: Obj = newHashMap(hashMapElements=functions)
