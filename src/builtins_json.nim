import tables
import json
from obj import
  Obj,
  ObjType,
  ApplyFunction,
  newBuiltin,
  newBuiltinModule,
  newHashMap,
  newStr,
  newError,
  newInteger,
  newFloat,
  newArray,
  Env,
  newEnv,
  OBJ_NIL,
  OBJ_TRUE,
  OBJ_FALSE,
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

proc jsonNodeToObj(jsonNode: JsonNode): Obj =
  case jsonNode.kind:
    of JInt:
      return newInteger(jsonNode.num.int)
    of JString:
      return newStr(jsonNode.str)
    of JFloat:
      return newFloat(jsonNode.fnum.float)
    of JBool:
      return if jsonNode.bval: OBJ_TRUE else: OBJ_FALSE
    of JArray:
      var elements: seq[Obj] = @[]
      for val in jsonNode.elems:
        elements.add(jsonNodeToObj(val))
      return newArray(elements)
    of JObject:
      var elements: OrderedTable[string, Obj] = initOrderedTable[string, Obj]()
      for key, val in pairs(jsonNode.fields):
        elements[key] = jsonNodeToObj(val)
      return newHashMap(elements)
    else:
      return OBJ_NIL

proc jsonFromJSON(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 1)
  requireArgOfType(arguments, 0, ObjType.OTString)

  let
    rawJSON: string = arguments[0].strValue
    jsonNode: JsonNode = parseJson(rawJSON)
  return jsonNodeToObj(jsonNode)

let functions*: OrderedTable[string, Obj] = {
  "toJSON": newBuiltin(builtinFn=jsonToJSON),
  "fromJSON": newBuiltin(builtinFn=jsonFromJSON),
}.toOrderedTable

let jsonModule*: Obj = newBuiltinModule(moduleFns=functions)
