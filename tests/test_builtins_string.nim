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
