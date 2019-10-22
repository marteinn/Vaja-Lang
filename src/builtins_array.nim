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
    return newError(errorMsg="Argument arr was " & $(fn.objType) & ", want Array")

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
  if arr.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(fn.objType) & ", want Array")
  if fn.objType != ObjType.OTFunction and fn.objType != ObjType.OTFunctionGroup:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")

  let filtered: seq[Obj] = filter(arr.arrayElements, proc (x: Obj): bool =
    var env: Env = newEnv()
    let res: Obj = applyFn(fn, @[x], env)
    if res.objType != OTBoolean:
      return res.boolValue
    return res.boolValue
  )
  return newArray(arrayElements=filtered)

let functions*: OrderedTable[string, Obj] = {
  "len": newBuiltin(builtinFn=arrayLen),
  "head": newBuiltin(builtinFn=arrayHead),
  "last": newBuiltin(builtinFn=arrayLast),
  "map": newBuiltin(builtinFn=arrayMap),
  "filter": newBuiltin(builtinFn=arrayFilter),
  "reduce": newBuiltin(builtinFn=arrayReduce),
}.toOrderedTable

let arrayModule*: Obj = newHashMap(hashMapElements=functions)
