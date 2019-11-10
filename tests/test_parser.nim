import unittest
from lexer import newLexer, Lexer, nextToken, readCharacter
from parser import Parser, newParser, parseProgram
from ast import Node, NodeType, toCode

proc parseSource(source:string): Node =
  var
    lexer: Lexer = newLexer(source)
    parser: Parser = newParser(lexer=lexer)
    program: Node = parser.parseProgram()

  return program

type
  ExpectedParsing = (string, string)
  ExpectedTokens = seq[ExpectedParsing]

suite "parser tests":
  test "test integer literal":
    var
      source: string = "1"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTIntegerLiteral
    check program.statements[0].toCode() == "1"

  test "test nil literal":
    var
      source: string = "nil"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTNil
    check program.statements[0].toCode() == "nil"

  test "test float literal":
    var
      source: string = "2.2"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTFloatLiteral
    check program.statements[0].toCode() == "2.2"

  test "test bool types":
    var
      source: string = "true"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTBoolean
    check program.statements[0].toCode() == "true"

  test "prefix parsing":
    var
      tests: ExpectedTokens = @[
        ("-1", "(-1)"),
        ("not true", "(not true)"),
        ("not (not true)", "(not (not true))"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "illegal prefix operators returns error":
    var
      source: string = "$1"
      lexer: Lexer = newLexer(source)
      parser: Parser = newParser(lexer = lexer)
      program: Node = parser.parseProgram()

    discard program

    check len(parser.errors) == 1

  test "operator precedence":
    var
      tests: ExpectedTokens = @[
        ("true and not false", "(true and (not false))"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "influx parsing":
    var
      tests: ExpectedTokens = @[
        ("1 + 1", "(1 + 1)"),
        ("1 + 1 + 1", "((1 + 1) + 1)"),
        ("1 - 1", "(1 - 1)"),
        ("-1 + 1", "((-1) + 1)"),
        ("1 * 1", "(1 * 1)"),
        ("1 / 1", "(1 / 1)"),
        ("1 + 2 * 3", "(1 + (2 * 3))"),
        ("a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"),
        ("5 % 5", "(5 % 5)"),
        ("6 ** 6", "(6 ** 6)"),
        ("\"hi\" ++ \"again\"", "(hi ++ again)"),
        ("true and false", "(true and false)"),
        ("true or false", "(true or false)"),
        ("1 == 2", "(1 == 2)"),
        ("1 != 2", "(1 != 2)"),
        ("1 > 2", "(1 > 2)"),
        ("1 >= 2", "(1 >= 2)"),
        ("1 < 2", "(1 < 2)"),
        ("1 <= 2", "(1 <= 2)"),
        ("[1] ++ [2]", "([1] ++ [2])"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "dentifier":
    var
      source: string = "a"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTIdentifier
    check program.statements[0].toCode() == "a"

  test "string":
    var
      source: string = """"hello""""
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTStringLiteral
    check program.statements[0].toCode() == "hello"

  test "empty strings returns emoty":
    check parseSource("\"\"").toCode() == ""

  test "variable assignment struct test":
    var
      source: string = "let a = 1"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTAssignStatement
    check program.statements[0].assignName.nodeType == NodeType.NTIdentifier
    check program.statements[0].assignName.identValue == "a"
    check program.statements[0].assignValue.nodeType == NodeType.NTIntegerLiteral
    check program.statements[0].assignValue.toCode() == "1"
    check program.statements[0].toCode() == "let a = 1"

  test "variable assignment variations":
    check parseSource("let a = b").toCode() == "let a = b"
    check parseSource("let a = true").toCode() == "let a = true"
    check parseSource("let a = 2.2").toCode() == "let a = 2.2"
    check parseSource("let a = \"string\"").toCode() == "let a = string"

  test "multiple assignments":
    var
      source: string = """let a = 1
let b = 2
let c = "hello"
"""
      program: Node = parseSource(source)
    check len(program.statements) == 3

  test "semicolon delimiter":
    check len(parseSource("1;2").statements) == 2
    check len(parseSource("let a = 1;2").statements) == 2

  test "destructuring assignment on array":
    var
      source: string = "let [a, b] = myArr"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTDestructAssignStatement
    check program.statements[0].toCode() == "let [a, b] = myArr"

  test "function parsing":
    var
      source: string = "fn hello(a, b) 1 end"
      program: Node = parseSource(source)

    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTFunctionLiteral
    check program.statements[0].expression.functionName.identValue == "hello"
    check len(program.statements[0].expression.functionParams) == 2
    check len(program.statements) == 1
    check program.statements[0].expression.toCode() == "fn hello(a, b) 1 end"

  test "function parsing short syntax":
    var
      source: string = "fn(x) -> x"
      program: Node = parseSource(source)

    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTFunctionLiteral
    check len(program.statements[0].expression.functionParams) == 1
    check len(program.statements) == 1
    check program.statements[0].expression.toCode() == "fn(x) x end"

  test "function parameter parsing":
    var
      source: string = """fn hello(1, "mystr", b) -> x"""
      program: Node = parseSource(source)

    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTFunctionLiteral
    check len(program.statements[0].expression.functionParams) == 3

    check program.statements[0].expression.functionParams[0].nodeType == NTIntegerLiteral
    check program.statements[0].expression.functionParams[1].nodeType == NTStringLiteral
    check len(program.statements) == 1
    check program.statements[0].expression.toCode() == "fn hello(1, mystr, b) x end"

  test "function call parsing":
    var
      source: string = "hello(1, 2)"
      program: Node = parseSource(source)

    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTCallExpression
    check program.statements[0].expression.toCode() == "hello(1, 2)"

  test "function parsing argument variation":
    check parseSource("a()").toCode() == "a()"
    check parseSource("a(1)").toCode() == "a(1)"
    check parseSource("a(1.2, 2.2)").toCode() == "a(1.2, 2.2)"
    check parseSource("a(1, 2, 3, 4, 5, 6)").toCode() == "a(1, 2, 3, 4, 5, 6)"
    check parseSource("a(b)").toCode() == "a(b)"
    check parseSource("a(true)").toCode() == "a(true)"
    check parseSource("""a("val", "val2")""").toCode() == "a(val, val2)"
    check parseSource("a(fn(x) 1 end)").toCode() == "a(fn(x) 1 end)"
    check parseSource("""
a(
1,
2,
3
)
""").toCode() == "a(1, 2, 3)"

  test "return statements":
    var
      source: string = "return 1"
      program: Node = parseSource(source)

    check program.statements[0].nodeType == NodeType.NTReturnStatement
    check program.statements[0].returnValue.nodeType == NodeType.NTIntegerLiteral
    check program.statements[0].toCode() == "return 1"

  test "function with multiline":
    var
      source: string = """fn hello(a, b)
1
end
"""
      program: Node = parseSource(source)

    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTFunctionLiteral
    check program.statements[0].expression.functionName.identValue == "hello"
    check len(program.statements[0].expression.functionParams) == 2
    check len(program.statements) == 1
    check program.statements[0].expression.toCode() == """fn hello(a, b) 1 end"""

  test "L to R function application":
    var
      tests: ExpectedTokens = @[
        ("1 |> a()", "1 |> a()"),
        ("1 |> a() |> b()", "1 |> a() |> b()"),
        ("""
1 \
|> a() \
|> b()
""", "1 |> a() |> b()"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "R to L function application":
    var
      tests: ExpectedTokens = @[
        ("a() <| 1", "a() <| 1"),
        ("b() <| a() <| 1", "b() <| a() <| 1"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "if/else statement":
    var
      source: string = """if (true) 1 else 2 end"""
      program: Node = parseSource(source)

    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTIfExpression
    check program.statements[0].expression.toCode() == """if (true) 1 else 2 end"""

  test "variations of if statements":
    var
      tests: ExpectedTokens = @[
        ("if (true) 1 end", "if (true) 1 end"),
        ("if (val()) 1 end", "if (val()) 1 end"),
        ("if (1 |> fun()) 1 end", "if (1 |> fun()) 1 end"),
        ("let a = if (true) 1 else 2 end", "let a = if (true) 1 else 2 end"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "case statement":
    var
      tests: ExpectedTokens = @[
        ("""case (true)
  of true -> 2
  of false -> 1
  of _ -> 0
end""", """case (true)
of true -> 2
of false -> 1
of _ -> 0
end"""),
        ("""case (false)
  of true -> 2
  of false ->
    11
end""", """case (false)
of true -> 2
of false -> 11
end""")]

    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].expression.nodeType == NodeType.NTCaseExpression
      check program.statements[0].toCode() == testPair[1]

  test "test array literal":
    var
      source: string = "[1, 2, 3, true]"
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTArrayLiteral
    check program.statements[0].toCode() == "[1, 2, 3, true]"

  test "test array constructs":
    var
      tests: ExpectedTokens = @[
        ("[]", "[]"),
        ("""[
1

]""", "[1]"),
        ("""[
1,
2,
3
]""", "[1, 2, 3]"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "hashmap literal":
    var
      source: string = """{"monday": 0, "tuesday": 1}"""
      program: Node = parseSource(source)

    check len(program.statements) == 1
    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTHashMapLiteral
    check program.statements[0].toCode() == "{monday: 0, tuesday: 1}"

  test "hashmap constructs":
    var
      tests: ExpectedTokens = @[
        ("{}", "{}"),
        ("{a: 1}", "{a: 1}"),
        ("{a: 1, b: 2, c: 3}", "{a: 1, b: 2, c: 3}"),
        ("""{
a: 1,
b: 2,
c: 3
}""", "{a: 1, b: 2, c: 3}"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "hashmap index":
    var
      tests: ExpectedTokens = @[
        ("random.a", "random[a]"),
        ("random[a]", "random[a]"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].expression.nodeType == NodeType.NTIndexOperation
      check program.statements[0].toCode() == testPair[1]

  test "array dynamic index":
    var
      tests: ExpectedTokens = @[
        ("random[0]", "random[0]"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].expression.nodeType == NodeType.NTIndexOperation
      check program.statements[0].toCode() == testPair[1]

  test "test functional composition R->L":
    var
      tests: ExpectedTokens = @[
        ("a << b", "a << b"),
        ("a << b << c", "a << b << c"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "test functional composition L->R":
    var
      tests: ExpectedTokens = @[
        ("a >> b", "a >> b"),
        ("a >> b >> c", "a >> b >> c"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.statements[0].toCode() == testPair[1]

  test "comment parsing":
    var
      tests: ExpectedTokens = @[
        ("# hello", ""),
        ("""
let a = fn(x)
  # Hello world
  1
end
""", "let a = fn(x) 1 end"),
      ]
    for testPair in tests:
      var program: Node = parseSource(testPair[0])
      check program.toCode() == testPair[1]

  test "macro parsing":
    var
      source: string = "macro hello(a, b) 1 end"
      program: Node = parseSource(source)

    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].expression.nodeType == NodeType.NTMacroLiteral
    check program.statements[0].expression.macroName.identValue == "hello"
    check len(program.statements[0].expression.macroParams) == 2
    check len(program.statements) == 1
    check program.statements[0].expression.toCode() == "macro hello(a, b) 1 end"

  test "if statement can be passed as call argument":
    var
      source: string = """type(if (true) 1 else 2 end)"""
      program: Node = parseSource(source)

    check program.statements[0].nodeType == NodeType.NTExpressionStatement
    check program.statements[0].toCode() == "type(if (true) 1 else 2 end)"
