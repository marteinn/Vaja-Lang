## General

## Some principles

- No OOP or inheritance
- No self/this
- (Not implemented) Variables cannot be re-assigned
- (Not implemented) If statements must have a else


## Supported types

### Integer

```
1
```

### Float

```
1.1
```

### Nil/Null

```
nil
```

### Strings

Strings are enclosed in `"double quotes"` and can be escaped by appending a \ before quote, `"like \" this"`.

### Booleans

```
true
false
```

### Arrays

```
let animals = ["bird", "horse", cat"]
print(animals[0])  # bird
```

### HashMap

```
let weather = {"monday": "Rain", "tuesday": "Cloudy"}
```

Hashmap keys can be accessed using a dot syntax.

```
let colors = {"red": "FF0000"}
colors.red  # FF0000
```

Adding a new key to hashmap is done by using `HashMap.insert`, which will return a new HashMap.

```
let colors = {}
let colorsWithBlack = HashMap.insert("black", "000000", colors)
```

### Regex

```
let pattern = Regex.fromString("^hello$")
```

## Variable assignment

```
let status = true
let msg = "hello"
let num = 1
let float = 1.1
```

Variables named or starting with `_` are discarded.

### Destructing assignment

```
let [firstColor] = ["red", "blue", "purple"]
firstColor  # red
```


## Functions

Functions are first class and can be both named and anonymous, Väja supports two types of function syntax:

Arrow syntax for short function declarations, where the last statement are automatically returned:

```
# Assigned to variable a
let a = fn () -> 1
a()  # 1

# Anonymous
map(["John", "Paul", "Ringo", "George"], fn (x) -> x)
```

And fn/end syntax, that allows multiline statments, `return` is optional

```
# Named function
fn hello(name)
  "hello " ++ name
end
hello("Martin")  # "hello Martin"

# Anonymous
map(["John", "Paul", "Ringo", "George"], fn (x)
  return x
end)
```

Closures look like this

```
fn adder(x)
  fn (y) -> x + y
end
adder(1)(2)  # 3
```

Named functions can be pattern matched

```
fn hello("john") -> "john sings"
fn hello("ringo") -> "ringo drums"
hello("john")  # "john sings"

fn hello(name, "whispers") -> name ++ " whispers"
fn hello(name, "sings") -> name ++ " sings"
hello("martin", "sings")  # "martin sings"
```

Parameters named `_` or with a `_` prefix will be ignored

```
fn hello(_) -> 1
fn greet(_name) -> 1
fn welcome(_, _, _) -> 1
```

IN PROGRESS: Anonymous functions can be curried

```
let add = fn'curry (x, y) -> x + y
add(1)(2)  # 3
```

## If/else

```
if (1 > 2) 1 end

if (1 > 2)
    1
else
    3
end

let value = if (1 > 2) true else false end

let value2 = if (false) 1 end  # nil
```

## Case

```
case (1 > 2)
    of true -> "It was true"
    of false -> "It was false"
    of _ -> "Anything goes?"
end
```


## Operator table

| Operator  | Binary                         | Unary                           |
| --------- | ------------------------------ | ------------------------------- |
| `=`       | Assignment                     |                                 |
| `==`      | Equality                       |                                 |
| `!=`      | Inequality                     |                                 |
| `<`       | Less than                      |                                 |
| `>`       | Greater than                   |                                 |
| `<=`      | Less or eqal than              |                                 |
| `>=`      | Greater or eqal than           |                                 |
| `and`     | Logical and                    |                                 |
| `or`      | Logical or                     |                                 |
| `not`     |                                | Logical negation                |
| `+`       | Addition                       |                                 |
| `/`       | Division                       |                                 |
| `-`       | Subtraction                    | Arithmetic negation             |
| `%`       | Modulo                         |                                 |
| `**`      |                                |                                 |
| `++`      | Inflix increment               |                                 |
| `\|>`     | Pass value to fn L -> R        |                                 |
| `<<`      | Functional compositon R -> L   |                                 |




## Imports

Full import
```
import mylibrary

funcFromMyLibrary()
```

IN PROGRESS: Import certain objects
```
from mylibrary import funcFromMyLibrary

funcFromMyLibrary()
```

## Builtin modules

### Functions

| Signature                                                                    |
| ---------------------------------------------------------------------------- |
| `len: id`                                                                    |
| `print: id`                                                                  |
| `type: id`                                                                   |


### Array module

| Signature                                                                    |
| ---------------------------------------------------------------------------- |
| `len: array`                                                                 |
| `head: array`                                                                |
| `last: array`                                                                |
| `map: fn, array`                                                             |
| `filter: fn, array`                                                          |
| `reduce: fn, id, array`                                                      |
| `push: id, array`                                                            |
| `deleteAt: id, array`                                                        |
| `replaceAt: int, id, array`                                                  |
| `tail: array`                                                                |


### String module

| Signature                                                                    |
| ---------------------------------------------------------------------------- |
| `len: string`                                                                |
| `split: string string`                                                       |
| `join: string, array[string]`                                                |
| `map: fn, string`                                                            |
| `filter: fn, string`                                                         |
| `reduce: fn, id, string`                                                     |
| `append: string, string`                                                     |
| `slice: int, int, string`                                                    |
| `toUpper: string`                                                            |
| `toLower: string`                                                            |
| `toArray: string`                                                            |


### HashMap module

| Signature                                                                    |
| ---------------------------------------------------------------------------- |
| `len: hashMap`                                                               |
| `map: fn, hashMap`                                                           |
| `filter: fn, hashMap`                                                        |
| `reduce: fn, id, hashMap`                                                    |
| `toArray: hashMap`                                                           |
| `insert: string, id, hashMap`                                                |
| `remove: string, hashMap`                                                    |
| `update: string, hashMap`                                                    |
| `empty: void`                                                                |


### Http module

| Signature                                                                    |
| ---------------------------------------------------------------------------- |
| `createServer`                                                               |
| `addRoutes: array[[string, fn]], server`                                     |
| `listen: port, server`                                                       |
| `call: string, hashmap, hashmap, server`                                     |

### IO module

| Signature                                                                    |
| ---------------------------------------------------------------------------- |
| `readFile: path`                                                             |
| `writeFile: string, string`                                                  |

### Regexp

| Signature                                                                    |
| ---------------------------------------------------------------------------- |
| `fromString: string`                                                         |
| `contains: Regex, string`                                                    |
| `find: Regex, string`                                                        |

### JSON

| Signature                                                                    |
| ---------------------------------------------------------------------------- |
| `toJSON: id`                                                                 |
| `fromJSON: string`                                                           |


## Comments

Comments are written like this `# I am a comment` and stops at newline
