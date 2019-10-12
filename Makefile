repl:
	nim compile --run src/vaja.nim

compile:
	nim --run c -o:bin/vaja src/vaja.nim
