from code import Instructions
from obj import Obj, `$`

type
  Frame* = ref object
    closure*: Obj
    ip*: int
    basePointer*: int

proc newFrame*(closure: Obj, basePointer: int): Frame =
  return Frame(closure: closure, ip: -1, basePointer: basePointer)

method getInstructions*(frame: Frame): Instructions {.base.} =
  return frame.closure.closureFn.compiledFunctionInstructions
