from obj import Obj

type
  TestValueType* = enum
    TVTInt
    TVTBool
    TVTFloat
  TestValue* = ref object
    case valueType*: TestValueType
      of TVTInt: intValue*: int
      of TVTBool: boolValue*: bool
      of TVTFloat: floatValue*: float

proc `$`*(tv: TestValue): string =
  case tv.valueType:
    of TVTInt:
      return $tv.intValue
    of TVTBool:
      return $tv.boolValue
    of TVTFloat:
      return $tv.floatValue

proc `==`*(tv: TestValue, obj: Obj): bool =
  case tv.valueType:
    of TVTInt:
      return tv.intValue == obj.intValue
    of TVTBool:
      return tv.boolValue == obj.boolValue
    of TVTFloat:
      return tv.floatValue == obj.floatValue
