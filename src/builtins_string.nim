import tables
import sequtils
import strutils
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
  inspect

proc stringSplit(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    delimiter: Obj = arguments[0]
    source: Obj = arguments[1]
  if source.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(source.objType) & ", want String")
  if delimiter.objType != ObjType.OTString:
    return newError(errorMsg="Argument fn was " & $(delimiter.objType) & ", want String")

  let
    strings = source.strValue.split(delimiter.strValue)
    arrayElements = strings.map(proc (x: string): Obj =
      return newStr(strValue=x)
    )
  return newArray(arrayElements=arrayElements)

let functions*: OrderedTable[string, Obj] = {
  "split": newBuiltin(builtinFn=stringSplit),
}.toOrderedTable

let stringModule*: Obj = newHashMap(hashMapElements=functions)
