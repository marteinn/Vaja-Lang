import unittest
from lexer import newLexer, Lexer
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from obj import Obj, Env, newEnv, inspect
from evaluator import eval

proc evalSource(source:string): Obj =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer = lexer)
    program: Node = parser.parseProgram()
    env: Env = newEnv()
  return eval(program, env)

suite "eval tests":
  test "int expressions":
    type
      ExpectedEval = (string, string)
      ExpectedEvals = seq[ExpectedEval]
    var
      tests: ExpectedEvals = @[
        ("1", "1"),
        ("1+1", "2"),
        ("1-1", "0"),
        ("5*2", "10"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]
