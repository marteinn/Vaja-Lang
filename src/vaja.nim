import os
import times
import strutils, terminal
import sequtils
from strutils import startsWith, endsWith
from lexer import newLexer, Lexer
from ast import Node, toCode
from parser import newParser, Parser, parseProgram
from obj import Obj, Env, newEnv, inspect
from evaluator import eval, unwrapReturnValue
from eval_macro_expansion import defineMacros, expandMacros

type
  RunMode = enum
    RMRepl
    RMFile
    RMTestRunner
var
  mode: RunMode = RMRepl
  filePath: string = ""
  showReplExp: bool = false

when declared(commandLineParams):
  let
    cliArgs: seq[string] = commandLineParams()
    cliFlags = filter(cliArgs, proc (x: string): bool = x.startsWith("--"))
    execFiles = filter(cliArgs, proc (x: string): bool = x.endsWith(".vaja"))
  if len(execFiles) > 0:
    mode = RMFIle

  if "--show-exp" in cliFlags:
    showReplExp = true

  if "--test" in cliFlags:
    mode = RMTestRunner

if mode == RMRepl:
  echo "Väja (type exit() to quit)"

  var
    env: Env = newEnv()
    macroEnv: Env = newEnv()

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
  var
    env: Env = newEnv()
    macroEnv: Env = newEnv()
  let
    filePath = execFiles[0]
    fileContent = readFile(filePath)

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

if mode == RMTestRunner:
  echo "=== Running test framework === "
  stdout.write("Collecting tests...")
  stdout.flushFile

  let startTime = getTime()

  # Collect
  var
    suites: seq[(Obj, Env)] = @[]
    numTests: int = 0
    baseDir: string = getCurrentDir()

  for file in execFiles:
    setCurrentDir(baseDir)

    let fileContent = readFile(file)
    setCurrentDir(parentDir(file))

    var
      source: string = fileContent
      lexer: Lexer = newLexer(source=source)
      parser: Parser = newParser(lexer=lexer)
      program: Node = parser.parseProgram()
      env: Env = newEnv()
      macroEnv: Env = newEnv()

    defineMacros(program, macroEnv)

    let
      expandedProgram: Node = expandMacros(program, macroEnv)
      evaluated: Obj = eval(expandedProgram, env)

    suites.add((evaluated, env))
    numTests += len(evaluated.arrayElements[1].arrayElements)

  stdout.eraseLine
  stdout.write("Collected " & $numTests & " tests")
  stdout.flushFile

  # Run tests
  var failures: int = 0
  for suite in suites:
    var
      obj: Obj = suite[0]
      env: Env = suite[1]
    stdout.write("\n\n" & obj.arrayElements[0].strValue)

    for test in obj.arrayElements[1].arrayElements:
      stdout.write("\n" & test.arrayElements[0].inspect())
      stdout.write(" ")

      let res: Obj = eval(test.arrayElements[1].functionBody, env)
      let unwrappedRes: Obj = unwrapReturnValue(res)
      if unwrappedRes.boolValue:
        stdout.write("[OK]")
      else:
        failures += 1
        stdout.write("[FAIL]")

  # Output
  let duration = (getTime() - startTime)

  stdout.write("\n\nFinished in " & $duration)
  stdout.write("\n" & $numTests & " tests, " & $failures & " failtures")

  if failures == 0:
    quit(QuitSuccess)
  else:
    quit(QuitFailure)
