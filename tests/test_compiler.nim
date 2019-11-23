import unittest
from code import
  Opcode,
  make,
  Instructions,
  toString,
  OpConstant,
  OpAdd,
  OpPop
from lexer import newLexer, Lexer, nextToken, readCharacter
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from compiler import newCompiler, compile, toBytecode
from obj import Obj, inspect

proc parseSource(source: string): Node =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer=lexer)
    program: Node = parser.parseProgram()
  return program

type
  TestValueType* = enum
    TVTInt
  TestValue* = ref object
    case valueType*: TestValueType
      of TVTInt: intValue*: int
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

proc testIntObj(expected: int, actual: Obj): bool =
  if actual.intValue != expected:
    return false
  return true

proc testConstants(expected: seq[TestValue], actual: seq[Obj]) =
  let
    hasEqLength = len(expected) == len(actual)

  check(len(expected) == len(actual))

  if not hasEqLength:
    return

  for i, constant in expected:
    case constant.valueType:
      of TVTInt:
        check(testIntObj(constant.intValue, actual[i]))

suite "compiler tests":
  test "integer arithmetic":
    check 1 == 1
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
      ])
    ]

    for x in tests:
      let program = parseSource(x.input)
      var compiler = newCompiler()
      let err = compiler.compile(program)

      check(err == nil)

      let bytecode = compiler.toBytecode()
      testInstructions(x.expectedInstructions, bytecode.instructions)
      testConstants(x.expectedConstants, bytecode.constants)
