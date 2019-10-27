import tables
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
  TRUE,
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

proc ioWriteFile(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) != 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 1"
    )

  let
    content: Obj = arguments[0]
    pathObj: Obj = arguments[1]
  if content.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(content.objType) & ", want String")
  if pathObj.objType != ObjType.OTString:
    return newError(errorMsg="Argument arr was " & $(pathObj.objType) & ", want String")

  writeFile(pathObj.strValue, content.strValue)
  return TRUE

let functions*: OrderedTable[string, Obj] = {
  "readFile": newBuiltin(builtinFn=ioReadFile),
  "writeFile": newBuiltin(builtinFn=ioWriteFile),
}.toOrderedTable

let ioModule*: Obj = newHashMap(hashMapElements=functions)
