import unittest
import tables
from lexer import newLexer, Lexer
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from obj import Obj, inspect, `$`
from compiler import newCompiler, compile, toBytecode
from vm import VM, newVM, runVM, lastPoppedStackElement
from helpers import TestValueType, TestValue, `==`, `$`

proc parseSource(source: string): Node =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer=lexer)
    program: Node = parser.parseProgram()
  return program

proc testExpectedObj(expected: TestValue, actual: Obj) =
  check(expected == actual)

proc runTests(tests: seq[(string, TestValue)]) =
  for x in tests:
    let program = parseSource(x[0])
    var compiler = newCompiler()
    let compilerErr = compiler.compile(program)
    check(compilerErr == nil)

    var vm: VM = newVM(compiler.toBytecode())
    let vmErr = vm.runVM()
    check(vmErr == nil)
    let obj: Obj = vm.lastPoppedStackElement()

    testExpectedObj(x[1], obj)

suite "vm tests":
  test "function calls":
    let tests: seq[(string, TestValue)] = @[
      ("""let a = fn() 2 + 3 end
a()""", TestValue(valueType: TVTInt, intValue: 5)),
    ]
    runTests(tests)

  test "index operations":
    let tests: seq[(string, TestValue)] = @[
      ("[5, 2][0]", TestValue(valueType: TVTInt, intValue: 5)),
      ("[5,2,3][1+1]", TestValue(valueType: TVTInt, intValue: 3)),
      ("{\"a\": 55}.a", TestValue(valueType: TVTInt, intValue: 55)),
    ]
    runTests(tests)

  test "hashmap":
    let tests: seq[(string, TestValue)] = @[
      ("{}", TestValue(
        valueType: TVTHashMap,
        hashMapElements: initOrderedTable[string, TestValue]()
      )),
      ("{\"a\": 1}", TestValue(
        valueType: TVTHashMap,
        hashMapElements: {
          "a": TestValue(valueType: TVTInt, intValue: 1),
        }.toOrderedTable
      )),
      ("{\"a\": 1, \"b\": [1]}", TestValue(
        valueType: TVTHashMap,
        hashMapElements: {
          "a": TestValue(valueType: TVTInt, intValue: 1),
          "b": TestValue(valueType: TVTArray, arrayElements: @[
            TestValue(valueType: TVTInt, intValue: 1),
          ]),
        }.toOrderedTable
      )),
      ("{\"a\": 1, \"b\": 2};1", TestValue(
        valueType: TVTInt,
        intValue: 1
      )),
    ]
    runTests(tests)

  test "arrays":
    let tests: seq[(string, TestValue)] = @[
      ("[]", TestValue(valueType: TVTArray, arrayElements: @[])),
      ("[1, 2, 3]", TestValue(valueType: TVTArray, arrayElements: @[
        TestValue(valueType: TVTInt, intValue: 1),
        TestValue(valueType: TVTInt, intValue: 2),
        TestValue(valueType: TVTInt, intValue: 3),
      ])),
      ("[1 + 2, 2 + 3, 3 + 4]", TestValue(valueType: TVTArray, arrayElements: @[
        TestValue(valueType: TVTInt, intValue: 3),
        TestValue(valueType: TVTInt, intValue: 5),
        TestValue(valueType: TVTInt, intValue: 7),
      ])),
      ("[1, 2, 3]; 1", TestValue(valueType: TVTInt, intValue: 1)),
    ]

    runTests(tests)

  test "string expressions":
    let tests: seq[(string, TestValue)] = @[
      ("\"Hello world\"", TestValue(valueType: TVTString, strValue: "Hello world")),
      ("\"Hello\" ++ \"world\"", TestValue(valueType: TVTString, strValue: "Helloworld")),
    ]

    runTests(tests)

  test "assignment statements":
    let tests: seq[(string, TestValue)] = @[
      ("let one = 1; one", TestValue(valueType: TVTInt, intValue: 1)),
      ("let one = 1; let two = 2; one + two", TestValue(valueType: TVTInt, intValue: 3)),
      ("let one = 1; let two = one + 1; one + two", TestValue(valueType: TVTInt, intValue: 3)),
    ]

    runTests(tests)

  test "if statements":
    let tests: seq[(string, TestValue)] = @[
      ("if (true) 10 end", TestValue(valueType: TVTInt, intValue: 10)),
      ("if (true) 1 else 2 end", TestValue(valueType: TVTInt, intValue: 1)),
      ("if (false) 1 else 2 end", TestValue(valueType: TVTInt, intValue: 2)),
      ("if (false) 10 end", TestValue(valueType: TVTNil)),
      ("if (if (false) true else false end) 10 else 20 end", TestValue(
        valueType: TVTInt, intValue: 20
      )),
    ]

    runTests(tests)

  test "expected integer arthmetic":
    let tests: seq[(string, TestValue)] = @[
      ("1", TestValue(valueType: TVTInt, intValue: 1)),
      ("2", TestValue(valueType: TVTInt, intValue: 2)),
      ("1 + 2", TestValue(valueType: TVTInt, intValue: 3)),
      ("2 - 1", TestValue(valueType: TVTInt, intValue: 1)),
      ("2 * 2", TestValue(valueType: TVTInt, intValue: 4)),
      ("4 / 2", TestValue(valueType: TVTFloat, floatValue: 2.0)),
      ("-1", TestValue(valueType: TVTInt, intValue: -1)),
      ("-10", TestValue(valueType: TVTInt, intValue: -10)),
      ("-50 + 20", TestValue(valueType: TVTInt, intValue: -30)),
      ("((5 + 10) * 2 + -10) / 2", TestValue(valueType: TVTFloat, floatValue: 10.0)),
    ]

    runTests(tests)

  test "boolean expressions":
    let tests: seq[(string, TestValue)] = @[
      ("true", TestValue(valueType: TVTBool, boolValue: true)),
      ("false", TestValue(valueType: TVTBool, boolValue: false)),
      ("1 < 2", TestValue(valueType: TVTBool, boolValue: true)),
      ("1 > 2", TestValue(valueType: TVTBool, boolValue: false)),
      ("1 < 1", TestValue(valueType: TVTBool, boolValue: false)),
      ("1 > 1", TestValue(valueType: TVTBool, boolValue: false)),
      ("1 == 1", TestValue(valueType: TVTBool, boolValue: true)),
      ("1 == 2", TestValue(valueType: TVTBool, boolValue: false)),
      ("1 != 1", TestValue(valueType: TVTBool, boolValue: false)),
      ("2 != 1", TestValue(valueType: TVTBool, boolValue: true)),
      ("true == true", TestValue(valueType: TVTBool, boolValue: true)),
      ("true == false", TestValue(valueType: TVTBool, boolValue: false)),
      ("true != false", TestValue(valueType: TVTBool, boolValue: true)),
      ("(2 > 1) == true", TestValue(valueType: TVTBool, boolValue: true)),
      ("not true", TestValue(valueType: TVTBool, boolValue: false)),
      ("not false", TestValue(valueType: TVTBool, boolValue: true)),
      ("not (2 > 1)", TestValue(valueType: TVTBool, boolValue: false)),
      ("not (if (false) true end)", TestValue(valueType: TVTBool, boolValue: true)),
    ]

    runTests(tests)
