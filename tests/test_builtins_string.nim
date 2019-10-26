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

  test "String.slice":
    var
      tests: ExpectedEvals = @[
        ("""String.slice(0, 4, "hello world")""", "hello"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
  test "String.split":
    var
      tests: ExpectedEvals = @[
        ("""String.split(" ", "hello world")""", "[hello, world]"),
      ]