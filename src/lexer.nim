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

method peekAhead*(lexer: var Lexer, steps: int): char {.base.} =
  if lexer.readPos + steps >= len(lexer.source):
    return
  else:
    return lexer.source[lexer.readPos + steps]

proc isInt(ch: char): bool =
  return ($ch).match(re"[0-9]").isSome()

proc isLetter(ch: char): bool =
  return ($ch).match(re"[a-zA-Z]|_").isSome()

method skipWhitespace(lexer: var Lexer) {.base.} =
  while lexer.ch == ' ':
    lexer.readCharacter()

method readNumber(lexer: var Lexer): string {.base.} =
  var startPos = lexer.pos
  while (isInt(lexer.ch) or lexer.ch == '.') and not lexer.eof:
    lexer.readCharacter()
  return lexer.source[startPos ..< lexer.pos]

method readIdentifier(lexer: var Lexer): string {.base.} =
  var startPos = lexer.pos
  while (isLetter(lexer.ch) or isInt(lexer.ch)) and not lexer.eof:
    lexer.readCharacter()
  return lexer.source[startPos ..< lexer.pos]

method readString(lexer: var Lexer): string {.base.} =
  lexer.readCharacter()

  var stringOut: string = $lexer.ch

  while true:
    lexer.readCharacter()

    if lexer.ch == '"':
      break

    stringOut = stringOut & lexer.ch

  return stringOut

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
      tok = newToken(tokenType=TokenType.PLUS, literal=($ch))
    of '-':
      if lexer.peekAhead(0) == '>':
        var nextCh: char = lexer.peekAhead(0)
        lexer.readCharacter()
        tok = newToken(tokenType=TokenType.RARROW, literal=($ch & $nextCh))
      else:
        tok = newToken(tokenType=TokenType.MINUS, literal=($ch))
    of '%':
      tok = newToken(tokenType=TokenType.MODULO, literal=($ch))
    of '(':
      tok = newToken(tokenType=TokenType.LPAREN, literal=($ch))
    of ')':
      tok = newToken(tokenType=TokenType.RPAREN, literal=($ch))
    of '[':
      tok = newToken(tokenType=TokenType.LBRACKET, literal=($ch))
    of ']':
      tok = newToken(tokenType=TokenType.RBRACKET, literal=($ch))
    of '{':
      tok = newToken(tokenType=TokenType.LBRACE, literal=($ch))
    of '}':
      tok = newToken(tokenType=TokenType.RBRACE, literal=($ch))
    of '&':
      tok = newToken(tokenType=TokenType.AMP, literal=($ch))
    of ',':
      tok = newToken(tokenType=TokenType.COMMA, literal=($ch))
    of ':':
      tok = newToken(tokenType=TokenType.COLON, literal=($ch))
    of '$':
      tok = newToken(tokenType=TokenType.DOLLAR, literal=($ch))
    of '|':
      if lexer.peekAhead(0) == '>':
        var nextCh: char = lexer.peekAhead(0)
        lexer.readCharacter()
        tok = newToken(tokenType=TokenType.PIPERARROW, literal=($ch & $nextCh))
    of '>':
      if lexer.peekAhead(0) == '=':
        var nextCh: char = lexer.peekAhead(0)
        lexer.readCharacter()
        tok = newToken(tokenType=TokenType.GTE, literal=($ch & $nextCh))
      else:
        tok = newToken(tokenType=TokenType.GT, literal=($ch))
    of '<':
      if lexer.peekAhead(0) == '=':
        var nextCh: char = lexer.peekAhead(0)
        lexer.readCharacter()
        tok = newToken(tokenType=TokenType.LTE, literal=($ch & $nextCh))
      else:
        tok = newToken(tokenType=TokenType.LT, literal=($ch))
    of '!':
      if lexer.peekAhead(0) == '=':
        var nextCh: char = lexer.peekAhead(0)
        lexer.readCharacter()
        tok = newToken(tokenType=TokenType.NOT_EQ, literal=($ch & $nextCh))
      else:
        tok = newToken(tokenType=TokenType.BANG, literal=($ch))
    of '=':
      if lexer.peekAhead(0) == '=':
        var nextCh: char = lexer.peekAhead(0)
        lexer.readCharacter()
        tok = newToken(tokenType=TokenType.EQ, literal=($ch & $nextCh))
      else:
        tok = newToken(tokenType=TokenType.ASSIGN, literal=($ch))
    of ';':
      tok = newToken(tokenType=TokenType.SEMICOLON, literal=($ch))
    of '*':
      if lexer.peekAhead(0) == '*':
        var nextCh: char = lexer.peekAhead(0)
        lexer.readCharacter()
        tok = newToken(tokenType=TokenType.EXPONENT, literal=($ch & $nextCh))
      else:
        tok = newToken(tokenType=TokenType.ASTERISK, literal=($ch))
    of '/':
      tok = newToken(tokenType=TokenType.SLASH, literal=($ch))
    of '"':
      var stringValue = lexer.readString()
      tok = newToken(tokenType=TokenType.STRING, literal=stringValue)
    elif isLetter(lexer.ch):
      var identifier = lexer.readIdentifier()
      case identifier:
        of "let":
          tok = newToken(tokenType=TokenType.LET, literal=identifier)
        of "true":
          tok = newToken(tokenType=TokenType.TRUE, literal=identifier)
        of "false":
          tok = newToken(tokenType=TokenType.FALSE, literal=identifier)
        of "and":
          tok = newToken(tokenType=TokenType.AND, literal=identifier)
        of "or":
          tok = newToken(tokenType=TokenType.OR, literal=identifier)
        of "not":
          tok = newToken(tokenType=TokenType.NOT, literal=identifier)
        of "fn":
          tok = newToken(tokenType=TokenType.FUNCTION, literal=identifier)
        of "end":
          tok = newToken(tokenType=TokenType.END, literal=identifier)
        of "return":
          tok = newToken(tokenType=TokenType.RETURN, literal=identifier)
        of "if":
          tok = newToken(tokenType=TokenType.IF, literal=identifier)
        of "else":
          tok = newToken(tokenType=TokenType.ELSE, literal=identifier)
        of "case":
          tok = newToken(tokenType=TokenType.CASE, literal=identifier)
        of "nil":
          tok = newToken(tokenType=TokenType.NIL, literal=identifier)
        of "of":
          tok = newToken(tokenType=TokenType.OF, literal=identifier)
        else:
          tok = newToken(tokenType=TokenType.IDENT, literal=identifier)
      return tok
    elif isInt(lexer.ch):
      var number: string = lexer.readNumber()
      if contains(number, '.'):
        tok = newToken(tokenType=TokenType.FLOAT, literal=number)
      else:
        tok = newToken(tokenType=TokenType.INT, literal=number)
      return tok
    else:
      tok = newToken(tokenType=TokenType.ILLEGAL, literal=($ch))

  lexer.readCharacter()
  return tok

proc newLexer*(source: string): Lexer =
  var
    lexer:Lexer = Lexer(source: source, pos: 0, readPos: 0, eof: false)

  lexer.readCharacter()
  return lexer
