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
      of 2:
        instruction[offset] = byte(operand shr 8 and 0xFF)
        instruction[offset+1] = byte(operand and 0xFF)
      else:
        discard

    offset += width
  return instruction

proc readUint16*(instructions: Instructions): int =
  return int(
    uint16(instructions[1]) or uint16(instructions[0]) shl 8
  )

proc readOperands*(
  definition: Definition, instructions: Instructions): (seq[int], int
) =
  var
    operands: seq[int] = newSeq[int](len(definition.operandWidths))
    offset: int = 0

  for i, width in definition.operandWidths:
    case width:
      of 2:
        #operands[i] = int(uint16(instructions[1]) or uint16(instructions[0]) shl 8)
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
      else:
        result &= fmt"Error: Unhandled operatorCount for {definition.name}"

    result &= "\n"

    i += 1 + readResult.read
