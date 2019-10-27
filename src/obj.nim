from sequtils import map
from strutils import join
import tables
import hashes
from ast import Node, toCode

type
  NativeValue* = ref object of RootObj
  ObjType* = enum
    OTInteger
    OTFloat
    OTString
    OTBoolean
    OTError
    OTFunction
    OTFunctionGroup
    OTReturn
    OTNil
    OTArray
    OTBuiltin
    OTHashMap
    OTNativeObject
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
      of OTFunctionGroup:
        arityGroup*: Table[int, seq[Obj]]
      of OTReturn: returnValue*: Obj
      of OTNil: discard
      of OTArray: arrayElements*: seq[Obj]
      of OTBuiltin: builtinFn*:
        proc(arguments: seq[Obj], applyFn: ApplyFunction): Obj
      of OTHashMap: hashMapElements*: OrderedTable[string, Obj]
      of OTNativeObject: nativeValue*: NativeValue
  ApplyFunction* =
    proc (fn: Obj, arguments: seq[Obj], env: var Env): Obj
  Env* = ref object
    store*: Table[string, Obj]
    outer*: Env

proc compareObj*(a: Obj, b: Obj): bool =
  if a.objType != b.objType:
    return false
  return case a.objType:
    of OTInteger:
      a.intValue == b.intValue
    of OTFloat:
      a.floatValue == b.floatValue
    of OTString:
      a.strValue == b.strValue
    of OTBoolean:
      a.boolValue == b.boolValue
    of OTNil:
      true
    else:
      false

proc newEnv*(): Env =
  return Env(store: initTable[string, Obj]())

proc newEnclosedEnv*(env: Env): Env =
  return Env(outer: env, store: initTable[string, Obj]())

proc mergeEnvs*(env: var Env, fromEnv: var Env): Env =
  for key, value in fromEnv.store:
    env.store[key] = value
  return env

proc setVar*(env: Env, name: string, value: Obj): Env =
  env.store[name] = value
  return env

proc containsVar*(env: Env, name: string): bool =
  if env.outer == nil:
    return contains(env.store, name)

  return contains(env.store, name) or contains(env.outer.store, name)

proc getVar*(env: Env, name: string): Obj =
  if contains(env.store, name):
    return env.store[name]

  if env != nil and contains(env.outer.store, name):
    return env.outer.store[name]

proc hasNumberType*(obj: Obj): bool =
  obj.objType == OTInteger or obj.objType == OTFloat

proc promoteToFloatValue*(obj: Obj): float =
  if obj.objType == OTInteger:
    return float(obj.intValue)

  if obj.objType == OTFloat:
    return obj.floatValue

proc inspect*(obj: Obj): string =
  if obj == nil:
    return ""

  case obj.objType:
    of OTInteger: $obj.intValue
    of OTFloat: $obj.floatValue
    of OTString: obj.strValue
    of OTBoolean:
      if obj.boolValue: "true" else: "false"
    of OTError: obj.errorMsg
    of OTFunctionGroup: "<function group>"
    of OTFunction:
      let
        paramsCode: seq[string] = map(obj.functionParams, proc (x: Node): string = toCode(x))
        paramsCodeString: string = join(paramsCode, ", ")
      "fn (" & paramsCodeString & ") " & obj.functionBody.toCode() & " end"
    of OTReturn:
      obj.returnValue.inspect()
    of OTNil: "nil"
    of OTArray:
      let
        elementsCode: seq[string] = map(obj.arrayElements, proc (x: Obj): string = inspect(x))
      "[" & join(elementsCode, ", ") & "]"
    of OTBuiltin: "<builtin>"
    of OTHashMap:
      var elementsCode: string = ""
      for key, val in obj.hashMapElements:
        if elementsCode != "":
          elementsCode = elementsCode & ", "
        elementsCode = elementsCode & key & ": " & val.inspect()

      "{" & elementsCode & "}"
    of OTNativeObject: "<native object>"

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

proc newNil*(): Obj =
  return Obj(objType: ObjType.OTNil)

proc newFunctionGroup*(): Obj =
  return Obj(
    objType: ObjType.OTFunctionGroup,
    arityGroup: initTable[
      int, seq[Obj]
    ](),
  )

proc newArray*(arrayElements: seq[Obj]): Obj =
  return Obj(objType: ObjType.OTArray, arrayElements: arrayElements)

proc newBuiltin*(builtinFn: proc(arguments: seq[Obj], applyFn: ApplyFunction): Obj): Obj =
  return Obj(objType: ObjType.OTBuiltin, builtinFn: builtinFn)

proc newHashMap*(hashMapElements: OrderedTable[string, Obj]): Obj =
  return Obj(objType: ObjType.OTHashMap, hashMapElements: hashMapElements)

proc newNativeObject*(nativeValue: NativeValue): Obj =
  return Obj(objType: ObjType.OTNativeObject, nativeValue: nativeValue)

proc addFunctionToGroup*(fnGroup: var Obj, fn: Obj): Obj =
  let arity: int = len(fn.functionParams)
  if not contains(fnGroup.arityGroup, arity):
    fnGroup.arityGroup[arity] = @[fn]
  else:
    fnGroup.arityGroup[arity].add(fn)
  fnGroup

proc inspectEnv*(env: Env): string =
  var ret = ""
  for key, obj in env.store:
    if len(ret) > 0:
      ret = ret & ", "
    ret = ret & key & ": " & obj.inspect()

  if env.outer != nil:
    if len(ret) > 0:
      ret = ret & ", "
    ret = ret & "outer: " & inspectEnv(env.outer)
  return "{" & ret & "}"

var
  TRUE*: Obj = newBoolean(boolValue=true)
  FALSE*: Obj = newBoolean(boolValue=false)
  NIL*: Obj = newNil()
