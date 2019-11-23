import strformat
from compiler import Bytecode
from obj import
  Obj,
  inspect,
  newError,
  newInteger,
  newFloat
from code import
  Instructions,
  readUint16,
  OpCode,
  OpConstant,
  OpAdd,
  OpPop,
  OpSub,
  OpMul,
  OpDiv

const stackSize: int = 2048

type
  VM* = ref object
    constants: seq[Obj]
    instructions: Instructions
    stack: seq[Obj]
    # Always use the next free value
    # If stack len = 1
    # If stack len = 1
    stackPointer: int
  VMError* = ref object
    message*: string

proc newVM*(bytecode: Bytecode): VM =
  return VM(
    constants: bytecode.constants,
    instructions: bytecode.instructions,
    stack: newSeq[Obj](stackSize),
    stackPointer: 0
  )

proc toOpCode(input: byte): OPCode =
  if input == OpConstant:
    return OpConstant

proc push(vm: var VM, obj: Obj): VMError =
  if vm.stackPointer >= stackSize:
    return VMError(message: "Stack overflow")

  vm.stack[vm.stackPointer] = obj
  vm.stackPointer += 1
  discard

proc pop(vm: var VM): Obj =
  let obj = vm.stack[vm.stackPointer-1]
  vm.stackPointer -= 1
  return obj

method execBinaryIntOp*(vm: var VM, opCode: OpCode): VMError {.base.} =
  let rightObj = vm.pop()
  let leftObj = vm.pop()
  let rightValue = rightObj.intValue
  let leftValue = leftObj.intValue

  case opCode:
    of OpAdd:
      return vm.push(newInteger(leftValue + rightValue))
    of OpSub:
      return vm.push(newInteger(leftValue - rightValue))
    of OpMul:
      return vm.push(newInteger(leftValue * rightValue))
    of OpDiv:
      return vm.push(newFloat(leftValue / rightValue))
    else:
      return VMError(message: fmt"Unknown binary operation {opCode}")

method runVM*(vm: var VM): VMError {.base.} =
  var ip = 0
  while ip < len(vm.instructions):
    let
      instruction = vm.instructions[ip]
      opCode = OpCode(instruction)
    case opCode:
      of OpConstant:
        let constIndex = readUint16(
          vm.instructions[ip+1 .. len(vm.instructions)-1]
        )
        ip += 2

        let vmError: VMError = vm.push(vm.constants[constIndex])
        if vmError != nil:
          return vmError
      of OpAdd:
        discard vm.execBinaryIntOp(opCode)
      of OpSub:
        discard vm.execBinaryIntOp(opCode)
      of OpMul:
        discard vm.execBinaryIntOp(opCode)
      of OpDiv:
        discard vm.execBinaryIntOp(opCode)
      of OpPop:
        discard vm.pop
      else:
        discard

    ip += 1

method stackTop*(vm: VM): Obj {.base.} =
  if len(vm.stack) == 0:
    return nil

  return vm.stack[vm.stackPointer-1]

method lastPoppedStackElement*(vm: VM): Obj =
  return vm.stack[vm.stackPointer]
