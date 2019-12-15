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
  OpCombine,
  OpArray,
  OpHashMap,
  OpIndex,
  OpReturn,
  OpReturnValue,
  OpCall,
  OpGetLocal,
  OpSetLocal
from lexer import newLexer, Lexer, nextToken, readCharacter
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from compiler import
  newCompiler,
  compile,
  toBytecode,
  emit,
  enterScope,
  leaveScope,
  EmittedInstruction
from obj import Obj, inspect, `$`
from symbol_table import SymbolTable
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
  test "let statement scopes":
    let tests: seq[CompilerTestCase] = @[
      (
        """let val = 5
fn () val end
""",
        @[
          TestValue(valueType: TVTInt, intValue: 5),
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpGetGlobal, @[0]),
              make(OpReturnValue),
          ])
        ],
        @[
          make(OpConstant, @[0]),
          make(OpSetGlobal, @[0]),
          make(OpConstant, @[1]),
          make(OpPop),
        ],
      ),
      (
        """fn()
  let num = 5
  num
end
""",
        @[
          TestValue(valueType: TVTInt, intValue: 5),
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpConstant, @[0]),
              make(OpSetLocal, @[0]),
              make(OpGetLocal, @[0]),
              make(OpReturnValue),
          ])
        ],
        @[
          make(OpConstant, @[1]),
          make(OpPop),
        ],
      ),
      (
        """fn()
  let a = 55
  let b = 77
  a + b
end
""",
        @[
          TestValue(valueType: TVTInt, intValue: 55),
          TestValue(valueType: TVTInt, intValue: 77),
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpConstant, @[0]),
              make(OpSetLocal, @[0]),
              make(OpConstant, @[1]),
              make(OpSetLocal, @[1]),
              make(OpGetLocal, @[0]),
              make(OpGetLocal, @[1]),
              make(OpAdd),
              make(OpReturnValue),
          ])
        ],
        @[
          make(OpConstant, @[2]),
          make(OpPop),
        ],
      ),
    ]
    runTests(tests)

  test "compiler scopes":
    var compiler = newCompiler()
    check(compiler.scopeIndex == 0)
    let globalSymbolTable: SymbolTable = compiler.symbolTable

    discard compiler.emit(OpMul)
    discard compiler.enterScope()

    check(len(compiler.scopes) == 2)
    check(compiler.scopeIndex == 1)

    discard compiler.emit(OpSub)
    check(len(compiler.scopes[compiler.scopeIndex].instructions) == 1)

    var lastInstruction: EmittedInstruction = compiler.scopes[compiler.scopeIndex].lastInstruction
    check(lastInstruction.opCode == OpSub)

    check(compiler.symbolTable.outer == globalSymbolTable)

    discard compiler.leaveScope()
    check(compiler.scopeIndex == 0)

    discard compiler.emit(OpAdd)
    check(len(compiler.scopes[compiler.scopeIndex].instructions) == 2)

    lastInstruction = compiler.scopes[compiler.scopeIndex].lastInstruction
    check(lastInstruction.opCode == OpAdd)

    var prevInstruction = compiler.scopes[compiler.scopeIndex].prevInstruction
    check(prevInstruction.opCode == OpMul)

    check(compiler.symbolTable == globalSymbolTable)
    check(compiler.symbolTable.outer == nil)

  test "function calls":
    let tests: seq[CompilerTestCase] = @[
      (
        "fn() 1 end()",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpConstant, @[0]),
              make(OpReturnValue),
          ])
        ],
        @[
          make(OpConstant, @[1]),
          make(OpCall, @[0]),
          make(OpPop),
        ],
      ),
      (
        """let a = fn() 1 end
a()""",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpConstant, @[0]),
              make(OpReturnValue),
          ])
        ],
        @[
          make(OpConstant, @[1]),
          make(OpSetGlobal, @[0]),
          make(OpGetGlobal, @[0]),
          make(OpCall, @[0]),
          make(OpPop),
        ],
      ),
      (
        """let a = fn(a) a end
a(55)""",
        @[
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpGetLocal, @[0]),
              make(OpReturnValue),
          ]),
          TestValue(valueType: TVTInt, intValue: 55),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpSetGlobal, @[0]),
          make(OpGetGlobal, @[0]),
          make(OpConstant, @[1]),
          make(OpCall, @[1]),
          make(OpPop),
        ],
      ),
      (
        """let a = fn(a, b)
    a
    b
end
a(55, 66)""",
        @[
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpGetLocal, @[0]),
              make(OpPop),
              make(OpGetLocal, @[1]),
              make(OpReturnValue),
          ]),
          TestValue(valueType: TVTInt, intValue: 55),
          TestValue(valueType: TVTInt, intValue: 66),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpSetGlobal, @[0]),
          make(OpGetGlobal, @[0]),
          make(OpConstant, @[1]),
          make(OpConstant, @[2]),
          make(OpCall, @[2]),
          make(OpPop),
        ],
      ),
    ]
    runTests(tests)

  test "functions":
    let tests: seq[CompilerTestCase] = @[
      (
        "fn() return 5 + 1 end",
        @[
          TestValue(valueType: TVTInt, intValue: 5),
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpConstant, @[0]),
              make(OpConstant, @[1]),
              make(OpAdd),
              make(OpReturnValue),
          ])
        ],
        @[
          make(OpConstant, @[2]),
          make(OpPop),
        ],
      ),
      (
        "fn() 5 + 1 end",
        @[
          TestValue(valueType: TVTInt, intValue: 5),
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpConstant, @[0]),
              make(OpConstant, @[1]),
              make(OpAdd),
              make(OpReturnValue),
          ])
        ],
        @[
          make(OpConstant, @[2]),
          make(OpPop),
        ],
      ),
      (
        "fn() end",
        @[
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpReturn),
          ])
        ],
        @[
          make(OpConstant, @[0]),
          make(OpPop),
        ],
      ),
      (
        """fn()
1
2
end""",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2),
          TestValue(
            valueType: TVTInstructions,
            instructions: @[
              make(OpConstant, @[0]),
              make(OpPop),
              make(OpConstant, @[1]),
              make(OpReturnValue),
          ])
        ],
        @[
          make(OpConstant, @[2]),
          make(OpPop),
        ],
      ),
    ]
    runTests(tests)

  test "index operations":
    let tests: seq[CompilerTestCase] = @[
      (
        "[1, 2][0]",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2),
          TestValue(valueType: TVTInt, intValue: 0),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpArray, @[2]),
          make(OpConstant, @[2]),
          make(OpIndex),
          make(OpPop),
      ]),
      (
        "[1, 2, 3][1+1]",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2),
          TestValue(valueType: TVTInt, intValue: 3),
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 1),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpConstant, @[2]),
          make(OpArray, @[3]),
          make(OpConstant, @[3]),
          make(OpConstant, @[4]),
          make(OpAdd),
          make(OpIndex),
          make(OpPop),
      ]),
      (
        "{\"a\": 1}[1+1]",
        @[
          TestValue(valueType: TVTString, strValue: "a"),
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 1),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpHashMap, @[2]),
          make(OpConstant, @[2]),
          make(OpConstant, @[3]),
          make(OpAdd),
          make(OpIndex),
          make(OpPop),
      ]),
    ]

    runTests(tests)
  test "hashmap":
    let tests: seq[CompilerTestCase] = @[
      (
        "{}",
        newSeq[TestValue](),
        @[
          make(OpHashMap, @[0]),
          make(OpPop),
      ]),
      (
        "{\"hello\": \"world\", \"goodbye\": \"world\"}",
        @[
          TestValue(valueType: TVTString, strValue: "hello"),
          TestValue(valueType: TVTString, strValue: "world"),
          TestValue(valueType: TVTString, strValue: "goodbye"),
          TestValue(valueType: TVTString, strValue: "world"),
        ],
        @[

          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpConstant, @[2]),
          make(OpConstant, @[3]),
          make(OpHashMap, @[4]),
          make(OpPop),
      ]),
    ]

    runTests(tests)

  test "arrays":
    let tests: seq[CompilerTestCase] = @[
      (
        "[]",
        newSeq[TestValue](),
        @[
          make(OpArray, @[0]),
          make(OpPop),
      ]),
      (
        "[1, 2, 3]",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2),
          TestValue(valueType: TVTInt, intValue: 3),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpConstant, @[2]),
          make(OpArray, @[3]),
          make(OpPop),
      ]),
      (
        "[1+1, 2+2, 3]",
        @[
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 1),
          TestValue(valueType: TVTInt, intValue: 2),
          TestValue(valueType: TVTInt, intValue: 2),
          TestValue(valueType: TVTInt, intValue: 3),
        ],
        @[
          make(OpConstant, @[0]),
          make(OpConstant, @[1]),
          make(OpAdd),
          make(OpConstant, @[2]),
          make(OpConstant, @[3]),
          make(OpAdd),
          make(OpConstant, @[4]),
          make(OpArray, @[3]),
          make(OpPop),
      ]),
    ]

    runTests(tests)
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
