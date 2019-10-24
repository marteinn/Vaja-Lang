import tables
from strutils import parseInt, parseFloat

from lexer import Lexer, nextToken, newLexer
from token import Token, TokenType
from ast import
  newProgram,
  newExpressionStatement,
  newIntegerLiteral,
  newFloatLiteral,
  newNil,
  newPrefixExpression,
  newInfixExpression,
  newIdentifier,
  newBoolean,
  newStringLiteral,
  newAssignStatement,
  newFuntionLiteral,
  newBlockStatement,
  newCallExpression,
  newReturnStatement,
  newPipeLR,
  newIfExpression,
  newCaseExpression,
  newArrayLiteral,
  newHashMapLiteral,
  newIndexOperation,
  newModule,
  Node,
  NodeType,
  toCode,
  CasePattern,
  hash

type
  Parser* = object
    lexer*: Lexer
    errors*: seq[string]
    curToken: Token
    peekToken: Token
  Precedence* = enum
    LOWEST = 0
    SUM = 4
    PRODUCT = 5
    PREFIX = 6
    CALL = 7
    INDEX = 8
var
  precedences: Table[TokenType, Precedence] = {
    TokenType.PLUS: Precedence.SUM,
    TokenType.MINUS: Precedence.SUM,
    TokenType.SLASH: Precedence.PRODUCT,
    TokenType.ASTERISK: Precedence.PRODUCT,
    TokenType.MODULO: Precedence.PRODUCT,
    TokenType.EXPONENT: Precedence.PRODUCT,
    TokenType.AMP: Precedence.PRODUCT,
    TokenType.PLUSPLUS: Precedence.PRODUCT,
    TokenType.AND: Precedence.PRODUCT,
    TokenType.OR: Precedence.PRODUCT,
    TokenType.EQ: Precedence.PRODUCT,
    TokenType.NOT_EQ: Precedence.PRODUCT,
    TokenType.GT: Precedence.PRODUCT,
    TokenType.GTE: Precedence.PRODUCT,
    TokenType.LT: Precedence.PRODUCT,
    TokenType.LTE: Precedence.PRODUCT,
    TokenType.LPAREN: Precedence.CALL,
    TokenType.PIPERARROW: Precedence.SUM,
    TokenType.DOT: Precedence.INDEX,
    TokenType.LBRACKET: Precedence.INDEX,
  }.toTable

proc newParser*(lexer: Lexer): Parser  # Forward declaration

proc nextParserToken(parser: var Parser): Token =
  parser.curToken = parser.peekToken
  parser.peekToken = parser.lexer.nextToken()

  return parser.curToken

proc expectPeek(parser: var Parser, tokenType: TokenType): bool =
  if parser.peekToken.tokenType != tokenType:
    var errorMsg = "Expected token to be " & $(tokenType) & " got " & $(parser.peekToken.tokenType)
    parser.errors.add(errorMsg)
    echo errorMsg
    return false

  discard parser.nextParserToken()
  return true

proc parseIntegerLiteral(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
    intValue: int = parseInt(literal)
  return newIntegerLiteral(token=parser.curToken, intValue=intValue)

proc parseFloatLiteral(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
    floatValue: float = parseFloat(literal)
  return newFloatLiteral(token=parser.curToken, floatValue=floatValue)

proc parseIdentifier(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
  return newIdentifier(token=parser.curToken, identValue=literal)

proc parseBoolean(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
  return newBoolean(token=parser.curToken, boolValue=literal == "true")

proc parseNil(parser: var Parser): Node =
  return newNil(token=parser.curToken)

proc parseStringLiteral(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
  return newStringLiteral(token=parser.curToken, strValue=literal)

proc parseExpression(parser: var Parser, precedence: Precedence): Node # forward declaration

proc parseStatement(parser: var Parser): Node # Forward declaration

proc parsePrefixExpression(parser: var Parser): Node =
  var
    token: Token = parser.curToken
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(Precedence.PREFIX)
  return newPrefixExpression(
    token=token, prefixRight=right, prefixOperator=token.literal
  )

proc parseGroupedExpression(parser: var Parser): Node =
  discard parser.nextParserToken()

  let expression: Node = parser.parseExpression(Precedence.LOWEST)

  if not expectPeek(parser, TokenType.RPAREN):
      return nil

  return expression

proc parseFunctionParameters(parser: var Parser): seq[Node] =
  if parser.peekToken.tokenType == TokenType.RPAREN:
    discard parser.nextParserToken()
    return @[]

  discard parser.nextParserToken()

  var
    parameters: seq[Node] = @[
      parser.parseExpression(Precedence.LOWEST)
    ]

  while parser.peekToken.tokenType == TokenType.COMMA:
    discard parser.nextParserToken()
    discard parser.nextParserToken()

    parameters.add(parser.parseExpression(Precedence.LOWEST))

  if not parser.expectPeek(TokenType.RPAREN):
    return @[]

  return parameters

proc parseBlockStatement(parser: var Parser): Node =
  var
    token: Token = parser.curToken
    statements: seq[Node] = @[]

  discard parser.nextParserToken()

  while (
    parser.curToken.tokenType != TokenType.END and
    parser.curToken.tokenType != TokenType.ELSE and
    parser.curToken.tokenType != TokenType.OF and
    parser.curToken.tokenType != TokenType.EOF
  ):
    if parser.curToken.tokenType == TokenType.NEWLINE:
      discard parser.nextParserToken()
      continue

    var statement: Node = parser.parseStatement()

    if statement != nil:
      statements.add(statement)

    discard parser.nextParserToken()

  return newBlockStatement(token=token, blockStatements=statements)

proc parseFunctionLiteral(parser: var Parser): Node =
  var
    token: Token = parser.curToken
    fnName: Node = nil

  if parser.peekToken.tokenType == TokenType.IDENT:
    discard parser.nextParserToken()

    fnName = newIdentifier(token=parser.curToken, identValue=parser.curToken.literal)

  if not parser.expectPeek(TokenType.LPAREN):
    return nil

  var
    parameters: seq[Node] = parseFunctionParameters(parser)
    functionBody: Node

  if parser.peekToken.tokenType == TokenType.RARROW:
    discard parser.nextParserToken()
    discard parser.nextParserToken()

    var
      statement: Node = parser.parseExpression(Precedence.LOWEST)
      statements: seq[Node] = @[statement]
    functionBody = newBlockStatement(
      token=token,
      blockStatements=statements,
    )
  else:
    functionBody = parseBlockStatement(parser)

  return newFuntionLiteral(
    token=token,
    functionBody=functionBody,
    functionParams=parameters,
    functionName=fnName,
  )

proc parseIfExpression(parser: var Parser): Node =
  let token: Token = parser.curToken
  discard parser.nextParserToken()

  var condition: Node = parser.parseExpression(Precedence.LOWEST)
  var consequence: Node = parser.parseBlockStatement()
  var alternative: Node = nil
  if parser.curToken.tokenType == TokenType.ELSE:
    alternative = parser.parseBlockStatement()

  discard parser.nextParserToken()

  return newIfExpression(
    token=token,
    ifCondition=condition,
    ifConsequence=consequence,
    ifAlternative=alternative
  )

proc parseCaseExpression(parser: var Parser): Node =
  let token: Token = parser.curToken
  discard parser.nextParserToken()

  let condition: Node = parser.parseExpression(Precedence.LOWEST)
  discard parser.nextParserToken()  # RPAREN

  var casePatterns: seq[CasePattern] = @[]
  while (
    parser.curToken.tokenType != TokenType.END and
    parser.curToken.tokenType != TokenType.EOF
  ):
    if parser.curToken.tokenType == TokenType.NEWLINE:
      discard parser.nextParserToken()
      continue

    if parser.curToken.tokenType != TokenType.OF:
      parser.errors.add("Missing of in case expression")
      return nil

    discard parser.nextParserToken()

    let conditionPattern: Node = parser.parseExpression(Precedence.LOWEST)
    if not parser.expectPeek(TokenType.RARROW):
      return nil

    let consequencePattern: Node = parser.parseBlockStatement()
    casePatterns.add(
      (condition: conditionPattern, consequence: consequencePattern)
    )

  return newCaseExpression(
    token=token, caseCondition=condition, casePatterns=casePatterns
  )

proc parseArrayExpressionList(parser: var Parser): seq[Node] =
  if parser.peekToken.tokenType == TokenType.RBRACKET:
    discard parser.nextParserToken()
    return @[]

  discard parser.nextParserToken()

  var elements: seq[Node] = @[
    parser.parseExpression(Precedence.LOWEST)
  ]

  while parser.peekToken.tokenType == TokenType.COMMA:
    discard parser.nextParserToken()
    discard parser.nextParserToken()

    elements.add(
      parser.parseExpression(Precedence.LOWEST)
    )

  # Remove any trailing newline
  while parser.peekToken.tokenType == TokenType.NEWLINE:
    discard parser.nextParserToken()
    continue

  if not parser.expectPeek(TokenType.RBRACKET):
    return @[]

  return elements

proc parseArrayLiteral(parser: var Parser): Node =
  let token: Token = parser.curToken
  let arrayElements: seq[Node] = parseArrayExpressionList(parser)
  return newArrayLiteral(
    token=token,
    arrayElements=arrayElements
  )

proc parseHashMapLiteral(parser: var Parser): Node =
  let token: Token = parser.curToken
  var elements: OrderedTable[Node, Node] = initOrderedTable[Node, Node]()

  if parser.peekToken.tokenType == TokenType.RBRACE:
    discard parser.nextParserToken()
    return newHashMapLiteral(token=token, hashMapElements=elements)

  while parser.curToken.tokenType != TokenType.RBRACE:
    discard parser.nextParserToken()
    let key: Node = parser.parseExpression(Precedence.LOWEST)

    if not parser.expectPeek(TokenType.COLON):
      return nil

    discard parser.nextParserToken()
    let value: Node = parser.parseExpression(Precedence.LOWEST)
    discard parser.nextParserToken()

    # Remove any trailing newlinw
    while parser.curToken.tokenType == TokenType.NEWLINE:
      discard parser.nextParserToken()
      continue

    elements[key] = value

  return newHashMapLiteral(token=token, hashMapElements=elements)

proc parseModule*(parser: var Parser): Node # Forward declaration

proc parseImport(parser: var Parser): Node =
  discard parser.nextParserToken()

  # TODO: Create parser function
  let
    filePath: string = parser.curToken.literal & ".vaja"
    source = readFile(filePath)
  var
    lexer: Lexer = newLexer(source=source)
    parser: Parser = newParser(lexer=lexer)

  return parser.parseModule()

proc parseFromImport(parser: var Parser): Node =
  discard parser.nextParserToken()

  # TODO: Add support for importing/exposing partial imports
  let
    filePath: string = parser.curToken.literal & ".vaja"
    source = readFile(filePath)
  var
    lexer: Lexer = newLexer(source=source)
    parser: Parser = newParser(lexer=lexer)

  return parser.parseModule()

type PrefixFunction = proc (parser: var Parser): Node

proc getPrefixFn(tokenType: TokenType): PrefixFunction =
  return case tokenType:
    of MINUS: parsePrefixExpression
    of NOT: parsePrefixExpression
    of INT: parseIntegerLiteral
    of FLOAT: parseFloatLiteral
    of IDENT: parseIdentifier
    of NIL: parseNil
    of TRUE: parseBoolean
    of FALSE: parseBoolean
    of STRING: parseStringLiteral
    of LPAREN: parseGroupedExpression
    of FUNCTION: parseFunctionLiteral
    of IF: parseIfExpression
    of CASE: parseCaseExpression
    of LBRACKET: parseArrayLiteral
    of LBRACE: parseHashMapLiteral
    of IMPORT: parseImport
    of FROM: parseFromImport
    else: nil

proc currentPrecedence(parser: var Parser): Precedence =
  if not precedences.hasKey(parser.curToken.tokenType):
    return Precedence.LOWEST

  return precedences[parser.curToken.tokenType]

proc peekPrecedence(parser: var Parser): Precedence =
  if not precedences.hasKey(parser.peekToken.tokenType):
    return Precedence.LOWEST

  return precedences[parser.peekToken.tokenType]

proc parseInfixExpression(parser: var Parser, left: Node): Node =
  var
    token: Token = parser.curToken
    precedence: Precedence = parser.currentPrecedence()
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(precedence)
  return newInfixExpression(
    token=token, infixLeft=left, infixRight=right, infixOperator=token.literal
  )

proc parseCallArguments(parser: var Parser): seq[Node] =
  if parser.peekToken.tokenType == TokenType.RPAREN:
    discard parser.nextParserToken()
    return @[]

  discard parser.nextParserToken()

  var callArguments: seq[Node] = @[
    parser.parseExpression(Precedence.LOWEST)
  ]

  while parser.peekToken.tokenType == TokenType.COMMA:
    discard parser.nextParserToken()
    discard parser.nextParserToken()

    callArguments.add(
      parser.parseExpression(Precedence.LOWEST)
    )

  if not parser.expectPeek(TokenType.RPAREN):
    return @[]

  return callArguments

proc parseCallExpression(parser: var Parser, function: Node): Node =
  var
    token: Token = parser.curToken
    callArguments: seq[Node] = parseCallArguments(parser)

  return newCallExpression(
    token=token, callFunction=function, callArguments=callArguments
  )

proc parsePipeLRInfix(parser: var Parser, left: Node): Node =
  var
    token: Token = parser.curToken
    precedence: Precedence = parser.currentPrecedence()
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(precedence)
  return newPipeLR(
    token=token, pipeLeft=left, pipeRight=right
  )

proc parseIndexPropertyOperationInfix(parser: var Parser, left: Node): Node =
  var
    token: Token = parser.curToken
    precedence: Precedence = parser.currentPrecedence()
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(precedence)
  # Transform identifier property to string
  if right.nodeType == NodeType.NTIdentifier:
    right = newStringLiteral(token=parser.curToken, strValue=right.identValue)

  return newIndexOperation(
    token=token,
    indexOpLeft=left,
    indexOpIndex=right
  )

proc parseIndexOperationInfix(parser: var Parser, left: Node): Node =
  let
    token: Token = parser.curToken
    precedence: Precedence = parser.currentPrecedence()
  discard parser.nextParserToken()

  let right: Node = parser.parseExpression(Precedence.LOWEST)
  if not expectPeek(parser, TokenType.RBRACKET):
    return nil

  return newIndexOperation(
    token=token,
    indexOpLeft=left,
    indexOpIndex=right
  )

type InfixFunction = proc (parser: var Parser, left: Node): Node

proc getInfixFn(tokenType: TokenType): InfixFunction =
  return case tokenType:
    of PLUS: parseInfixExpression
    of MINUS: parseInfixExpression
    of SLASH: parseInfixExpression
    of ASTERISK: parseInfixExpression
    of MODULO: parseInfixExpression
    of EXPONENT: parseInfixExpression
    of AMP: parseInfixExpression
    of PLUSPLUS: parseInfixExpression
    of AND: parseInfixExpression
    of OR: parseInfixExpression
    of EQ: parseInfixExpression
    of NOT_EQ: parseInfixExpression
    of GT: parseInfixExpression
    of GTE: parseInfixExpression
    of LT: parseInfixExpression
    of LTE: parseInfixExpression
    of LPAREN: parseCallExpression
    of PIPERARROW: parsePipeLRInfix
    of DOT: parseIndexPropertyOperationInfix
    of LBRACKET: parseIndexOperationInfix
    else: nil

proc parseExpression(parser: var Parser, precedence: Precedence): Node =
  while parser.curToken.tokenType == TokenType.NEWLINE:
    discard parser.nextParserToken()
    continue

  var
    prefixFn = getPrefixFn(parser.curToken.tokenType)

  if prefixFn == nil:
    var errorMsg = "No prefix found for " & $(parser.curToken.tokenType)
    parser.errors.add(errorMsg)
    echo errorMsg
    return

  var
    leftExpression: Node = prefixFn(parser)

  while (
    parser.peekToken.tokenType != TokenType.SEMICOLON and
    parser.peekToken.tokenType != TokenType.NEWLINE and
    precedence < parser.peekPrecedence()
  ):
    var
      infixFn = getInfixFn(parser.peekToken.tokenType)

    if infixFn == nil:
      return leftExpression

    discard parser.nextParserToken()
    leftExpression = infixFn(parser, leftExpression)

  return leftExpression

proc parseExpressionStatement(parser: var Parser): Node =
  let
    expression = parser.parseExpression(Precedence.LOWEST)
  return newExpressionStatement(token=parser.curToken, expression=expression)

proc parseAssignmentStatement(parser: var Parser): Node =
  var
    token: Token = parser.nextParserToken()
    identToken: Token = parser.curToken
    assignName: Node = newIdentifier(token=identToken, identValue=token.literal)

  discard parser.nextParserToken()
  discard parser.nextParserToken()

  var assignValue: Node = parser.parseExpression(Precedence.LOWEST)

  if parser.peekToken.tokenType in [TokenType.NEWLINE, TokenType.SEMICOLON]:
    discard parser.nextParserToken()

  return newAssignStatement(
    token=token,
    assignName=assignName,
    assignValue=assignValue,
  )

proc parseReturnStatement(parser: var Parser): Node =
  var
    token: Token = parser.curToken
  discard parser.nextParserToken()

  var returnValue: Node = parser.parseExpression(Precedence.LOWEST)
  return newReturnStatement(
    token=token,
    returnValue=returnValue,
  )

proc parseStatement(parser: var Parser): Node =
  if parser.curToken.tokenType == TokenType.LET:
    return parser.parseAssignmentStatement()
  if parser.curToken.tokenType == TokenType.RETURN:
    return parser.parseReturnStatement()
  return parser.parseExpressionStatement()

proc parseModule*(parser: var Parser): Node =
  var statements: seq[Node] = @[]
  while parser.curToken.tokenType != TokenType.EOF:
    if parser.curToken.tokenType in [
      TokenType.SEMICOLON, TokenType.NEWLINE
    ]:
      discard parser.nextParserToken()
      continue

    var statement: Node = parser.parseStatement()
    statements.add(statement)

    discard parser.nextParserToken()

  return newModule(moduleStatements=statements)

proc parseProgram*(parser: var Parser): Node =
  var statements: seq[Node] = @[]
  while parser.curToken.tokenType != TokenType.EOF:
    if parser.curToken.tokenType in [
      TokenType.SEMICOLON, TokenType.NEWLINE
    ]:
      discard parser.nextParserToken()
      continue

    var statement: Node = parser.parseStatement()
    statements.add(statement)

    discard parser.nextParserToken()

  return newProgram(statements=statements)

proc newParser*(lexer: Lexer): Parser =
  var parser: Parser = Parser(lexer: lexer)
  parser.errors = @[]
  parser.curToken = parser.lexer.nextToken()
  parser.peekToken = parser.lexer.nextToken()
  return parser
