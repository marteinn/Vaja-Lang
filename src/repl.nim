from lexer import newLexer, Lexer
from ast import Node, toCode
from parser import newParser, Parser, parseProgram
from obj import Obj, Env, newEnv, inspect
from evaluator import eval

echo "Väja"
var env: Env = newEnv()
while true:
  stdout.write ">> "
  var
    source: string = readLine(stdin)
    lexer: Lexer = newLexer(source = source)
    parser: Parser = newParser(lexer = lexer)
    program: Node = parser.parseProgram()
    evaluated: Obj = eval(program, env)
  echo evaluated.inspect()
  #echo program.toCode() & " = " & evaluated.inspect()
