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
  inspect,
  OBJ_TRUE,
  OBJ_FALSE
import test_utils

proc stringLen(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTString)

  let obj: Obj = arguments[0]
  return newInteger(intValue=len(obj.strValue))

proc stringSplit(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, stringSplit)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    delimiter: Obj = arguments[0]
    source: Obj = arguments[1]
    strings = source.strValue.split(delimiter.strValue)
    arrayElements = strings.map(proc (x: string): Obj =
      return newStr(strValue=x)
    )
  return newArray(arrayElements=arrayElements)

proc stringJoin(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, stringJoin)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 1, ObjType.OTArray)

  let
    delimiter: Obj = arguments[0]
    source: Obj = arguments[1]
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
  curryIfMissingArgs(arguments, 2, stringMap)
  requireArgOfTypes(arguments, 0, @[
    ObjType.OTFunction, ObjType.OTFunctionGroup, ObjType.OTBuiltin
  ])
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    fn: Obj = arguments[0]
    source: Obj = arguments[1]
    sourceString: string = source.strValue
  var
    mappedStr: string = ""
  for ch in sourceString:
    var env: Env = newEnv()
    let res: Obj = applyFn(fn, @[newStr($ch)], env)
    mappedStr = mappedStr & res.strValue

  return newStr(strValue=mappedStr)

proc stringFilter(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, stringFilter)
  requireArgOfTypes(arguments, 0, @[
    ObjType.OTFunction, ObjType.OTFunctionGroup, ObjType.OTBuiltin
  ])
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    fn: Obj = arguments[0]
    source: Obj = arguments[1]
    sourceString: string = source.strValue
  var
    mappedStr: string = ""
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
  curryIfMissingArgs(arguments, 3, stringReduce)
  requireArgOfTypes(arguments, 0, @[
    ObjType.OTFunction, ObjType.OTFunctionGroup, ObjType.OTBuiltin
  ])
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    fn: Obj = arguments[0]
    initial: Obj = arguments[1]
    source: Obj = arguments[2]
  result = initial
  let sourceString: string = source.strValue
  for ch in sourceString:
    var env: Env = newEnv()
    let curr: Obj = newStr($ch)
    result = applyFn(fn, @[result, curr], env)

proc stringAppend(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, stringAppend)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    string1: Obj = arguments[0]
    string2: Obj = arguments[1]
  return newStr(string1.strValue & string2.strValue)

proc stringSlice(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 3, stringSlice)
  requireArgOfType(arguments, 0, ObjType.OTInteger)
  requireArgOfType(arguments, 1, ObjType.OTInteger)
  requireArgOfType(arguments, 2, ObjType.OTString)

  let
    fromIndex: Obj = arguments[0]
    toIndex: Obj = arguments[1]
    source: Obj = arguments[2]
    slice = source.strValue[fromIndex.intValue .. (toIndex.intValue-1)]
  return newStr(slice)

proc stringToUpper(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTString)

  let obj: Obj = arguments[0]
  return newStr(obj.strValue.toUpper())

proc stringToLower(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTString)

  let obj: Obj = arguments[0]
  return newStr(obj.strValue.toLower())

proc stringToArray(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTString)

  let
    obj: Obj = arguments[0]
    sourceString: string = obj.strValue
  var
    arrayElements: seq[Obj] = @[]
  for ch in sourceString:
    arrayElements.add(newStr($ch))
  return newArray(arrayElements=arrayElements)

proc stringLeft(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 2)
  requireArgOfType(arguments, 0, ObjType.OTInteger)
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    length: int = arguments[0].intValue
    source: Obj = arguments[1]
    slice = source.strValue[0 .. length-1]
  return newStr(slice)

proc stringRight(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 2)
  requireArgOfType(arguments, 0, ObjType.OTInteger)
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    length: int = arguments[0].intValue
    source: Obj = arguments[1]
    strLength: int = len(source.strValue)
    slice = source.strValue[(strLength-length) .. strLength-1]
  return newStr(slice)

proc stringContains(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 2)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    needle: string = arguments[0].strValue
    source: string = arguments[1].strValue

  if contains(source, needle):
    return OBJ_TRUE
  else:
    return OBJ_FALSE

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
  "left": newBuiltin(builtinFn=stringLeft),
  "right": newBuiltin(builtinFn=stringRight),
  "contains": newBuiltin(builtinFn=stringContains),
  # TODO: Add isEmpty
  # TODO: Add dropLeft
  # TODO: Add dropRight
}.toOrderedTable

let stringModule*: Obj = newHashMap(hashMapElements=functions)
