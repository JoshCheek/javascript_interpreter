Josh's JavaScript Interpreter
=============================

I find it kind of depressing that people get excited about promises.

A JavaScript interpreter, because I frequently wind up trying to explain what I think JavaScript should
do to make async not infect the entire language and everything ever written in it, but most people don't
understand what I mean. Some do, but it's rare, and they usually act like I just spoke at them.
Anyway, generators are an okay immitation of what you should have, but lets be honest...
you should just not live in poverty. I'm super crazy impressed with how your community has pushed this language
to a point that I respect it, 2 years ago I wouldn't have anticipated that could ever happen, but you did it!
Your community has really improved the world you live in... but fuck, JavaScript's approach to async is a fkn virus,
and it if you just demand better, then maybe one day you can know the delightful sensibility of a callstack!


What JavaScript needs
---------------------

When you call an async function, if you give it a callback, it should behave as it does right now.
But if you omit the function, then it should save the callstack as the callback.
when it comes time to resume, instead of passing the result into the callback, it can just return it,
and the callstack picks back up with no idea that it's been idling in an event queue for the last 150 milliseconds

No need to litter the paraphernalia of promises all over your codebase,
you just write the obvious normal thing, and under the covers it is still sinlge threaded, and non-blocking,
but as far as your code is concerned, you get for-real actual return values!


A JS interpreter that does this
-------------------------------

So at least half the point of this repo is to show you that it is totally doable.
It took like 2-3 days of work to make this shitty JS interpreter, and I don't even know the language.
But this interpreter does what I'm talking about (NOTE: Not yet, but I'm super close).
If I can do it, kinda drunk largely distracted thinking about life, and barely knowing shit about JS,
then you can surely petition your humans to build you a better interpreter.
I know you can, I've seen you do it already! In a lot of ways, I'm actually jealous of what you have.
Not your promises, I find them alarming, your generators are okay, but go look at the generated code behind them,
they literally have to turn every method into an incomprehensible state machine with retained mutable state across method calls.
Just fix your interpreter and your world will be so enticing!
I'm already impressed by how your community has adjusted its perspective on design,
based on the pain of mutable state and global variables.
I legit want that! I've been contemplating making npm for
Ruby for like a year or something, you have so much going for you, just take off the async blinders!


Questions about the JavaScripts
-------------------------------

### new

Why is `new` a keyword instead of a function? It's frustrating b/c I have no real momentum left in me, but could probably keep coding otherwise.


### What do parens do

In C, they make a statement into an expression. eg this will print `2`

```c
# include <stdio.h>
int main() {
  int i = ({
      1;
      2;
  });
  printf("%d\n", i);
}
```

In JS this would be the equivalent

```javascript
var i = (
  1;
  2;
);
console.log(i);
```

But it doesn't work:

```sh
$ node f2.js

/Users/josh/deleteme/js-interpreter/f2.js:2
  1;
   ^
SyntaxError: Unexpected token ;
    at Module._compile (module.js:439:25)
    at Object.Module._extensions..js (module.js:474:10)
    at Module.load (module.js:356:32)
    at Function.Module._load (module.js:312:12)
    at Function.Module.runMain (module.js:497:10)
    at startup (node.js:119:16)
    at node.js:902:3
```
