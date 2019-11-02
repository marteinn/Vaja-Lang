import tables
import json
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
import test_utils

proc objToJSON(obj: Obj): JsonNode =
  case obj.objType:
    of ObjType.OTInteger:
      return newJInt(obj.intValue)
    of ObjType.OTString:
      return newJString(obj.strValue)
    of ObjType.OTFloat:
      return newJFloat(obj.floatValue)
    of ObjType.OTBoolean:
      return newJBool(obj.boolValue)
    of ObjType.OTArray:
      var arr: JsonNode = newJArray()
      for x in obj.arrayElements:
        arr.add(objToJSON(x))
      return arr
    of ObjType.OTHashMap:
      var jObj: JsonNode = newJObject()
      for key, val in obj.hashMapElements:
        jObj.add(key, objToJSON(val))
      return jObj
    else:
      return newJNull()

proc jsonToJSON(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)

  let
    obj: Obj = arguments[0]
    jsonObj: JsonNode = objToJSON(obj)
  return newStr(strValue= $jsonObj)

proc jsonFromJSON(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  discard

let functions*: OrderedTable[string, Obj] = {
  "toJSON": newBuiltin(builtinFn=jsonToJSON),
  "fromJSON": newBuiltin(builtinFn=jsonFromJSON),
}.toOrderedTable

let jsonModule*: Obj = newHashMap(hashMapElements=functions)
