from sequtils import map
from strutils import join
import tables
from ast import Node, toCode

type
  ObjType* = enum
    OTInteger
    OTFloat
    OTString
    OTBoolean
    OTError
    OTFunction
    OTReturn
  Obj* = ref object
    case objType*: ObjType
      of OTInteger: intValue*: int
      of OTFloat: floatValue*: float
      of OTString: strValue*: string
      of OTBoolean: boolValue*: bool
      of OTError: errorMsg*: string
      of OTFunction:
        functionBody*: Node
        functionEnv*: Env
        functionParams*: seq[Node]
      of OTReturn:
        returnValue*: Obj
  Env* = ref object
    store: Table[string, Obj]
    outer: Env


proc newEnv*(): Env =
  return Env(store: initTable[string, Obj]())

proc newEnclosedEnv*(env: Env): Env =
  return Env(outer: env, store: initTable[string, Obj]())

method setVar*(env: Env, name: string, value: Obj): Env {.base.} =
  env.store[name] = value
  return env

method containsVar*(env: Env, name: string): bool {.base.} =
  return contains(env.store, name)

method getVar*(env: Env, name: string): Obj {.base.} =
  return env.store[name]

method hasNumberType*(obj: Obj): bool {.base.} =
  obj.objType == OTInteger or obj.objType == OTFloat

method promoteToFloatValue*(obj: Obj): float {.base.} =
  if obj.objType == OTInteger:
    return float(obj.intValue)

  if obj.objType == OTFloat:
    return obj.floatValue

method inspect*(obj: Obj): string {.base.} =
  if obj == nil:
    return ""

  case obj.objType:
    of OTInteger: $obj.intValue
    of OTFloat: $obj.floatValue
    of OTString: obj.strValue
    of OTBoolean:
      if obj.boolValue: "true" else: "false"
    of OTError: obj.errorMsg
    of OTFunction:
      let
        paramsCode: seq[string] = map(obj.functionParams, proc (x: Node): string = toCode(x))
        paramsCodeString: string = join(paramsCode, ", ")
      "fn (" & paramsCodeString & ") " & obj.functionBody.toCode() & " end"
    of OTReturn:
      obj.returnValue.inspect()

proc newInteger*(intValue: int): Obj =
  return Obj(objType: ObjType.OTInteger, intValue: intValue)

proc newFloat*(floatValue: float): Obj =
  return Obj(objType: ObjType.OTFloat, floatValue: floatValue)

proc newBoolean*(boolValue: bool): Obj =
  return Obj(objType: ObjType.OTBoolean, boolValue: boolValue)

proc newStr*(strValue: string): Obj =
  return Obj(objType: ObjType.OTString, strValue: strValue)

proc newError*(errorMsg: string): Obj =
  return Obj(objType: ObjType.OTError, errorMsg: errorMsg)

proc newFunction*(functionBody: Node, functionEnv: Env, functionParams: seq[Node]): Obj =
  return Obj(
    objType: ObjType.OTFunction,
    functionBody: functionBody,
    functionEnv: functionEnv,
    functionParams: functionParams
  )

proc newReturn*(returnValue: Obj): Obj =
  return Obj(objType: ObjType.OTReturn, returnValue: returnValue)

var
  TRUE*: Obj = newBoolean(boolValue=true)
  FALSE*: Obj = newBoolean(boolValue=false)
