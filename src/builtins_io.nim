import tables
from obj import
  Obj,
  ObjType,
  ApplyFunction,
  newBuiltin,
  newBuiltinModule,
  newError,
  newInteger,
  newArray,
  newStr,
  Env,
  newEnv,
  OBJ_TRUE,
  inspect
import test_utils

proc ioReadFile(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTString)

  let
    pathObj: Obj = arguments[0]
    fileContent: string = readFile(pathObj.strValue)
  return newStr(fileContent)

proc ioWriteFile(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  curryIfMissingArgs(arguments, 2, ioWriteFile)
  requireArgOfType(arguments, 0, ObjType.OTString)
  requireArgOfType(arguments, 1, ObjType.OTString)

  let
    content: Obj = arguments[0]
    pathObj: Obj = arguments[1]
  writeFile(pathObj.strValue, content.strValue)
  return OBJ_TRUE

let functions*: OrderedTable[string, Obj] = {
  "readFile": newBuiltin(builtinFn=ioReadFile),
  "writeFile": newBuiltin(builtinFn=ioWriteFile),
}.toOrderedTable

let ioModule*: Obj = newBuiltinModule(moduleFns=functions)
