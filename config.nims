task tests, "Run all tests":
  exec r"nim c -r tests/test_lexer.nim"
  exec r"nim c -r tests/test_parser.nim"
  exec r"nim c -r tests/test_eval.nim"
  exec r"nim c -r tests/test_obj.nim"
  setCommand "nop"

task test_lexer, "Test lexer":
  exec r"nim c -r tests/test_lexer.nim"
  setCommand "nop"

task test_parser, "Test parser":
  exec r"nim c -r tests/test_parser.nim"
  setCommand "nop"

task test_eval, "Test eval":
  exec r"nim c -r tests/test_eval.nim"
  setCommand "nop"

task test_obj, "Test obj":
  exec r"nim c -r tests/test_obj.nim"
  setCommand "nop"
