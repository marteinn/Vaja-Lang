import unittest
from code import
  Opcode,
  OpConstant,
  make,
  Instructions,
  toString,
  lookup,
  readOperands,
  OpAdd,
  OpGetLocal

suite "code tests":
  test "test make":
    let tests: seq[
      tuple[op: Opcode, operands: seq[int], expected: seq[byte]]
    ] = @[
      (OpConstant, @[65534], @[byte(OpConstant), 255, 254]),
      (OpAdd, @[], @[byte(OpAdd)]),
      (OpGetLocal, @[255], @[byte(OpGetLocal), 255])
    ]

    for x in tests:
      let instruction = make(x.op, x.operands)
      check instruction == x.expected

  test "instructions string":
    let instructions: seq[Instructions] = @[
      make(OpAdd, @[]),
      make(OpConstant, @[1]),
      make(OpConstant, @[2]),
      make(OpConstant, @[65535]),
    ]

    let expected = """0000 OpAdd
0001 OpConstant 1
0004 OpConstant 2
0007 OpConstant 65535
"""
    var concatted: Instructions = @[]
    for instruction in instructions:
      for x in instruction:
        concatted.add(x)

    check(toString(concatted) == expected)

  test "read operands":
    let tests: seq[
      tuple[op: Opcode, operands: seq[int], bytesRead: int]
    ] = @[
      (OpConstant, @[65534], 2),
      (OpConstant, @[65100], 2),
      (OpGetLocal, @[255], 1),
    ]

    for x in tests:
      let instruction = make(x.op, x.operands)
      let definition = lookup(byte(x.op))
      let res: tuple[operationsRead: seq[int], offset: int] = readOperands(
        definition, instruction[1 .. len(instruction)-1]
      )

      check(res.offset == x.bytesRead)

      for i, want in x.operands:
        check want == res.operationsRead[i]
