import os
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

suite "builtins io tests":
  test "IO.readFile":
    writeFile("example_read.txt", "Example text")

    var
      tests: ExpectedEvals = @[
        ("""IO.readFile("example_read.txt")""", "Example text"),
      ]

    for testPair in tests:
      var evaluated: Obj = evalSource(testPair[0])
      check evaluated.inspect() == testPair[1]

    removeFile("example_read.txt")
