# Väja

Väja is a dynamic interpreted language inspired by Elixir, Lua, Python, Nim and Monkey.


## Features:
- First class/higher order functions
- Pattern matching for functions
- Closures
- Integers, floats, strings, bools, regex
- A repl
- let statements
- Arithmetic expressions
- Pipe operator
- Immutable data
- Uses a tree walking, top to bottom, interpreter
- A pratt parser
- A (work in process) compiler and virtual machine

## Example syntax

```
let myList = [1, 2, 3]
let myLongerList = myList ++ [4, 5, 6]
Array.map(fn (x) -> x*2, myLongerList)
let isTrue = if (2 > 1) true else false end
print(String.len("my string"))
1.1 |> type()
let trimAndCapitalize = capitalize << trim
trimAndCapitalize("   helllo world")
```

This is how you would spin up the built in web server

```
Http.createServer() \
|> Http.addHandler(fn (req)
  {
    "status": 200,
    "body": "{\"message\": \"Hello world\"}",
    "headers": [
      ["Content-Type", "application/json"],
    ]
  }
end) \
|> Http.listen(8080)
```

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


## Editor integration
You can find a vim plugin [here](https://github.com/marteinn/Vaja-Vim/).


## Like the Väja syntax?
Awesome, since Väja is a "hobby" language I recommend that you use Elixir, a great Lua/Ruby functional language built around the BEAM.


## Väja?
The name comes from a lumber mill in the northen of Sweden.


## Running tests
- `nimble test`


## Credits
- Thorsten Ball - [Writing A Interpreter In Go](https://interpreterbook.com/)
- Thorsten Ball - [Writing A Compiler In Go](https://compilerbook.com/)


## References/links
- [Nim by Example](https://nim-by-example.github.io/procs/)
- [unittest](https://nim-lang.org/docs/unittest.html)
- [Nim for python programmers](https://github.com/nim-lang/Nim/wiki/Nim-for-Python-Programmers)
- [Docs / Unittest](https://nim-lang.org/docs/unittest.html)
- [Let's Explore Object Oriented Programming with Nim](https://matthiashager.com/nim-object-oriented-programming)
- [Object variants](https://nim-lang.org/0.19.2/tut2.html#object-oriented-programming-object-variants)
- [A Scripter's Notes](https://scripter.co/notes/nim/)
- [The Nim memory model](http://zevv.nl/nim-memory/)
- [Inside The Python Virtual Machine](https://leanpub.com/insidethepythonvirtualmachine/read)
- [Let’s Build A Simple Interpreter](https://ruslanspivak.com/lsbasi-part1/)


## License
This project is released under the [MIT License](http://www.opensource.org/licenses/MIT).
