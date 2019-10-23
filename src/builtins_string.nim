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

proc stringLen(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) != 1:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 1"
    )
  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(obj.objType) & ", want String")
  return newInteger(intValue=len(obj.strValue))

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

proc stringJoin(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    delimiter: Obj = arguments[0]
    source: Obj = arguments[1]
  if delimiter.objType != ObjType.OTString:
    return newError(errorMsg="Argument fn was " & $(delimiter.objType) & ", want String")
  if source.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(source.objType) & ", want Array")
  let
    arrayElements = source.arrayElements.map(proc (x: Obj): string =
      return case x.objType:
        of ObjType.OTString:
          x.strValue
        of ObjType.OTInteger:
          $x.intValue
        of ObjType.OTFloat:
          $x.floatValue
        else:
          ""
    )

  return newStr(
    strValue=arrayElements.join(delimiter.strValue)
  )

let functions*: OrderedTable[string, Obj] = {
  "len": newBuiltin(builtinFn=stringLen),
  "split": newBuiltin(builtinFn=stringSplit),
  "join": newBuiltin(builtinFn=stringJoin),
}.toOrderedTable

let stringModule*: Obj = newHashMap(hashMapElements=functions)
