import tables
import base64
from obj import
  Obj,
  ObjType,
  ApplyFunction,
  newBuiltin,
  newBuiltinModule,
  newError,
  newArray,
  newStr,
  inspect
import test_utils

proc base64Encode(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTString)

  let
    pathObj: Obj = arguments[0]
    fileContent: string = encode(pathObj.strValue)
  return newStr(fileContent)

proc base64Decode(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTString)

  let
    pathObj: Obj = arguments[0]
    fileContent: string = decode(pathObj.strValue)
  return newStr(fileContent)

let functions*: OrderedTable[string, Obj] = {
  "encode": newBuiltin(builtinFn=base64Encode),
  "decode": newBuiltin(builtinFn=base64Decode),
}.toOrderedTable

let base64Module*: Obj = newBuiltinModule(moduleFns=functions)
