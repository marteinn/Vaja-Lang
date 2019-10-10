type
  TokenType* = enum
    # Types
    INT,
    FLOAT,
    STRING,
    TRUE,
    FALSE
    # Arithmetic
    PLUS,
    MINUS,
    SLASH,
    ASTERISK,
    MODULO,
    EXPONENT,
    # TODO: Floor? //
    # Special
    ILLEGAL,
    EOF,
    NEWLINE,
    SEMICOLON,
    LPAREN,
    RPAREN,
    AMP,
    # Operators
    LET,
    # Identifier
    IDENT,
    # Assignment
    ASSIGN,
    # Logical
    # TODO: AND,
    # TODO: OR,
    # TODO: NOT
    # Comparison
    EQ

type
  Token* = object
    tokenType*: TokenType
    literal*: string

proc newToken*(tokenType: TokenType, literal: string): Token =
  return Token(tokenType: tokenType, literal: literal)
