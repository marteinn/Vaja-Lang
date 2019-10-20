import tables
from obj import Obj, ObjType, newBuiltin, newError, newStr, NIL, inspect

proc builtinType(arguments: seq[Obj]): Obj =
  if len(arguments) == 0:
    return newError(errorMsg="Missing arguments")

  let obj = arguments[0]
  let objType = case obj.objType:
    of ObjType.OTInteger: "integer"
    of ObjType.OTFloat: "float"
    of ObjType.OTString: "string"
    of ObjType.OTArray: "array"
    of ObjType.OTBoolean: "boolean"
    of ObjType.OTNIL: "nil"
    else: ""

  if objType == "":
    return NIL

  return newStr(strValue=objType)

proc builtinPrint(arguments: seq[Obj]): Obj =
  if len(arguments) == 0:
    return newError(errorMsg="Missing arguments")
  let obj = arguments[0]
  echo obj.inspect()
  return NIL

var
  globals*: Table[string, Obj] = {
    "type": newBuiltin(builtinFn=builtinType),
    "print": newBuiltin(builtinFn=builtinPrint)
  }.toTable
