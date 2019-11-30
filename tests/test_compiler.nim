import unittest
import strformat
from code import
  Opcode,
  make,
  Instructions,
  toString,
  OpConstant,
  OpAdd,
  OpPop,
  OpSub,
  OpMul,
  OpDiv,
  OpTrue,
  OpFalse,
  OpEqual,
  OpNotEqual,
  OpGreaterThan,
  OpMinus,
  OpNot,
  OpJump,
  OpJumpNotThruthy,
  OpNil,
  OpGetGlobal,
  OpSetGlobal,
  OpCombine
from lexer import newLexer, Lexer, nextToken, readCharacter
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from compiler import newCompiler, compile, toBytecode
from obj import Obj, inspect, `$`
from helpers import TestValueType, TestValue, `==`, `$`

proc parseSource(source: string): Node =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer=lexer)
    program: Node = parser.parseProgram()
  return program

type
  CompilerTestCase = tuple[
    input: string,
    expectedConstants: seq[TestValue],
    expectedInstructions: seq[Instructions]
  ]

proc flattenInstructions(instructions: seq[Instructions]): Instructions =
  result = @[]

  for x in instructions:
    for y in x:
      result.add(y)

proc testInstructions(expected: seq[Instructions], actual: Instructions) =
  let
    flatExpected = flattenInstructions(expected)
    hasEqLength = len(flatExpected) == len(actual)

  check(len(flatExpected) == len(actual))
  check(toString(flatExpected) == toString(actual))

  if not hasEqLength:
    return

  for i, instruction in flatExpected:
    check(actual[i] == instruction)

proc testConstants(expected: seq[TestValue], actual: seq[Obj]) =
  let
    hasEqLength = len(expected) == len(actual)

  check(len(expected) == len(actual))

  if not hasEqLength:
    return

  for i, constant in expected:
    check(constant == actual[i])

proc runTests(tests: seq[CompilerTestCase]) =
  for x in tests:
    let program = parseSource(x.input)
    var compiler = newCompiler()
    let err = compiler.compile(program)
    if err != nil:
      echo fmt"Compile contains error: {err.message}"

    check(err == nil)

    let bytecode = compiler.toBytecode()
    testInstructions(x.expectedInstructions, bytecode.instructions)
    testConstants(x.expectedConstants, bytecode.constants)

suite "compiler tests":
  test "strings":
    let tests: seq[CompilerTestCase] = @[
      (
        "\"Hello world\"",
        @[
          TestValue(valueType: TVTString, strValue: "Hello world"),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpPop),
      ]),
      (
        "\"Hello\" ++ \"world\"",
        @[
          TestValue(valueType: TVTString, strValue: "Hello"),
          TestValue(valueType: TVTString, strValue: "world"),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpCombine),
          make(OpPop),
      ]),
    ]

    runTests(tests)

  test "assignment":
    let tests: seq[CompilerTestCase] = @[
      (
        "let one = 1; let two = 2;",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpSetGlobal, @[0]),
          make(OpConstant, @[1]),
          make(OpSetGlobal, @[1]),
      ]),
      (
        "let one = 1; one;",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpSetGlobal, @[0]),
          make(OpGetGlobal, @[0]),
          make(OpPop),
      ]),
      (
        "let one = 1; let two = one; two;",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpSetGlobal, @[0]),
          make(OpGetGlobal, @[0]),
          make(OpSetGlobal, @[1]),
          make(OpGetGlobal, @[1]),
          make(OpPop),
      ]),
    ]

    runTests(tests)

  test "conditionals":
    let tests: seq[CompilerTestCase] = @[
      (
        "if (true) 10 end; 3333",
        @[
          TestValue(valueType: TVTInt, intValue: 10),
          TestValue(valueType: TVTInt, intValue: 3333),
        ],
        @[
          make(OpTrue),
          make(OpJumpNotThruthy, @[10]),
          make(OpConstant, @[0]),
          make(OpJump, @[11]),
          make(OpNil),
          make(OpPop),
          make(OpConstant, @[1]),
          make(OpPop),
      ]),
      (
        "if (true) 10 else 20 end; 3333",
        @[
          TestValue(valueType: TVTInt, intValue: 10),
          TestValue(valueType: TVTInt, intValue: 20),
          TestValue(valueType: TVTInt, intValue: 3333),
        ],
        @[
          make(OpTrue),
          make(OpJumpNotThruthy, @[10]),
          make(OpConstant, @[0]),
          make(OpJump, @[13]),
          make(OpConstant, @[1]),
          make(OpPop),
          make(OpConstant, @[2]),
          make(OpPop),
      ]),
    ]

    runTests(tests)

  test "boolean expressions":
    let tests: seq[CompilerTestCase] = @[
      (
        "true",
        newSeq[TestValue](),
        @[
          make(OpTrue, @[]),
          make(OpPop, @[]),
      ]),
      (
        "false",
        newSeq[TestValue](),
        @[
          make(OpFalse, @[]),
          make(OpPop, @[]),
      ]),
      (
        "not false",
        newSeq[TestValue](),
        @[
          make(OpFalse, @[]),
          make(OpNot, @[]),
          make(OpPop, @[]),
      ]),
      (
        "1 > 2",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2)
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpGreaterThan, @[]),
          make(OpPop, @[]),
      ]),
      (
        "1 < 2",
        @[
          TestValue(valueType: TVTInt, intValue: 2),
          TestValue(valueType: TVTInt, intValue: 1),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpGreaterThan, @[]),
          make(OpPop, @[]),
      ]),
      (
        "1 == 2",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2)
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpEqual, @[]),
          make(OpPop, @[]),
      ]),
      (
        "1 != 2",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2)
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpNotEqual, @[]),
          make(OpPop, @[]),
      ]),
      (
        "true == false",
        newSeq[TestValue](),
        @[
          make(OpTrue, @[]),
          make(OpFalse, @[]),
          make(OpEqual, @[]),
          make(OpPop, @[]),
      ]),
      (
        "true != false",
        newSeq[TestValue](),
        @[
          make(OpTrue, @[]),
          make(OpFalse, @[]),
          make(OpNotEqual, @[]),
          make(OpPop, @[]),
      ]),
    ]

    runTests(tests)

  test "integer arithmetic":
    let tests: seq[CompilerTestCase] = @[
      (
        "1 + 2",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2)
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpAdd, @[]),
          make(OpPop, @[]),
      ]),
      (
        "1; 2",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2)
        ],
        @[
          make(OpConstant, @[0]),
          make(OpPop, @[]),
          make(OpConstant, @[1]),
          make(OpPop, @[]),
      ]),
      (
        "1 - 2",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2)
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpSub, @[]),
          make(OpPop, @[]),
      ]),
      (
        "1 * 2",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2)
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpMul, @[]),
          make(OpPop, @[]),
      ]),
      (
        "1 / 2",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2)
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpDiv, @[]),
          make(OpPop, @[]),
      ]),
      (
        "-1",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpMinus, @[]),
          make(OpPop, @[]),
      ])
    ]

    runTests(tests)
