from compiler import Bytecode
from obj import
  Obj,
  inspect,
  newError,
  newInteger
from code import Instructions, readUint16, OpCode, OpConstant, OpAdd

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
        let rightObj = vm.pop()
        let leftObj = vm.pop()
        let rightValue = rightObj.intValue
        let leftValue = leftObj.intValue

        discard vm.push(newInteger(leftValue + rightValue))
      else:
        discard

    ip += 1

method stackTop*(vm: VM): Obj {.base.} =
  if len(vm.stack) == 0:
    return nil

  return vm.stack[vm.stackPointer-1]
