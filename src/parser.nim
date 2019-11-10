import tables
from strutils import parseInt, parseFloat

from lexer import Lexer, nextToken, newLexer
from token import Token, TokenType, newEmptyToken
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
  newDestructAssignStatement,
  newFuntionLiteral,
  newBlockStatement,
  newCallExpression,
  newReturnStatement,
  newPipeLR,
  newPipeRL,
  newFNCompositionLR,
  newFNCompositionRL,
  newIfExpression,
  newCaseExpression,
  newArrayLiteral,
  newHashMapLiteral,
  newIndexOperation,
  newModule,
  newMacroLiteral,
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
    TokenType.PIPELARROW: Precedence.SUM,
    TokenType.DOT: Precedence.INDEX,
    TokenType.LBRACKET: Precedence.INDEX,
    TokenType.DOUBLELT: Precedence.INDEX,
    TokenType.DOUBLEGT: Precedence.INDEX,
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

proc parseExpression(parser: var Parser, precedence: int): Node # forward declaration

proc parseStatement(parser: var Parser): Node # Forward declaration

proc parsePrefixExpression(parser: var Parser): Node =
  var
    token: Token = parser.curToken
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(Precedence.PREFIX.int)
  return newPrefixExpression(
    token=token, prefixRight=right, prefixOperator=token.literal
  )

proc parseGroupedExpression(parser: var Parser): Node =
  discard parser.nextParserToken()

  let expression: Node = parser.parseExpression(Precedence.LOWEST.int)

  if not expectPeek(parser, TokenType.RPAREN):
    return nil

  return expression

proc parseNodeList(parser: var Parser, endTokenType: TokenType): seq[Node] =
  if parser.peekToken.tokenType == endTokenType:
    discard parser.nextParserToken()
    return @[]

  discard parser.nextParserToken()

  var
    parameters: seq[Node] = @[
      parser.parseExpression(Precedence.LOWEST.int)
    ]

  while parser.peekToken.tokenType == TokenType.COMMA:
    discard parser.nextParserToken()
    discard parser.nextParserToken()

    parameters.add(parser.parseExpression(Precedence.LOWEST.int))

  if not parser.expectPeek(endTokenType):
    return @[]

  return parameters

proc parseFunctionParameters(parser: var Parser): seq[Node] =
  return parseNodeList(parser=parser, endTokenType=TokenType.RPAREN)

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
      statement: Node = parser.parseExpression(Precedence.LOWEST.int)
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

proc parseMacroLiteral(parser: var Parser): Node =
  var
    token: Token = parser.curToken
    macroName: Node = nil

  if parser.peekToken.tokenType == TokenType.IDENT:
    discard parser.nextParserToken()

    macroName = newIdentifier(
      token=parser.curToken, identValue=parser.curToken.literal
    )

  if not parser.expectPeek(TokenType.LPAREN):
    return nil

  var
    parameters: seq[Node] = parseFunctionParameters(parser)
    macroBody: Node

  if parser.peekToken.tokenType == TokenType.RARROW:
    discard parser.nextParserToken()
    discard parser.nextParserToken()

    var
      statement: Node = parser.parseExpression(Precedence.LOWEST.int)
      statements: seq[Node] = @[statement]

    macroBody = newBlockStatement(
      token=token,
      blockStatements=statements,
    )
  else:
    macroBody = parseBlockStatement(parser)

  return newMacroLiteral(
    token=token,
    macroBody=macroBody,
    macroParams=parameters,
    macroName=macroName,
  )

proc parseIfExpression(parser: var Parser): Node =
  let token: Token = parser.curToken
  discard parser.nextParserToken()

  var condition: Node = parser.parseExpression(Precedence.LOWEST.int)
  var consequence: Node = parser.parseBlockStatement()
  var alternative: Node = nil
  if parser.curToken.tokenType == TokenType.ELSE:
    alternative = parser.parseBlockStatement()

  return newIfExpression(
    token=token,
    ifCondition=condition,
    ifConsequence=consequence,
    ifAlternative=alternative
  )

proc parseCaseExpression(parser: var Parser): Node =
  let token: Token = parser.curToken
  discard parser.nextParserToken()

  let condition: Node = parser.parseExpression(Precedence.LOWEST.int)
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

    let conditionPattern: Node = parser.parseExpression(Precedence.LOWEST.int)
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
    parser.parseExpression(Precedence.LOWEST.int)
  ]

  while parser.peekToken.tokenType == TokenType.COMMA:
    discard parser.nextParserToken()
    discard parser.nextParserToken()

    elements.add(
      parser.parseExpression(Precedence.LOWEST.int)
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
    let key: Node = parser.parseExpression(Precedence.LOWEST.int)

    if not parser.expectPeek(TokenType.COLON):
      return nil

    discard parser.nextParserToken()
    let value: Node = parser.parseExpression(Precedence.LOWEST.int)
    discard parser.nextParserToken()

    # Remove any trailing newlinw
    while parser.curToken.tokenType == TokenType.NEWLINE:
      discard parser.nextParserToken()
      continue

    elements[key] = value

  return newHashMapLiteral(token=token, hashMapElements=elements)

proc parseModule*(parser: var Parser): seq[Node] # Forward declaration

proc parseImport(parser: var Parser): Node =
  discard parser.nextParserToken()

  # TODO: Create parser function
  let
    moduleName: string = parser.curToken.literal
    filePath: string = moduleName & ".vaja"
    source = readFile(filePath)
  var
    lexer: Lexer = newLexer(source=source)
    parser: Parser = newParser(lexer=lexer)

  let moduleStatements: seq[Node] = parser.parseModule()
  return newModule(moduleName=moduleName, moduleStatements=moduleStatements)

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
    of MACRO: parseMacroLiteral
    of IF: parseIfExpression
    of CASE: parseCaseExpression
    of LBRACKET: parseArrayLiteral
    of LBRACE: parseHashMapLiteral
    of IMPORT: parseImport
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

  var right: Node = parser.parseExpression(precedence.int)
  return newInfixExpression(
    token=token, infixLeft=left, infixRight=right, infixOperator=token.literal
  )

proc parseCallArguments(parser: var Parser): seq[Node] =
  if parser.peekToken.tokenType == TokenType.RPAREN:
    discard parser.nextParserToken()
    return @[]

  discard parser.nextParserToken()

  var callArguments: seq[Node] = @[
    parser.parseExpression(Precedence.LOWEST.int)
  ]

  while parser.peekToken.tokenType == TokenType.COMMA:
    discard parser.nextParserToken()
    discard parser.nextParserToken()

    callArguments.add(
      parser.parseExpression(Precedence.LOWEST.int)
    )

  while parser.peekToken.tokenType == TokenType.NEWLINE:
    discard parser.nextParserToken()
    continue

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

  var right: Node = parser.parseExpression(precedence.int)
  return newPipeLR(
    token=token, pipeLRLeft=left, pipeLRRight=right
  )

proc parsePipeRLInfix(parser: var Parser, left: Node): Node =
  var
    token: Token = parser.curToken
    precedence: Precedence = parser.currentPrecedence()
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(precedence.int-1)
  return newPipeRL(
    token=token, pipeRLLeft=left, pipeRLRight=right
  )

proc parseComposeRLInfix(parser: var Parser, left: Node): Node =
  var
    token: Token = parser.curToken
    precedence: Precedence = parser.currentPrecedence()
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(precedence.int)
  return newFNCompositionRL(
    token=token, fnCompositionRLLeft=left, fnCompositionRLRight=right
  )

proc parseComposeLRInfix(parser: var Parser, left: Node): Node =
  var
    token: Token = parser.curToken
    precedence: Precedence = parser.currentPrecedence()
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(precedence.int)
  return newFNCompositionLR(
    token=token, fnCompositionLRLeft=left, fnCompositionLRRight=right
  )

proc parseIndexPropertyOperationInfix(parser: var Parser, left: Node): Node =
  var
    token: Token = parser.curToken
    precedence: Precedence = parser.currentPrecedence()
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(precedence.int)
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

  let right: Node = parser.parseExpression(Precedence.LOWEST.int)
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
    of PIPELARROW: parsePipeRLInfix
    of DOUBLELT: parseComposeRLInfix
    of DOUBLEGT: parseComposeLRInfix
    of DOT: parseIndexPropertyOperationInfix
    of LBRACKET: parseIndexOperationInfix
    else: nil

proc parseExpression(parser: var Parser, precedence: int): Node =
  while parser.curToken.tokenType in [TokenType.NEWLINE]:
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
    precedence < parser.peekPrecedence().int
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
    expression = parser.parseExpression(Precedence.LOWEST.int)
  return newExpressionStatement(token=parser.curToken, expression=expression)

proc parseAssignmentRegularStatement(parser: var Parser): Node =
  let
    token: Token = parser.nextParserToken()
    identToken: Token = parser.curToken
    assignName: Node = newIdentifier(token=identToken, identValue=token.literal)

  discard parser.nextParserToken()  # ident
  discard parser.nextParserToken()  # =

  let assignValue: Node = parser.parseExpression(Precedence.LOWEST.int)
  if parser.peekToken.tokenType in [TokenType.NEWLINE, TokenType.SEMICOLON]:
    discard parser.nextParserToken()

  return newAssignStatement(
    token=token,
    assignName=assignName,
    assignValue=assignValue,
  )

proc parseAssignmentArrayUnpackStatement(parser: var Parser): Node =
  let
    token: Token = parser.nextParserToken()
  let unpackIdentifiers: seq[Node] = parseNodeList(parser, TokenType.RBRACKET)

  discard parser.nextParserToken()  # ]
  discard parser.nextParserToken()  # =

  let assignValue: Node = parser.parseExpression(Precedence.LOWEST.int)

  if parser.peekToken.tokenType in [TokenType.NEWLINE, TokenType.SEMICOLON]:
    discard parser.nextParserToken()

  var namesAndIndexes: seq[(Node, Node)] = @[]
  for index, ident in unpackIdentifiers:
    namesAndIndexes.add((
      ident,
      newIntegerLiteral(
        token=newEmptyToken(),
        intValue=index,
      )
    ))

  return newDestructAssignStatement(
    token=token,
    destructAssignNamesAndIndexes=namesAndIndexes,
    destructAssignValue=assignValue,
  )

proc parseAssignmentStatement(parser: var Parser): Node =
  case parser.peekToken.tokenType:
    of TokenType.IDENT:
      return parseAssignmentRegularStatement(parser)
    of TokenType.LBRACKET:
      return parseAssignmentArrayUnpackStatement(parser)
    else:
      return nil

proc parseReturnStatement(parser: var Parser): Node =
  var
    token: Token = parser.curToken
  discard parser.nextParserToken()

  var returnValue: Node = parser.parseExpression(Precedence.LOWEST.int)
  return newReturnStatement(
    token=token,
    returnValue=returnValue,
  )

proc parseStatement(parser: var Parser): Node =
  if parser.curToken.tokenType == TokenType.LET:
    return parser.parseAssignmentStatement()
  if parser.curToken.tokenType == TokenType.RETURN:
    return parser.parseReturnStatement()
  if parser.curToken.tokenType == TokenType.COMMENT:
    return nil
  return parser.parseExpressionStatement()

proc parseModule*(parser: var Parser): seq[Node] =
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
  return statements

proc parseProgram*(parser: var Parser): Node =
  var statements: seq[Node] = @[]
  while parser.curToken.tokenType != TokenType.EOF:
    if parser.curToken.tokenType in [
      TokenType.SEMICOLON,
      TokenType.COMMENT,
      TokenType.NEWLINE
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
