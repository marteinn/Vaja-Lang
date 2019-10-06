import tables
from strutils import parseInt

from lexer import Lexer, nextToken
from token import Token, TokenType
from ast import
  newProgram,
  newExpressionStatement,
  newIntegerLiteral,
  newPrefixExpression,
  Node,
  Program

type
  Parser* = object
    lexer*: Lexer
    errors*: seq[string]
    curToken: Token
    peekToken: Token
  Precedence* = enum
    LOWEST = 0
    PREFIX = 1
var
  precedences: Table[TokenType, Precedence] = {
    TokenType.MINUS: Precedence.PREFIX
  }.toTable

method nextParserToken(parser: var Parser): Token =
  parser.curToken = parser.peekToken
  parser.peekToken = parser.lexer.nextToken()

  return parser.curToken

proc parseIntegerLiteral(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
    value: int = parseInt(literal)
  return newIntegerLiteral(token=parser.curToken, value=value)


method parseExpression(parser: var Parser, precedence: Precedence): Node # forward declaration

proc parsePrefixExpression(parser: var Parser): Node =
  var 
    token: Token = parser.curToken
  discard parser.nextParserToken()

  var right: Node =parser.parseExpression(Precedence.PREFIX)
  return newPrefixExpression(token=token, right=right, operator=token.literal)

type
  PrefixFunction = proc (parser: var Parser): Node

proc getPrefixFn(tokenType: TokenType): PrefixFunction =
  return case tokenType:
    of MINUS: parsePrefixExpression
    of INT: parseIntegerLiteral
    else: nil

method parseExpression(parser: var Parser, precedence: Precedence): Node =
  var
    prefixFn = getPrefixFn(parser.curToken.tokenType)

  if prefixFn == nil:
    var errorMsg = "No prefix found for " & $(parser.curToken.tokenType)
    parser.errors.add(errorMsg)
    echo errorMsg
    return

  var
    leftExpression: Node = prefixFn(parser)

  return leftExpression

method parseExpressionStatement(parser: var Parser): Node {.base.} =
  var
    expression = parser.parseExpression(Precedence.LOWEST)
  return newExpressionStatement(token=parser.curToken, expression=expression)

method parseStatement(parser: var Parser): Node =
  return parser.parseExpressionStatement()

method parseProgram*(parser: var Parser): Program {.base.} =
  var statements: seq[Node] = @[]
  while parser.curToken.tokenType != TokenType.EOF:
    var statement = parser.parseStatement()
    statements.add(statement)

    discard parser.nextParserToken()

  return newProgram(statements = statements)

proc newParser*(lexer: Lexer): Parser =
  var parser: Parser = Parser(lexer: lexer)
  parser.errors = @[]
  parser.curToken = parser.lexer.nextToken()
  parser.peekToken = parser.lexer.nextToken()
  return parser
