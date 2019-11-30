from obj import Obj, ObjType

type
  TestValueType* = enum
    TVTInt
    TVTBool
    TVTFloat
    TVTNil
  TestValue* = ref object
    case valueType*: TestValueType
      of TVTInt: intValue*: int
      of TVTBool: boolValue*: bool
      of TVTFloat: floatValue*: float
      of TVTNil: discard

proc `$`*(tv: TestValue): string =
  case tv.valueType:
    of TVTInt:
      return $tv.intValue
    of TVTBool:
      return $tv.boolValue
    of TVTFloat:
      return $tv.floatValue
    of TVTNil:
      return "null"

proc `==`*(tv: TestValue, obj: Obj): bool =
  case tv.valueType:
    of TVTInt:
      return tv.intValue == obj.intValue
    of TVTBool:
      return tv.boolValue == obj.boolValue
    of TVTFloat:
      return tv.floatValue == obj.floatValue
    of TVTNil:
      return obj.objType == ObjType.OTNil
