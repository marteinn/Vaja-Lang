# Array

## Functions

- `len`
    ```
    Array.len([1, 2, 3])  # 3
    ```
- `head`
    ```
    Array.head([1, 2, 3])  # 1
    ```
- `last`
    ```
    Array.last([1, 2, 3])  # 3
    ```
- `map`

    ```
    Array.map(fn (x) -> x*2, [1, 2, 3])  # [2, 4, 6]
    ```
- `filter`
    ```
    Array.filter(fn (x) -> x == 1, [1, 2, 1])  # [1, 1]
    ```
- `reduce`

    ```
    Array.reduce(fn (acc, curr) -> acc + curr, 1, [1, 2, 3])  # 7
    ```
- `push`

    ```
    Array.push(3, [1, 2])  # [1, 2, 3]
    ```
- `deleteAt`

    ```
    Array.deleteAt(0, [1, 2, 3])  # [2, 3]
    ```
- `append`

    ```
    Array.deleteAt([1, 2], [3, 4])  # [1, 2, 3, 4]
    ```
- `replaceAt`

    ```
    Array.replaceAt(0, 55, [1, 2])  # [55, 2]
    ```
- `tail`
    ```
    Array.replaceAt([1, 2, 3])  # [2, 3]
    ```

#### Not yet implemented

- `take`
- `drop`
- `any`
- `all`
- `reverse`
