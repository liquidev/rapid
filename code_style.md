# rapid code style guidelines

This is a set of style guidelines which should be followed by contributors to
the rapid game engine.

## 1. Follow NEP 1

rapid tries to follow NEP 1's coding guidelines. Check them out [here](https://nim-lang.org/docs/nep1.html).

The following rules take precedence over NEP 1:

## 2. Naming conventions

`const`s should *always* use `PascalCase`.

## 3. Styling conventions

 - For name-type pairs, put a single whitespace after the colon: `arg1: int`.
 - For calls, always use parentheses, refrain from using the command syntax
   unless otherwise specified. In calls, do not put any whitespace before and
   after the parentheses. Whenever it makes sense (eg. the object is mutated or
   performs some action), use the dot call syntax `a.someProc(b)`.
 - For type conversions, use dot call syntax `a.SomeType` whenever possible,
   otherwise use either regular proc call syntax `SomeType(a + 2)`. Use command
   call syntax `SomeType a` for variable declarations, like `var i = int a / 2`.
 - Put whitespace around all operators except `..`, `..<` and `..^`.
 - Use `proc ()` instead of `proc()` for anonymous procs.
 - Order imports in three sections: system modules, Nimble modules, and own
   modules. Order each import in a section alphabetically.
 - For other things, NEP 1 rules apply.

## 4. Coding conventions

 - Use implicit return *only* in one-line procs for formulas etc., use `result`
   everywhere else *unless* you need the flow control capabilities of `return`.
 - Use `ref object`s for "portable" objects, that is, objects which are always
   passed by reference from proc to proc (like `RGfx`)
