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

proc stringMap(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    fn: Obj = arguments[0]
    source: Obj = arguments[1]
  if fn.objType != ObjType.OTFunction and fn.objType != ObjType.OTFunctionGroup:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")
  if source.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(source.objType) & ", want String")

  let sourceString: string = source.strValue
  var mappedStr: string = ""
  for ch in sourceString:
    var env: Env = newEnv()
    let res: Obj = applyFn(fn, @[newStr($ch)], env)
    mappedStr = mappedStr & res.strValue

  return newStr(strValue=mappedStr)

proc stringFilter(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    fn: Obj = arguments[0]
    source: Obj = arguments[1]
  if fn.objType != ObjType.OTFunction and fn.objType != ObjType.OTFunctionGroup:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")
  if source.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(source.objType) & ", want String")

  let sourceString: string = source.strValue
  var mappedStr: string = ""
  for ch in sourceString:
    var env: Env = newEnv()
    let res: Obj = applyFn(fn, @[newStr($ch)], env)
    if res.objType != OTBoolean:
      continue

    if not res.boolValue:
      continue
    mappedStr = mappedStr & $ch

  return newStr(strValue=mappedStr)

proc stringReduce(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 3:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 3"
    )
  let
    fn: Obj = arguments[0]
    initial: Obj = arguments[1]
    source: Obj = arguments[2]
  if fn.objType != ObjType.OTFunction and fn.objType != ObjType.OTFunctionGroup:
    return newError(errorMsg="Argument fn was " & $(fn.objType) & ", want Function")
  if source.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(source.objType) & ", want String")

  result = initial
  let sourceString: string = source.strValue
  for ch in sourceString:
    var env: Env = newEnv()
    let curr: Obj = newStr($ch)
    result = applyFn(fn, @[result, curr], env)

proc stringAppend(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) != 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    string1: Obj = arguments[0]
    string2: Obj = arguments[1]
  if string1.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(string1.objType) & ", want String")
  if string2.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(string2.objType) & ", want String")
  return newStr(string1.strValue & string2.strValue)

proc stringSlice(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) < 3:
    return newError(
      errorMsg="Wrong number of arguments to String.slice, got " & $len(arguments) & ", want 2"
    )
  let
    fromIndex: Obj = arguments[0]
    toIndex: Obj = arguments[1]
    source: Obj = arguments[2]
  if fromIndex.objType != ObjType.OTInteger:
    return newError(errorMsg="Argument fromIndex was " & $(fromIndex.objType) & ", want Integer")
  if toIndex.objType != ObjType.OTInteger:
    return newError(errorMsg="Argument toIndex was " & $(toIndex.objType) & ", want Integer")
  if source.objType != ObjType.OTString:
    return newError(errorMsg="Argument fn was " & $(source.objType) & ", want String")

  let
    slice = source.strValue[fromIndex.intValue .. (toIndex.intValue-1)]
  return newStr(slice)

proc stringToUpper(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) != 1:
    return newError(
      errorMsg="Wrong number of arguments in String.toUpper, got " & $len(arguments) & ", want 1"
    )
  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(obj.objType) & ", want String")
  return newStr(obj.strValue.toUpper())

proc stringToLower(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) != 1:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 1"
    )
  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(obj.objType) & ", want String")
  return newStr(obj.strValue.toLower())

proc stringToArray(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) != 1:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 1"
    )
  let obj: Obj = arguments[0]
  if obj.objType != ObjType.OTString:
    return newError(errorMsg="Argument obj was " & $(obj.objType) & ", want String")

  let sourceString: string = obj.strValue
  var arrayElements: seq[Obj] = @[]
  for ch in sourceString:
    arrayElements.add(newStr($ch))
  return newArray(arrayElements=arrayElements)

let functions*: OrderedTable[string, Obj] = {
  "len": newBuiltin(builtinFn=stringLen),
  "split": newBuiltin(builtinFn=stringSplit),
  "join": newBuiltin(builtinFn=stringJoin),
  "map": newBuiltin(builtinFn=stringMap),
  "filter": newBuiltin(builtinFn=stringFilter),
  "reduce": newBuiltin(builtinFn=stringReduce),
  "append": newBuiltin(builtinFn=stringAppend),
  "slice": newBuiltin(builtinFn=stringSlice),
  "toUpper": newBuiltin(builtinFn=stringToUpper),
  "toLower": newBuiltin(builtinFn=stringToLower),
  "toArray": newBuiltin(builtinFn=stringToArray),
  # TODO: Add isEmpty
  # TODO: Add left
  # TODO: Add dropLeft
  # TODO: Add dropRight
}.toOrderedTable

let stringModule*: Obj = newHashMap(hashMapElements=functions)

