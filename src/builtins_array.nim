import tables
from obj import Obj, ObjType, newBuiltin, newHashMap, newError, newInteger, NIL, inspect

proc builtinArrayLen(arguments: seq[Obj]): Obj =
  if len(arguments) == 0:
    return newError(errorMsg="Missing arguments")
  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTArray:
    return newError(errorMsg="Argument is not an array")
  return newInteger(intValue=len(obj.arrayElements))

proc builtinArrayHead(arguments: seq[Obj]): Obj =
  if len(arguments) == 0:
    return newError(errorMsg="Missing arguments")
  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTArray:
    return newError(errorMsg="Argument is not an array")
  return obj.arrayElements[0]

proc builtinArrayLast(arguments: seq[Obj]): Obj =
  if len(arguments) == 0:
    return newError(errorMsg="Missing arguments")
  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTArray:
    return newError(errorMsg="Argument is not an array")
  return obj.arrayElements[high(obj.arrayElements)]

let functions*: OrderedTable[string, Obj] = {
  "len": newBuiltin(builtinFn=builtinArrayLen),
  "head": newBuiltin(builtinFn=builtinArrayHead),
  "last": newBuiltin(builtinFn=builtinArrayLast),
}.toOrderedTable

let arrayModule*: Obj = newHashMap(hashMapElements=functions)
