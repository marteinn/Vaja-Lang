from lexer import newLexer, Lexer
from ast import Node, toCode
from parser import newParser, Parser, parseProgram
from obj import Obj, Env, newEnv, inspect
from evaluator import eval

echo "Väja repl"
while true:
  var
    source: string = readLine(stdin)
    lexer: Lexer = newLexer(source = source)
    parser: Parser = newParser(lexer = lexer)
    program: Node = parser.parseProgram()
    env: Env = newEnv()
    evaluated: Obj = eval(program, env)
  echo program.toCode() & "> " & evaluated.inspect()
