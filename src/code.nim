import tables
import strformat

type
  Opcode* = byte
  Instructions* = seq[byte]

const
  OpConstant*: OPCode = 1
  OpAdd*: OPCode = 2
  OpPop*: OpCode = 3
  OpSub*: OpCode = 4
  OpMul*: OpCode = 5
  OpDiv*: OpCode = 6
  OpTrue*: OpCode = 7
  OpFalse*: OpCode = 8
  OpEqual*: OpCode = 9
  OpNotEqual*: OpCode = 10
  OpGreaterThan*: OpCode = 11
  OpMinus*: OpCode = 12
  OpNot*: OpCode = 13
  OpJumpNotThruthy*: OpCode = 14
  OpJump*: OpCode = 15
  OpNil*: OpCode = 16
  OpGetGlobal*: OpCode = 17
  OpSetGlobal*: OpCode = 18
  OpCombine*: OPCode = 19  # ++
  OpArray*: OPCode = 20
  OpHashMap*: OPCode = 21
  OpIndex*: OPCode = 22
  OpCall*: OPCode = 23
  OpReturn*: OPCode = 24
  OpReturnValue*: OPCode = 25
  OpGetLocal*: OpCode = 26
  OpSetLocal*: OpCode = 27
  OpGetBuiltin*: OpCode = 28
  OpClosure*: OpCode = 29
  OpGetFree*: OpCode = 30

type
  Definition* = ref object
    name*: string
    operandWidths*: seq[int]

let definitions: Table[Opcode, Definition] = {
  OpConstant: Definition(name: "OpConstant", operandWidths: @[2]),
  OpAdd: Definition(name: "OpAdd", operandWidths: @[]),
  OpPop: Definition(name: "OpPop", operandWidths: @[]),
  OpSub: Definition(name: "OpSub", operandWidths: @[]),
  OpMul: Definition(name: "OpMul", operandWidths: @[]),
  OpDiv: Definition(name: "OpDiv", operandWidths: @[]),
  OpTrue: Definition(name: "OpTrue", operandWidths: @[]),
  OpFalse: Definition(name: "OpFalse", operandWidths: @[]),
  OpEqual: Definition(name: "OpEqual", operandWidths: @[]),
  OpNotEqual: Definition(name: "OpNotEqual", operandWidths: @[]),
  OpGreaterThan: Definition(name: "OpGreaterThan", operandWidths: @[]),
  OpMinus: Definition(name: "OpMinus", operandWidths: @[]),
  OpNot: Definition(name: "OpNot", operandWidths: @[]),
  OpJump: Definition(name: "OpJump", operandWidths: @[2]),
  OpJumpNotThruthy: Definition(name: "OpJumpNotThruthy", operandWidths: @[2]),
  OpNil: Definition(name: "OpNil", operandWidths: @[]),
  OpGetGlobal: Definition(name: "OpGetGlobal", operandWidths: @[2]),
  OpSetGlobal: Definition(name: "OpSetGlobal", operandWidths: @[2]),
  OpCombine: Definition(name: "OpCombine", operandWidths: @[]),
  OpArray: Definition(name: "OpArray", operandWidths: @[2]),
  OpHashMap: Definition(name: "OpHashMap", operandWidths: @[2]),
  OpIndex: Definition(name: "OpIndex", operandWidths: @[]),
  OpCall: Definition(name: "OpCall", operandWidths: @[1]),
  OpReturn: Definition(name: "OpReturn", operandWidths: @[]),
  OpReturnValue: Definition(name: "OpReturnValue", operandWidths: @[]),
  OpGetLocal: Definition(name: "OpGetLocal", operandWidths: @[1]),
  OpSetLocal: Definition(name: "OpSetLocal", operandWidths: @[1]),
  OpGetBuiltin: Definition(name: "OpGetBuiltin", operandWidths: @[1]),
  OpClosure: Definition(name: "OpClosure", operandWidths: @[2, 1]),
  OpGetFree: Definition(name: "OpGetFree", operandWidths: @[1]),
}.toTable

proc lookup*(op: byte): Definition =
  let opCode = cast[OpCode](op)
  definitions[opCode]

proc make*(op: OpCode, operands: seq[int]): seq[byte] =
  if not (op in definitions):
    return @[]

  let definition: Definition = definitions[op]

  var instructionLen: int = 1
  for x in definition.operandWidths:
    instructionLen += x

  var instruction: seq[byte] = newSeq[byte](instructionLen)
  instruction[0] = byte(op)

  var offset = 1
  for i, operand in operands:
    let width: int = definition.operandWidths[i]
    case width:
      of 1:
        instruction[offset] = byte(operand)
      of 2:
        instruction[offset] = byte(operand shr 8 and 0xFF)
        instruction[offset+1] = byte(operand and 0xFF)
      else:
        discard

    offset += width
  return instruction

proc make*(op: OpCode): seq[byte] =
  return make(op, @[])

proc readUint16*(instructions: Instructions): int =
  return int(
    uint16(instructions[1]) or uint16(instructions[0]) shl 8
  )

proc readUint8*(instructions: Instructions): int =
  return int(
    uint8(instructions[0])
  )

proc readOperands*(
  definition: Definition, instructions: Instructions): (seq[int], int
) =
  var
    operands: seq[int] = newSeq[int](len(definition.operandWidths))
    offset: int = 0

  for i, width in definition.operandWidths:
    case width:
      of 1:
        operands[i] = readUint8(@[instructions[0]])
      of 2:
        operands[i] = readUint16(@[instructions[0], instructions[1]])
      else:
        discard

    offset += width
  return (operands, offset)

proc toString*(instructions: Instructions): string =
  var i: int = 0
  result = ""

  while i < len(instructions):
    let
      definition = lookup(instructions[i])
      readResult: tuple[operands: seq[int], read: int] = readOperands(
        definition, instructions[i+1 .. len(instructions)-1]
      )
      operandCount = len(definition.operandWidths)
    case operandCount:
      of 0:
        result &= fmt"{i:04} {definition.name}"
      of 1:
        result &= fmt"{i:04} {definition.name} {readResult.operands[0]}"
      of 2:
        result &= fmt"{i:04} {definition.name} {readResult.operands[0]} {readResult.operands[1]}"
      else:
        result &= fmt"Error: Unhandled operatorCount for {definition.name}"

    result &= "\n"

    i += 1 + readResult.read

proc `$`*(instructions: Instructions): string =
  return toString(instructions)
