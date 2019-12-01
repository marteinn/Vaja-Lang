import sequtils
from strutils import join
from obj import Obj, ObjType

type
  TestValueType* = enum
    TVTInt
    TVTBool
    TVTFloat
    TVTNil
    TVTString
    TVTArray
  TestValue* = ref object
    case valueType*: TestValueType
      of TVTInt: intValue*: int
      of TVTBool: boolValue*: bool
      of TVTFloat: floatValue*: float
      of TVTNil: discard
      of TVTString: strValue*: string
      of TVTArray: arrayElements*: seq[TestValue]

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
    of TVTString:
      return $tv.strValue
    of TVTArray:
      let
        elements: seq[string] = map(
          tv.arrayElements,
          proc (x: TestValue): string =
            $x
        )

      return "[" & join(elements, ", ") & "]"

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
    of TVTString:
      return tv.strValue == obj.strValue
    of TVTArray:
      if len(tv.arrayElements) != len(obj.arrayElements):
        return false
      for index, tvElement in tv.arrayElements:
        if tvElement != obj.arrayElements[index]:
          return false
      return true
