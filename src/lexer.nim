import nre
from token import TokenType, Token, newToken

type
  Lexer* = object
    source: string
    pos: int
    readPos: int
    ch: char
    eof: bool

method readCharacter*(lexer: var Lexer) {.base.} =
  var ch: char

  if lexer.readPos < len(lexer.source):
    ch = lexer.source[lexer.readPos]
  else:
    lexer.eof = true

  lexer.ch = ch
  lexer.pos = lexer.readPos
  lexer.readPos = lexer.readPos + 1

proc isInt(ch: char): bool =
  return ($ch).match(re"[0-9]").isSome()

proc isLetter(ch: char): bool =
  return ($ch).match(re"[a-zA-Z]|_").isSome()

method skipWhitespace(lexer: var Lexer) {.base.} =
  while lexer.ch == ' ':
    lexer.readCharacter()

method readIdentifier(lexer: var Lexer): string {.base.} =
  var startPos = lexer.pos
  while isLetter(lexer.ch):
    lexer.readCharacter()
  return lexer.source[startPos ..< lexer.pos]

method nextToken*(lexer: var Lexer): Token {.base.} =
  if lexer.eof:
      return newToken(tokenType=TokenType.EOF, literal="")

  skipWhitespace(lexer)

  var
    ch: char = lexer.ch
    tok: Token

  case ch:
    of '\n':
      tok = newToken(tokenType=TokenType.NEWLINE, literal=($ch))
    of '+':
      tok = newToken(tokenType=TokenType.PLUs, literal=($ch))
    of '-':
      tok = newToken(tokenType=TokenType.MINUS, literal=($ch))
    of '=':
      tok = newToken(tokenType=TokenType.ASSIGN, literal=($ch))
    of ';':
      tok = newToken(tokenType=TokenType.SEMICOLON, literal=($ch))
    of '*':
      tok = newToken(tokenType=TokenType.ASTERISK, literal=($ch))
    of '/':
      tok = newToken(tokenType=TokenType.SLASH, literal=($ch))
    elif isLetter(lexer.ch):
      var identifier = lexer.readIdentifier()
      case identifier:
        of "let":
          tok = newToken(tokenType=TokenType.LET, literal=identifier)
        else:
          tok = newToken(tokenType=TokenType.IDENT, literal=identifier)
    elif isInt(lexer.ch):
      tok = newToken(tokenType=TokenType.INT, literal=($ch))
    else:
      tok = newToken(tokenType=TokenType.ILLEGAL, literal=($ch))

  lexer.readCharacter()
  return tok

proc newLexer*(source: string): Lexer =
  var
    lexer:Lexer = Lexer(source: source, pos: 0, readPos: 0, eof: false)

  lexer.readCharacter()
  return lexer
