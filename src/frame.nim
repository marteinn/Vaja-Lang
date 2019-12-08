from code import Instructions
from obj import Obj, `$`

type
  Frame* = ref object
    fn*: Obj
    ip*: int

proc newFrame*(fn: Obj): Frame =
  return Frame(fn: fn, ip: -1)

method getInstructions*(frame: Frame): Instructions {.base.} =
  return frame.fn.compiledFunctionInstructions
