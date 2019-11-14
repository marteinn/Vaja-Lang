import unittest
from lexer import newLexer, Lexer
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from obj import Obj, ObjType, Env, newEnv, inspect
from evaluator import eval

proc evalSource(source:string): Obj =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer = lexer)
    program: Node = parser.parseProgram()
    env: Env = newEnv()
  return eval(program, env)

type
  ExpectedEval = (string, string)
  ExpectedEvals = seq[ExpectedEval]

suite "builtins string tests":
  test "String.len":
    var
      tests: ExpectedEvals = @[
        ("""String.len("abc")""", "3"),
        ("""String.len("")""", "0"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
  test "String.split":
    var
      tests: ExpectedEvals = @[
        ("""String.split(" ", "hello world")""", "[hello, world]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.join":
    var
      tests: ExpectedEvals = @[
        ("""let a = ["hello", "world"]; String.join(" ", a)""", "hello world"),
        ("""let a = [1, 1.1, "world"]; String.join(" ", a)""", "1 1.1 world"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.map":
    var
      tests: ExpectedEvals = @[
        ("""
String.map(
  fn (char)
    if (char == ".") "_" else char end
  end,
  "a.b.c"
)""", "a_b_c"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.filter":
    var
      tests: ExpectedEvals = @[
        ("""
String.filter(
  fn (char) -> char != ".",
  "a.b.c"
)""", "abc"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.reduce":
    var
      tests: ExpectedEvals = @[
        ("""
"abcdef" |> String.reduce(
  fn (acc, curr) -> curr,
  ""
)""", "f"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.append":
    var
      tests: ExpectedEvals = @[
        ("""String.append("abc", "def")""", "abcdef"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.split":
    var
      tests: ExpectedEvals = @[
        ("""String.split(" ", "hello world")""", "[hello, world]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.slice":
    var
      tests: ExpectedEvals = @[
        ("""String.slice(0, 4, "hello world")""", "hell"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.toUpper":
    var
      tests: ExpectedEvals = @[
        ("""String.toUpper("i am yelling")""", "I AM YELLING"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.toLower":
    var
      tests: ExpectedEvals = @[
        ("""String.toLower("I AM NOT YELLING")""", "i am not yelling"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.toArray":
    var
      tests: ExpectedEvals = @[
        ("""String.toArray("A LIST")""", "[A,  , L, I, S, T]"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.left":
    var
      tests: ExpectedEvals = @[
        ("""String.left(4, "Future days")""", "Futu"),
        ("""String.left(2, "Future days")""", "Fu"),
        ("""String.left(1, "Future days")""", "F"),
        ("""String.left(0, "Future days")""", ""),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.right":
    var
      tests: ExpectedEvals = @[
        ("""String.right(4, "Tago Mago")""", "Mago"),
        ("""String.right(2, "Tago Mago")""", "go"),
        ("""String.right(1, "Tago Mago")""", "o"),
        ("""String.right(0, "Tago Mago")""", ""),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

  test "String.contains":
    var
      tests: ExpectedEvals = @[
        ("""String.contains("Tago", "Tago Mago")""", "true"),
        ("""String.contains("Hello", "Tago Mago")""", "false"),
        ("""String.contains("go Ma", "Tago Mago")""", "true"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
