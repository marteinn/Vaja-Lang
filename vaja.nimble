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

task test_builtins_string, "Test string module":
  exec r"nim c -r tests/test_builtins_string.nim"

task test_builtins_hashmap, "Test hashmap module":
  exec r"nim c -r tests/test_builtins_hashmap.nim"

task test_builtins_http, "Test http module":
  exec r"nim c -r tests/test_builtins_http.nim"

task test_builtins_io, "Test IO module":
  exec r"nim c -r tests/test_builtins_io.nim"

task test_builtins_regex, "Test regex module":
  exec r"nim c -r tests/test_builtins_regex.nim"

task test_builtins_json, "Test json module":
  exec r"nim c -r tests/test_builtins_json.nim"

task test_builtins_base64, "Test base64 module":
  exec r"nim c -r tests/test_builtins_base64.nim"

task test_ast_modify, "Test ast modify module":
  exec r"nim c -r tests/test_ast_modify.nim"

task test_macro_expansion, "Test Macro expansion":
  exec r"nim c -r tests/test_macro_expansion.nim"

task test_code, "Test code":
  exec r"nim c -r tests/test_code.nim"

task test_compiler, "Test compiler":
  exec r"nim c -r tests/test_compiler.nim"

task test_vm, "Test vm":
  exec r"nim c -r tests/test_vm.nim"

task test_symbol_table, "Test symbol table":
  exec r"nim c -r tests/test_symbol_table.nim"
