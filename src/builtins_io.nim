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
  newStr,
  Env,
  newEnv,
  NIL,
  inspect

proc ioReadFile(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) != 1:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 1"
    )

  let pathObj: Obj = arguments[0]
  if pathObj.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(pathObj.objType) & ", want String")
  let fileContent: string = readFile(pathObj.strValue)
  return newStr(fileContent)

let functions*: OrderedTable[string, Obj] = {
  "readFile": newBuiltin(builtinFn=ioReadFile),
}.toOrderedTable

let ioModule*: Obj = newHashMap(hashMapElements=functions)
