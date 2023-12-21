# Quart standard library
Quart has a small standard library (28 words) and each word is documented below

## +
`( n1 n2 -- n1+n2 )`

Returns `n1` + `n2`

## -
`( n1 n2 -- n1-n2 )`

Returns `n1` - `n2`

## *
`( n1 n2 -- n1*n2 )`

Returns `n1` * `n2`

## /
`( n1 n2 -- n1/n2 )`

Returns `n1` / `n2`

## %
`( n1 n2 -- n1%n2 )`

Returns `n1` % `n2` (modulo)

## .
`( n -- )`

Prints the given number as decimal to stdout

## =
`( n1 n2 -- bool )`

Returns -1 if `n1` and `n2` are equal, 0 if not

## >
`( n1 n2 -- bool )`

Returns -1 if `n1` > `n2`

## >=
`( n1 n2 -- bool )`

Returns -1 if `n1` >= `n2`

## <
`( n1 n2 -- bool )`

Returns -1 if `n1` < `n2`

## <=
`( n1 n2 -- bool )`

Returns -1 if `n1` <= `n2`

## words
`( -- )`

Prints all defined words and the amount to stdout

## emit
`( ch -- )`

Writes the given character to stdout

## dup
`( n -- n n )`

Duplicates the top item on the stack

## @
`( addr -- value )`

Reads a cell size value from `addr` and returns the value

## !
`( value addr -- )`

Writes `value` as a cell size value to `addr`

## C@
`( addr -- byte )`

Reads a byte from `addr` and returns the value

## C!
`( byte addr -- )`

Writes `byte` to `addr`

## bye
`( -- )`

Exits with exit code 0

## exit
`( n -- )`

Exits with exit code `n`

## cells
`( n -- n*size )`

Multiplies `n` by the cell size in bytes

## r>
`( -- n)`

Pops from the return stack and puts the value on the stack

## >r
`( n -- )`

Pops from the stack and pushes the value to the return stack

## swap
`( n1 n2 -- n2 n1)`

Swaps the top 2 items on the stack

## over
`( n1 n2 -- n1 n2 n1)`

Pushes the second to top value on the stack

## rot
`( n1 n2 n3 -- n2 n3 n1)`

Rotates the top 3 stack entries

## drop
`( n -- )`

Removes the top value on the stack

