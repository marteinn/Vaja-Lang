import os
import sequtils
from strutils import startsWith, endsWith
from lexer import newLexer, Lexer
from ast import Node, toCode
from parser import newParser, Parser, parseProgram
from obj import Obj, Env, newEnv, inspect
from evaluator import eval
from eval_macro_expansion import defineMacros, expandMacros

type
  RunMode = enum
    RMRepl
    RMFile
var
  mode: RunMode = RMRepl
  filePath: string = ""
  env: Env = newEnv()
  macroEnv: Env = newEnv()
  showReplExp: bool = false

when declared(commandLineParams):
  let
    cliArgs: seq[string] = commandLineParams()
    cliFlags = filter(cliArgs, proc (x: string): bool = x.startsWith("--"))
    execFiles = filter(cliArgs, proc (x: string): bool = x.endsWith(".vaja"))
  if len(execFiles) > 0:
    filePath = execFiles[0]
    mode = RMFIle

  if "--show-exp" in cliFlags:
    showReplExp = true

if mode == RMRepl:
  echo "Väja (type exit() to quit)"

  while true:
    stdout.write ">> "
    var
      source: string = readLine(stdin)
      lexer: Lexer = newLexer(source = source)
      parser: Parser = newParser(lexer = lexer)
      program: Node = parser.parseProgram()

    defineMacros(program, macroEnv)

    var
      expandedProgram: Node = expandMacros(program, macroEnv)
      evaluated: Obj = eval(expandedProgram, env)
    let
      inspected: string = evaluated.inspect()

    if len(inspected) > 0 and showReplExp:
      echo program.toCode() & " = " & inspected
    if len(inspected) > 0 and not showReplExp:
      echo inspected

if mode == RMFile:
  let fileContent = readFile(filePath)
  setCurrentDir(parentDir(filePath))

  var
    source: string = fileContent
    lexer: Lexer = newLexer(source=source)
    parser: Parser = newParser(lexer=lexer)
    program: Node = parser.parseProgram()

  defineMacros(program, macroEnv)

  let
    expandedProgram: Node = expandMacros(program, macroEnv)
    evaluated: Obj = eval(expandedProgram, env)
  echo evaluated.inspect()
