type
  ObjType* = enum
    OTInteger
    OTFloat
  Obj* = ref object
    case objType*: ObjType
      of OTInteger: intValue*: int
      of OTFloat: floatValue*: float
  Env* = ref object

proc newEnv*():Env =
  return Env()

method hasNumberType*(obj: Obj): bool =
  obj.objType == OTInteger or obj.objType == OTFloat

method promoteToFloatValue*(obj: Obj): float =
  if obj.objType == OTInteger:
    return float(obj.intValue)

  if obj.objType == OTFloat:
    return obj.floatValue

method inspect*(obj: Obj): string =
  case obj.objType:
    of OTInteger: $obj.intValue
    of OTFloat: $obj.floatValue

proc newInteger*(intValue: int): Obj =
  return Obj(objType: ObjType.OTInteger, intValue: intValue)

proc newFloat*(floatValue: float): Obj =
  return Obj(objType: ObjType.OTFloat, floatValue: floatValue)
