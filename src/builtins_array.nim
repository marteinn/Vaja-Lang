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
  if fn.objType != ObjType.OTFunction:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")

  let mapped: seq[Obj] = map(arr.arrayElements, proc (x: Obj): Obj =
    var env: Env = newEnv()
    return applyFn(fn, @[x], env)
  )
  return newArray(arrayElements=mapped)

let functions*: OrderedTable[string, Obj] = {
  "len": newBuiltin(builtinFn=arrayLen),
  "head": newBuiltin(builtinFn=arrayHead),
  "last": newBuiltin(builtinFn=arrayLast),
  "map": newBuiltin(builtinFn=arrayMap),
}.toOrderedTable

let arrayModule*: Obj = newHashMap(hashMapElements=functions)
