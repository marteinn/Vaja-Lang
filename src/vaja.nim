import os
from lexer import newLexer, Lexer
from ast import Node, toCode
from parser import newParser, Parser, parseProgram
from obj import Obj, Env, newEnv, inspect
from evaluator import eval

type
  RunMode = enum
    RMRepl
    RMFile
var
  mode: RunMode = RMRepl
  filePath: string = ""
  env: Env = newEnv()

when declared(commandLineParams):
  var cliArgs = commandLineParams()
  if len(cliArgs) > 0:
    filePath = cliArgs[0]
    mode = RMFIle

if mode == RMRepl:
  echo "Väja"

  while true:
    stdout.write ">> "
    var
      source: string = readLine(stdin)
      lexer: Lexer = newLexer(source = source)
      parser: Parser = newParser(lexer = lexer)
      program: Node = parser.parseProgram()
      evaluated: Obj = eval(program, env)
    # echo evaluated.inspect()
    echo program.toCode() & " = " & evaluated.inspect()

if mode == RMFile:
  let fileContent = readFile(filePath)
  setCurrentDir(parentDir(filePath))

  var
    source: string = fileContent
    lexer: Lexer = newLexer(source=source)
    parser: Parser = newParser(lexer=lexer)
    program: Node = parser.parseProgram()
    evaluated: Obj = eval(program, env)
  echo evaluated.inspect()
