## General

- No oop / inheritance


## Types

```
var status = true
var msg = "hello"
var num = 1
var decimal = 1.1
```

## Functions

```
fn () -> 1

fn (a, b) -> 2

fn hello(a, b) -> {
    let a = 5
    return  5
}

map([1, 2], fn (x) -> x * 2)

map([1, 2], fn (x) -> {x * 2})

```

## Pipeline operator

```
"hello" |> capitalize()
```

## Array

```
var a = [1, 2, 3]
```

## Iterators

```
map(a, fn (x) -> x)
map(a, fn (x) -> {
    x
})
```
