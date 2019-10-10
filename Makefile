compile:
	nim compile --run src/repl.nim

test:
	nim c -r tests/test_lexer.nim
	nim c -r tests/test_parser.nim
	nim c -r tests/test_evaluator.nim
