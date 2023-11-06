# Writing functions with loops/if-else structures into ASM

## Loops

The first step to turning any function into ASM, with or without loops, is determine what registers you will need to implement it.  Here's a factorial function for example:

```c
int factorial (int n) {
    int sum = 1;
    for (int i = 1; i <= n; i++)
        sum *= i;
    return sum;
}
```

We can see that we'll have two registers first - `n` in x10/a0, and we'll use x4/t0 as `sum`.  Initialize sum to 1 - this will be our first instruction.

To tackle a loop, the first thing to do is evaluate what our "exit condition" is.  In this case, the condition for the loop is when the counter variable reaches `n`.  If you'd like to minimize the number of variables you want to keep track of, you could consider rewriting the loop so it doesn't use the counter variable:

```c
for (; n >= 1; n--)
    sum *= n;
```

So we don't even need an `i` variable, but we will need to compare `n` to 1, so we still need to allocate that register.  We'll use x5/t1 for this.

Now we're at the start of the loop.  As mentioned above, we should determine our exit condition - it could be that you never enter the loop in the first place.  Our condition is therefore checking if `n >= 1`.  However, keep in mind that this is to **remain** in the loop, so what we actually need is an exit condition, which is the inverse of the loop condition (`n < 1`).  Since this should be the first line in our loop, we'll put a label here.  We'll put a second label after this branch to indicate the exit for our loop.  At this point, your code should look something like:

```c
li t0, 1    // sum = 1
li t1, 1    // hold 1
_loop:
    blt a0, t1, exit
_exit:
    ret
```

Now we tackle the instructions inside the loop.  Luckily there's only one instruction here: `mul t0, a0, t0` to perform `sum = sum * n`.  As part of the loop, we decrement `n` (`addi a0, a0, -1`), and check the exit condition again, by jumping back to the top of the loop.

```c
li t0, 1    // sum = 1
li t1, 1    // hold 1
_loop:
    blt a0, t1, _exit
    mul t0, a0, t0
    addi a0, a0, -1
    jal x0, _loop
_exit:
    ret
```

If we execute this code with any value of `n` however, we'll get `1`.  Something's wrong here.  

In general, since you only have to work with a few registers, it's best to map out what each of the registers should be at each step of the loop (or at least the important ones).  On pen/paper/tablet, create a table with the following columns.  The values for each registers should be the values **after** the instruction is executed.  (We'll assume n is 5).

| insn                | n/a0 | sum/t0 | 1/t1 | Comments                  |
|---------------------|------|--------|------|---------------------------|
| `li t0, 1`          | 5    | 1      | 1    | sum = 1                   |
| `li t1, 1`          | 5    | 1      | 1    | hold 1                    |
| `blt a0, t1, _exit` | 5    | 1      | 1    | 5 < 1 is false, no branch |
| `mul t0, a0, t0`    | 5    | 5      | 1    | sum = 5*1 = 5             |
| `addi a0, a0, -1`   | 4    | 5      | 1    | n = 5-1 = 4               |
| `jal x0, _loop`     | 4    | 5      | 1    | jump to _loop             |
| `blt a0, t1, _exit` | 4    | 5      | 1    | 4 < 1 is false, no branch |
| `mul t0, a0, t0`    | 4    | 20     | 1    | sum = 5*4 = 20            |
| `addi a0, a0, -1`   | 3    | 20     | 1    | n = 4-1 = 3               |
| `jal x0, _loop`     | 3    | 20     | 1    | jump to _loop             |
| `blt a0, t1, _exit` | 3    | 20     | 1    | 3 < 1 is false, no branch |
| `mul t0, a0, t0`    | 3    | 60     | 1    | sum = 20*3 = 60           |
| `addi a0, a0, -1`   | 2    | 60     | 1    | n = 3-1 = 2               |
| `jal x0, _loop`     | 2    | 60     | 1    | jump to _loop             |
| `blt a0, t1, _exit` | 2    | 60     | 1    | 2 < 1 is false, no branch | 
| `mul t0, a0, t0`    | 2    | 120    | 1    | sum = 60*2 = 120          |
| `addi a0, a0, -1`   | 1    | 120    | 1    | n = 2-1 = 1               |
| `jal x0, _loop`     | 1    | 120    | 1    | jump to _loop             |
| `blt a0, t1, _exit` | 1    | 120    | 1    | 1 < 1 is false, no branch |
| `mul t0, a0, t0`    | 1    | 120    | 1    | sum = 120*1 = 120         |
| `addi a0, a0, -1`   | 0    | 120    | 1    | n = 1-1 = 0               |
| `jal x0, _loop`     | 0    | 120    | 1    | jump to _loop             |
| `blt a0, t1, _exit` | 0    | 120    | 1    | 0 < 1 is true, branch     |
| `ret`               | 0    | 120    | 1    | return a0 = 0             |

You don't have to work out all the iterations, but it's good to work out at least one or two to see if your code is doing what you expect it to.

For computing more iterations more easily, and once you have your table, make use of the Watch sidebar in the VScode debugger by adding `-exec p $a0`, `-exec p $t0`, and `-exec p $t1` to it, and comparing the values you see to your table.  That should help you identify your mistakes.

<video src="watchbar.mp4" autoplay controls loop style="width: 700px"></video>

The error in this case is more conceptual - why are we always getting 0 from the function?  This is because `a0`, which gets decremented to 0 by the end of the loop, is also the value to be returned, and we forgot to copy `sum` to a0 at the end of the loop (`_exit`).  We can fix this by adding `add a0, t0, x0` before the `ret` instruction (this does `a0 = t0 + x0`).

```c
li t0, 1    // sum = 1
li t1, 1    // hold 1
_loop:
    blt a0, t1, _exit
    mul t0, a0, t0
    addi a0, a0, -1
    jal x0, _loop
_exit:
    add a0, t0, x0
    ret
```

## If-else structures

Let's combine a loop with an if-else structure.  Here's a function that returns the sum of all the even numbers from 0 to n:

```c
int sum_even (int n) {
    int sum = 0;
    for (int i = 0; i <= n; i++)
        if (i % 2 == 0)
            sum += i;
    return sum;
}
```

Similar to the one above, we'll initialize `sum` to 0 in `t0`, and we'll also initialize `i` to 0 in `t1` - for this example, we'll try implementing the loop as it has been given instead of changing it.  

The first thing we'll do is check the exit condition of the loop.  In this case, it's when `i <= n`, so we'll check `i > n` instead.  If this is false, we enter the loop and perform all internal operations, and incrementing i by 1.  If it's true, we jump to the exit label.  

```c
li t0, 0    // sum = 0
li t1, 0    // i = 0
lo_loop:
    bgt t1, a0, lo_exit
    // internal operations
    addi t1, t1, 1
    jal x0, lo_loop
lo_exit:
    add a0, t0, x0
    ret
```

Note that we can write the rest of the loop, so it's easier to focus on the "internal operations", which we'll do now.

We'll now handle the if-else structure inside the loop.  We know that we need to add `i` to `sum` but only if i is an even number.  

Like a loop, we need to check a condition here.  The great thing about some operations involving a power of 2 (multiplication/division/modulus) is that we can use shift left/right or ANDs.  Recall that any even number in binary will not have the zeroth bit set, so we can check if the zeroth bit is set to determine if `i` is even. 

If that happens, we'll jump to the `_even` label, where we'll perform `sum += i`.  If it's not even, we'll just continue to the next iteration of the loop.  (What if we had more code after the if statement? An else statement?)  We'll also need to increment `i` by 1 before jumping back to the top of the loop.

```c
li t0, 0    // sum = 0
li t1, 0    // i = 0
lo_loop:
    bgt t1, a0, lo_exit
    andi t2, t1, 1
    beq t2, x0, lo_even   // if (x & 1 == 0)
    addi t1, t1, 1
    jal x0, lo_loop
lo_even:
    // internal operations
lo_exit:
    add a0, t0, x0
    ret
```

Next, we add the `sum += i` inside the `_even` section, but we also need to increment `i` by 1 before jumping back to the top of the loop, since we won't get to it otherwise.  Here's our full code:

```c
li t0, 0    // sum = 0
li t1, 0    // i = 0
lo_loop:
    bgt t1, a0, lo_exit
    andi t2, t1, 1
    beq t2, x0, lo_even   // if (x & 1 == 0)
    addi t1, t1, 1        // else continue: i++
    jal x0, lo_loop
lo_even:
    // internal operations
    add t0, t0, t1      // sum += i
    addi t1, t1, 1      // i++
    jal x0, lo_loop
lo_exit:
    add a0, t0, x0
    ret
```

A good thing to keep in mind with multiple if/else-if/else statements is to minimize the number of branches you have to take.  For example, if you have an if/else-if/else structure, you can use a branch to jump to the if, and then use a branch to jump to the else-if.  If neither applies, than you automatically end up at the else block as a result of the natural program flow.  Reducing your branch instructions will reduce the number of instructions you have to execute, and therefore improve your performance.

## Practice
- What if you had to do the following instead?

```c
int sum_even (int n) {
    int sum = 0;
    for (int i = 0; i <= n; i++)
        if (i % 2 == 0)
            sum += i;
        else
            sum -= i;
    return sum;
}
```
