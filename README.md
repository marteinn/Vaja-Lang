# Väja

Väja is a experimental language built in Nim and is primarly inspired by Elixir, Lua, Python, Nim and Monkey.


## Features:
- First class/higher order functions
- Pattern matching for functions
- Closures
- Integers, floats, strings and bools
- A repl
- let statements
- Arithmetic expressions
- Pipe operator


## Compiling from source
- First [install nim](https://nim-lang.org/install.html)
- Compile vaja: `nim --run c -o:bin/vaja src/vaja.nim`


## Running

### Using the repl
```
./bin/vaja
Väja
>>> 1+1
2
```

### Executing a file
```
./bin/vaja examples/hello.vaja
2
```


## Language syntax
See the [language](https://github.com/marteinn/Vaja-Lang/blob/master/docs/LANGUAGE.md) specification


## Tests
- `nim tests`


## Credits
- Thorsten Ball's book [Writing A Compiler In Go](https://compilerbook.com/)


## References/links
- [Nim by Example](https://nim-by-example.github.io/procs/)
- [unittest](https://nim-lang.org/docs/unittest.html)
- [Nim for python programmers](https://github.com/nim-lang/Nim/wiki/Nim-for-Python-Programmers)
- [Docs / Unittest](https://nim-lang.org/docs/unittest.html)
- [Let's Explore Object Oriented Programming with Nim](https://matthiashager.com/nim-object-oriented-programming)
- [Object variants](https://nim-lang.org/0.19.2/tut2.html#object-oriented-programming-object-variants)
- [A Scripter's Notes](https://scripter.co/notes/nim/)


## License
This project is released under the [MIT License](http://www.opensource.org/licenses/MIT).
