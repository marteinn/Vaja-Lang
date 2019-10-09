type
  ObjType* = enum
    OTInteger
  Obj* = ref object
    case objType*: ObjType
      of OTInteger: intValue*: int
  Env* = ref object


proc newEnv*():Env =
  return Env()

method inspect*(obj: Obj): string =
  case obj.objType:
    of OTInteger: $obj.intValue

proc newInteger*(intValue: int): Obj =
  return Obj(objType: ObjType.OTInteger, intValue: intValue)
