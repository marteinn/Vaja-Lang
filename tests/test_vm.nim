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
    if x[1].valueType == TVTVMError:
      echo vmErr.message
      check(x[1].vmErrorMsg == vmErr.message)
    else:
      check(vmErr == nil)
      let obj: Obj = vm.lastPoppedStackElement()
      testExpectedObj(x[1], obj)

suite "vm tests":
  test "calling builtins":
    let tests: seq[(string, TestValue)] = @[
      ("type([])",
        TestValue(
          valueType: TVTString,
          strValue: "array"
        )
      ),
      ("""let a = fn(x) type(x) end; a("hello")""",
        TestValue(
          valueType: TVTString,
          strValue: "string"
        )
      ),
      ("""Array.len([1])""",
        TestValue(
          valueType: TVTInt,
          intValue: 1
        )
      ),
    ]
    runTests(tests)

  test "calling with wrong number of arguments":
    let tests: seq[(string, TestValue)] = @[
      ("""let sum = fn(a, b) a+b end; sum(2)""",
        TestValue(
          valueType: TVTVMError,
          vmErrorMsg: "Incorrect number of arguments, expected 2, got 1"
        )
      ),
      ("""let sum = fn() 1 end; sum(2)""",
        TestValue(
          valueType: TVTVMError,
          vmErrorMsg: "Incorrect number of arguments, expected 0, got 1"
        )
      ),
    ]
    runTests(tests)

  test "calling functions with arguments and bindings":
    let tests: seq[(string, TestValue)] = @[
      ("""let a = fn(a) a end
a(5)""", TestValue(valueType: TVTInt, intValue: 5)),
    ("""let a = fn(a, b) a+b end
a(5, 3)""", TestValue(valueType: TVTInt, intValue: 8)),
      ("""let a = fn(a, b, c)
  let value = a+b
  value + c
end
a(5, 3, 7)""", TestValue(valueType: TVTInt, intValue: 15)),
    ("""let sum = fn(a, b)
  a+b
end
sum(2, 3) + sum(6, 4)""", TestValue(valueType: TVTInt, intValue: 15)),
      ("""let outer = fn(a, b)
  a+b
end
let inner = fn(a, b)
  outer(a, b)
end
inner(2, 3)""", TestValue(valueType: TVTInt, intValue: 5)),
      ("""let globalVal = 1
let sum = fn(a, b)
  let c = a + b
  c+globalVal
end
let outer = fn()
  sum(6, 2) + sum(2, 1) + globalVal
end
outer() + globalVal""", TestValue(valueType: TVTInt, intValue: 15)),
    ]
    runTests(tests)

  test "calling functions with binding":
    let tests: seq[(string, TestValue)] = @[
      ("""let a = fn()
  let value = 5
  value
end
a()""", TestValue(valueType: TVTInt, intValue: 5)),
      ("""let a = fn()
  let one = 1
  let two = 2
  one + two
end
a()""", TestValue(valueType: TVTInt, intValue: 3)),
      ("""let oneAndTwo = fn()
  let one = 1
  let two = 2
  one + two
end
let twoAndThree = fn()
  let two = 2
  let three = 3
  two + three
end
oneAndTwo() + twoAndThree()""", TestValue(valueType: TVTInt, intValue: 8)),
        ("""let a = fn()
  let value = 1
  return value
end
let b = fn()
  let value = 2
  return value
end
a() + b()""", TestValue(valueType: TVTInt, intValue: 3)),
      ("""let globalVal = 50
let a = fn()
  let value = 2
  globalVal - value
end
let b = fn()
  let value = 4
  globalVal + value
end
a() + b()""", TestValue(valueType: TVTInt, intValue: 102)),
    ]
    runTests(tests)

  test "function calls without args":
    let tests: seq[(string, TestValue)] = @[
      ("""let a = fn() 2 + 3 end
a()""", TestValue(valueType: TVTInt, intValue: 5)),
      ("""let one = fn() 1 end
let two = fn() 2 end
one() + two()""", TestValue(valueType: TVTInt, intValue: 3)),
    ("""let one = fn() 1 end
let two = fn() one() + 1 end
let three = fn() two() + 1 end
three()""", TestValue(valueType: TVTInt, intValue: 3)),
    ]
    runTests(tests)

  test "first class functions":
    let tests: seq[(string, TestValue)] = @[
      ("""let a = fn() 4 end
let b = fn() a end
b()()""", TestValue(valueType: TVTInt, intValue: 4)),
      ("""let a = fn()
    let one = fn() 1 end
    one
end
a()()""", TestValue(valueType: TVTInt, intValue: 1)),
    ]
    runTests(tests)

  test "function calls with returns":
    let tests: seq[(string, TestValue)] = @[
      ("""let a = fn()
  return 1
  2
end
a()""", TestValue(valueType: TVTInt, intValue: 1)),
    ]
    runTests(tests)

  test "function call with no return value":
    let tests: seq[(string, TestValue)] = @[
      ("""let a = fn() end
a()""", TestValue(valueType: TVTNil)),
      ("""let a = fn() end
let b = fn () a() end
b()""", TestValue(valueType: TVTNil)),
    ]
    runTests(tests)

  test "index operations":
    let tests: seq[(string, TestValue)] = @[
      ("[5, 2][0]", TestValue(valueType: TVTInt, intValue: 5)),
      ("[5,2,3][1+1]", TestValue(valueType: TVTInt, intValue: 3)),
      ("{\"a\": 55}.a", TestValue(valueType: TVTInt, intValue: 55)),
      ("""let val = {"a": 55}; val.a""", TestValue(valueType: TVTInt, intValue: 55)),
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

  test "closures":
    let tests: seq[(string, TestValue)] = @[
      ("""let newClosure = fn(a)
  fn() a end
end
let closure = newClosure(99)
closure()""", TestValue(valueType: TVTInt, intValue: 99)),
    ("""let newClosure = fn(a, b)
  let c = a + b
  fn(d)
    fn(e)
      c + d + e
    end
  end
end
let closure = newClosure(1, 2)
closure(3)(4)""", TestValue(valueType: TVTInt, intValue: 10)),

    ]
    runTests(tests)

  test "recursive function":
    let tests: seq[(string, TestValue)] = @[
      ("""let countDown = fn(x)
  if (x == 0)
    return 0
  else
    countDown(x - 1)
  end
end
countDown(1)""", TestValue(valueType: TVTInt, intValue: 0)),
    ]
    runTests(tests)
