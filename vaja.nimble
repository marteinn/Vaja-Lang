# Package

version       = "0.1.0"
author        = "marteinn"
description   = "A dynamic interpreted language inspired by Elixir, Lua, Python, Nim and Monkey."
license       = "MIT"
srcDir        = "src"
bin           = @["vaja"]
binDir        = "bin"


# Dependencies

requires "nim >= 1.0.0"

task test_lexer, "Test lexer":
  exec r"nim c -r tests/test_lexer.nim"

task test_parser, "Test parser":
  exec r"nim c -r tests/test_parser.nim"

task test_eval, "Test eval":
  exec r"nim c -r tests/test_eval.nim"

task test_obj, "Test obj":
  exec r"nim c -r tests/test_obj.nim"

task test_builtins_array, "Test array module":
  exec r"nim c -r tests/test_builtins_array.nim"
