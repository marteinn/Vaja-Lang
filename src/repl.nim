from lexer import newLexer, Lexer
from parser import newParser, Parser, parseProgram
from ast import toProgramCode

echo "Väja repl"
while true:
  var source: string = readLine(stdin)
  var lexer: Lexer = newLexer(source = source)
  var parser: Parser = newParser(lexer = lexer)
  var program = parser.parseProgram()
  echo program.toProgramCode()

