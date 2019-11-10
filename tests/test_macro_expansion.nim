import unittest
from lexer import newLexer, Lexer
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode
from obj import Obj, ObjType, Env, newEnv, inspect, containsVar, inspect, getVar
from evaluator import eval
from eval_macro_expansion import defineMacros, expandMacros

type
  ExpectedEval = (string, string)
  ExpectedEvals = seq[ExpectedEval]

suite "macro expansipon tests":
  test "defineMacros":
    var
      source = """
let myVar = 1
fn hello(x) print(x) end
macro myMacro(x, y) x + y end
let anotherMacro = macro (x, y) x + y end
let hello = 3
"""

    var
      lexer: Lexer = newLexer(source)
      parser: Parser = newParser(lexer = lexer)
      program: Node = parser.parseProgram()
      env: Env = newEnv()
    defineMacros(program, env)

    check len(program.statements) == 3
    check containsVar(env, "myMacro") == true
    check containsVar(env, "anotherMacro") == true
    check getVar(env, "myMacro").inspect() == "macro (x, y) (x + y) end"

  test "macro expansion":
    var
      tests: ExpectedEvals = @[
        ("""
macro infixExpression ()
  quote(1 + 2)
end
infixExpression()
""", "(1 + 2)"),
        ("""
let reverse = macro (a, b)
  quote(unquote(b) - unquote(a))
end
reverse(2 + 2, 10 - 5)
""", "((10 - 5) - (2 + 2))")
      ]

    for testPair in tests:
      let source = testPair[0]
      var
        lexer: Lexer = newLexer(source)
        parser: Parser = newParser(lexer = lexer)
        program: Node = parser.parseProgram()
        env: Env = newEnv()
        macroEnv: Env = newEnv()

      defineMacros(program, macroEnv)
      let expanded: Node = expandMacros(program, macroEnv)
      check expanded.toCode() == testPair[1]

  test "unless macro":
    var
      source = """
macro unless(condition, consequence, alternative)
  quote(if (not unquote(condition))
      unquote(consequence)
    else
      unquote(alternative)
    end)
end
unless(1 > 2, true, false)
"""

    var
      lexer: Lexer = newLexer(source)
      parser: Parser = newParser(lexer = lexer)
      program: Node = parser.parseProgram()
      env: Env = newEnv()

    defineMacros(program, env)
    let expanded: Node = expandMacros(program, env)
    check expanded.toCode() == "if ((not (1 > 2))) true else false end"
