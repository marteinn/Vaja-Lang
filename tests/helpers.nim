import sequtils
import tables
from strutils import join
from obj import Obj, ObjType
from code import Instructions, `$`

type
  TestValueType* = enum
    TVTInt
    TVTBool
    TVTFloat
    TVTNil
    TVTString
    TVTArray
    TVTHashMap
    TVTInstructions,
  TestValue* = ref object
    case valueType*: TestValueType
      of TVTInt: intValue*: int
      of TVTBool: boolValue*: bool
      of TVTFloat: floatValue*: float
      of TVTNil: discard
      of TVTString: strValue*: string
      of TVTArray: arrayElements*: seq[TestValue]
      of TVTHashMap: hashMapElements*: OrderedTable[string, TestValue]
      of TVTInstructions: instructions*: seq[Instructions]

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
    of TVTHashMap:
      var elementsCode: string = ""
      for key, val in tv.hashMapElements:
        if elementsCode != "":
          elementsCode = elementsCode & ", "
        elementsCode = elementsCode & key & ": " & $val
      return "{" & elementsCode & "}"
    of TVTInstructions:
      return $tv.instructions

proc `==`*(tv: TestValue, obj: Obj): bool =
  if isNil(obj):
    return false

  if tv.valueType == TVTInt and obj.objType != OTInteger:
    return false
  if tv.valueType == TVTBool and obj.objType != OTBoolean:
    return false

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
    of TVTHashMap:
      if len(tv.hashMapElements) != len(obj.hashMapElements):
        return false
      for key, tvElement in tv.hashMapElements:
        if not (key in obj.hashMapElements):
          return false
        if tvElement != obj.hashMapElements[key]:
          return false
      return true
    of TVTInstructions:
      var flattenInstructions: Instructions = @[]
      for x in tv.instructions:
        for y in x:
          flattenInstructions.add(y)

      return $flattenInstructions == $obj.compiledFunctionInstructions
