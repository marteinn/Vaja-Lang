task tests, "Run all tests":
  exec r"nim c -r tests/test_lexer.nim"
  exec r"nim c -r tests/test_parser.nim"
  exec r"nim c -r tests/test_evaluator.nim"
  setCommand "nop"
