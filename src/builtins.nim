import tables
from obj import
  Obj,
  ObjType,
  ApplyFunction,
  newBuiltin,
  newHashMap,
  newError,
  newInteger,
  newStr,
  NIL,
  inspect
from builtins_array import arrayModule
from builtins_string import stringModule
from builtins_hashmap import hashMapModule
from builtins_http import httpModule
from builtins_io import ioModule
from builtins_regex import regexModule
import test_utils

proc builtinType(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)

  let obj = arguments[0]
  let objType = case obj.objType:
    of ObjType.OTInteger: "integer"
    of ObjType.OTFloat: "float"
    of ObjType.OTString: "string"
    of ObjType.OTArray: "array"
    of ObjType.OTBoolean: "boolean"
    of ObjType.OTNIL: "nil"
    of ObjType.OTHashMap: "hashmap"
    of ObjType.OTRegex: "regex"
    else: ""

  if objType == "":
    return NIL

  return newStr(strValue=objType)

proc builtinPrint(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)

  let obj = arguments[0]
  echo obj.inspect()
  return NIL

var
  globals*: Table[string, Obj] = {
    "type": newBuiltin(builtinFn=builtinType),
    "print": newBuiltin(builtinFn=builtinPrint),
    "Array": arrayModule,
    "String": stringModule,
    "HashMap": hashMapModule,
    "Http": httpModule,
    "IO": ioModule,
    "Regex": regexModule,
  }.toTable
