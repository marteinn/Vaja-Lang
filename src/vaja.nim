import os
import times
import strutils, terminal
import sequtils
import tables
from strutils import startsWith, endsWith
from lexer import newLexer, Lexer
from ast import Node, toCode
from parser import newParser, Parser, parseProgram
from obj import Obj, Env, newEnv, setVar, newHashMap, inspect, ObjType
from evaluator import eval, unwrapReturnValue
from eval_macro_expansion import defineMacros, expandMacros
from compiler import newCompiler, compile, toBytecode
from vm import VM, newVM, runVM, stackTop

type
  RunMode = enum
    RMRepl
    RMFile
    RMTestRunner
var
  mode: RunMode = RMRepl
  filePath: string = ""
  showReplExp: bool = false
  useVM: bool = false

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

  if "--vm" in cliFlags:
    useVM = true

if mode == RMRepl:
  if useVM:
    echo "Väja (with VM) (type exit() to quit)"
  else:
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
      inspected: string

    if useVM:
      var compiler = newCompiler()
      let compilerErr = compiler.compile(expandedProgram)
      if compilerErr != nil:
        stdout.write "Compilation failed " & compilerErr.message
        quit(QuitFailure)

      var vm: VM = newVM(compiler.toBytecode())
      let vmErr = vm.runVM()
      if vmErr != nil:
        stdout.write "Bytecode execution failed" & vmErr.message
        quit(QuitFailure)

      let stackTop: Obj = vm.stackTop()
      inspected = stackTop.inspect()
    else:
      let evaluated: Obj = eval(expandedProgram, env)
      inspected = evaluated.inspect()

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
    suites: seq[tuple[suite: Obj, tests: seq[Obj], env: Env, setUp: Obj]] = @[]
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

    let
      tests: seq[Obj] = filter(
        evaluated.arrayElements[1].arrayElements,
        proc (x: Obj): bool =
          x.arrayElements[0].strValue == "test"
        )
      setupList: seq[Obj] = filter(
        evaluated.arrayElements[1].arrayElements,
        proc (x: Obj): bool =
          x.arrayElements[0].strValue == "setup"
        )
      setup: Obj = if len(setupList) > 0: setupList[0] else: nil

    numTests += len(tests)
    suites.add((suite: evaluated, tests: tests, env: env, setup: setup))

  stdout.eraseLine
  stdout.write("Collected " & $numTests & " tests")
  stdout.flushFile

  # Run tests
  var failures: int = 0
  for suite in suites:
    var
      obj: Obj = suite.suite
      env: Env = suite.env
      setup: Obj = suite.setup
    stdout.write("\n\n" & obj.arrayElements[0].strValue)


    for test in suite.tests:
      stdout.write("\n" & test.arrayElements[1].inspect())
      stdout.write(" ")

      var
        testEnv = deepCopy(env)
        setupEnv = deepCopy(env)
        testState: Obj

      if setup != nil:
        testState = eval(setup.arrayElements[1].functionBody, setupEnv)
      else:
        testState = newHashMap(hashMapElements=initOrderedTable[string, Obj]())

      testEnv = setVar(testEnv, "state", testState)

      let
        res: Obj = eval(test.arrayElements[2].functionBody, testEnv)
        unwrappedRes: Obj = unwrapReturnValue(res)
      if unwrappedRes.objType == ObjType.OTBoolean and unwrappedRes.boolValue:
        stdout.write("[OK]")
      else:
        if unwrappedRes.objType == OTError:
          stdout.write("[FAIL - " & unwrappedRes.errorMsg & "]")
        else:
          stdout.write("[FAIL]")

        failures += 1

  # Output
  let duration = (getTime() - startTime)

  stdout.write("\n\nFinished in " & $duration)
  stdout.write("\n" & $numTests & " tests, " & $failures & " failtures")

  if failures == 0:
    quit(QuitSuccess)
  else:
    quit(QuitFailure)
