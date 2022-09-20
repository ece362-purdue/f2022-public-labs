# Lab 3: Functions in assembly

In this lab we will first discuss the ARMv8 calling convention or ABI (application binary interface), which allows us to write functions that properly invoke each other in machine code level. Along with them we will also mention some aspects about stacks.

Then we will write some assembly code to call standard C library functions like `malloc` and `qsort` to practice the calling convention.

Speaking of functions, we must not forget recursion! You will also code up some recursive assembly functions to compute yet again for fibonacci series and implement a recursive binary search. 

The points will be evenly distributed among the 4 questions with each problem having 30 testcases. So for each question, your score will be `PASS_COUNT/30 * 25` round to the hundredths place.

- (100 points total) [Lab 3: Functions in assembly](#lab-3-functions-in-assembly)
  - (0 points) [1. What is calling convention?](#1-what-is-calling-convention)
    - [1.1 Calling convention to the rescue!](#11-calling-convention-to-the-rescue)
    - [1.2 Calling functions and returning in ARMv8 A64 ISA](#12-calling-functions-and-returning-in-armv8-a64-isa)
      - [1.2.1 Calling a function](#121-calling-a-function)
      - [1.2.2 Entering in a function and returning from it](#122-entering-in-a-function-and-returning-from-it)
    - [1.3 Utilizing stack](#13-utilizing-stack)
      - [1.3.1 Stack 101](#131-stack-101)
      - [1.3.2 Using stack in ARMv8 with AArch64 ISA](#132-using-stack-in-armv8-with-aarch64-isa)
  - (50 points) [2. ASM with C](#2-asm-with-c)
    - (0 points) [2.0 Autograder update](#20-autograder-update)
    - (25 points) [2.1 Better call quicksort](#21-better-call-quicksort)
    - (25 points) [2.2 String concatenation](#22-string-concatenation)
  - (50 points) [3. Recursion](#3-recursion)
    - (25 points) [3.1 Fibonacci revisited](#31-fibonacci-revisited)
    - (25 points) [3.2 Binary search in assembly](#32-binary-search-in-assembly)

## 1. What is calling convention?

Suppose your friends Alice and Bob (why [Alice and Bob](https://en.wikipedia.org/wiki/Alice_and_Bob)?) wrote two assembly functions `foo(a, b)` and `bar(c)` respectively. Now suppose you want to write yet another assembly function `baz` that will call these functions, how would you start?

Well first we might want to know how should we pass the arguments into `foo(a, b)` and `bar(c)`. Do we put `a` in register `x0` or `x1`? What about argument `b`? How can I make sure all my registers' values stay the same after calling `foo` and `bar`? Also where is the return value from these functions?

### 1.1 Calling convention to the rescue!

To make our life easier (and compiler's too), we would want to define a uniform way to pass function arguments, preserve register values, and get function return value, which is what the calling convention is about.

You have already encountered the ARMv8 convention before in lab 1 and lab 2, where you were asked specifically to get function arguments from reg `x0`, `x1` and put return value in reg `x0`. Here is a brief list of each register's type in ARMv8 calling convention (you can find a more detail description [here](https://developer.arm.com/documentation/den0024/a/The-ABI-for-ARM-64-bit-Architecture/Register-use-in-the-AArch64-Procedure-Call-Standard/Parameters-in-general-purpose-registers)):

1. Argument registers (`x0-x7`)
   1. Used for passing function arguments and function value returns.
   2. Suppose a C function `int foo(int a, int b, int c, int d)`:
      1. `a`: reg `x0`
      2. `b`: reg `x1`
      3. `c`: reg `x2`
      4. `d`: reg `x3`
      5. The mapping keeps continue until the eighth argument in `x7`
      6. `return value`: reg `x0`
   3. Since C does not support multi-value return, `x0` is enough for returning function results.
   4. Note these registers are caller-saved so if you use any of them in the caller function prior to calling a subroutine, you will need to save it onto the stack (more about this later).
2. Caller-saved temporary registers (`x9-x15`)
   1. These registers, if used by caller (the function calling another function), should be saved to memory (typically stack) before calling any subroutine.
   2. This means that if `foo` calls `bar` and `foo` uses `x9`, it will need to store `x9` to the memory right before calling `bar`.
3. Callee-saved registers (`x19-x29`)
   1. These registers, if used by callee (the function being called), should be saved to memory before any modification is made.
   2. Suppose `foo` calls `bar` and `bar` uses `x19`, `bar` will need to save it before changing its value and restore it at the end of function.
4. Registers with special purposes (`x29`, `x30`)
   1. `x29` is the frame pointer register, which does not matter in the scope of this class (related to OS)
   2. `x30` is the link register that usually store the function return address so that when function returns, it will return to its caller.

Basically calling convention allows all programs to speck the same "language" so that they could interact as expected from a high-level point of view.

### 1.2 Calling functions and returning in ARMv8 A64 ISA

#### 1.2.1 Calling a function

Suppose we have a function `int add_one(int a)` and we would like to call it in ARM assembly, how should we do this? Well there are generally 5 steps:

1. Save any caller-saved registers in used
2. Prepare the argument registers
3. Call the function
4. Read the return value
5. Restore the caller-saved registers

Step 1 and 5 can be optional if you do not use the caller-saved registers, and we will discuss how to do them in [section 1.3](#13-utilizing-stack).

Ignoring step 1 and 5, the assembly code to call this function looks like this:

```assembly
// Suppose we call the above function `int add_one(int a)` with `a = 1`

// Prepare arguments, here just `x0` as the function has a single argument
mov x0, #1

// Call the function with `bl`, which stands for branch and link
// The operand is the function label, or its name here
// Review lab 2 if you are not familiar with the term `label`  
bl add_one

// After the function returns, the program counter will
// be set to the instruction immediately after the `bl` instruction

// Here we can stored the return value of `add_one`
// to some memory address in `x9`
str x0, [x9]
```

The key instruction here is the `bl label`, [branch and link instruction](https://developer.arm.com/documentation/ddi0596/2021-12/Base-Instructions/BL--Branch-with-Link-?lang=en). What it does is that it will change the `PC` value to the address at `label` and save the `PC + 4` (the instruction immediately after the `bl`) value into register `x30` or `LR` link register. Thus the CPU will know where to go back when returning from a function call.

#### 1.2.2 Entering in a function and returning from it

Now suppose we have the reversed situation here: we have an assembly function `int sub_two(int a)`, how should we prepare when this function is called and how should we return from it?

Likewise to calling a function, this also have 6 steps:

1. Save link register
2. Save callee-saved registers
3. The actual function content
4. Restore the callee-saved registers
5. Restore the link register
6. Return to address in link register

If your function does not call other functions, you do not need to save and restore the link register. This is because when calling another function, the value within the link register will be overwritten. Thus if we do not save it properly, we will end up with an infinite loop in the program:

```assembly
inf_loop_func:
   // Some assembly code without saving register `lr`
   bl some_func
   add x0, x0, #1
   // Some assembly code without restoring register `lr`
   ret lr

// This will become an infinite loop as immediate after calling 
// some_func, the `lr` register will have the address
// of `add x0, x0, #1` to it. Since we did not save 
// nor restore `lr`, when we execute `ret lr`, we will
// also return to the instruction `add x0, x0, #1`.
// Thus forming an infinite loop.
```

If your function does not modify the callee-saved registers, you do not need to save and restore them.

The returning of function is accomplished by [`ret lr`](https://developer.arm.com/documentation/ddi0596/2021-12/Base-Instructions/RET--Return-from-subroutine-?lang=en) or `ret`. It will return to the address in the register, which is default to `lr`.

### 1.3 Utilizing stack

In this section we will briefly discuss the what stack is and how to use it to save and restore registers value to and from memory.

#### 1.3.1 Stack 101

```
------------- ----- 0xFFFF
|   Stack   |
|-----------|
|     |     |
|     V     |
|           |
|    Free   |
|   Memory  |
|           |
|    /|\    |
|     |     |
|-----------|
|    Heap   |
|-----------|
|    Data   |
|-----------|
|    Text   |
------------- ----- 0x0000
```

The above code block shows a typical memory arrangement for program. The `Text` section (`.text` label) is where the actual program lives.
The `Data` section (`.data` label) is where we put our global data (e.g. string literals or large constants). The rest of the memory space is then shared by `Heap` and `Stack`.

`Heap` is basically a memory portion that grows upward (its "pointer" to the end of it will increase). Most of the time it will be used by a memory allocator to perform dynamic memory allocation (i.e. `malloc`).

`Stack` is the opposite of `Heap` that it grows downward: each time we put something on the stack, the stack pointer `sp` should be decremented. The common practice is to use `Stack` for storing function states (callee/caller-saved registers) and local variables within functions. Therefore you will sometimes see the term stack frame, which refers to the stack space allocated to a function:

```
------------- ----- 0xFFFF
|   Func_1  |
|-----------|
|   Func_2  |
|-----------|
|   Func_3  |
|-----------|
|     |     |
|     V     |
|           |
|  Rest of  |
|   Memory  |
|    ...    |
```

Here is what the stack will look like if `Func_1` called `Func_2`, and then `Func_2` called `Func_3`.

> Note: the stack here we are discussing is not the software data structure but rather an implementation of it in hardware. 

#### 1.3.2 Using stack in ARMv8 with AArch64 ISA

Unlike ARMv7 or Thumb ISA, in ARMv8 AArch64, there does not exist a `pop` or `push` instruction. Instead, you will need to manually manage the stack space for each function call. To do so, we will need to subtract the stack pointer `sp` as we enter a function call. Saving registers onto the assigned space. Then, just before we return, we will need to restore the registers based on the store sequence and add back the stack pointer. This probably is best demonstrated with a sample assembly code:

```assembly
// We will store x0-x6 and x30 onto the stack at the beginning
// Then we will restore them at the end
// The stack memory after storing will look like this:
//    x0
//    x1
//    x2
//    x3
//    x4
//    x5
//    x6
//    x30 <-- sp after assigning space
func:
   // Assign space to store 8 64-bit register
   // Noted we need to assign at 16-byte granularity
   // (modify the `sp` reg at multiples of 16)
   // as AArch 64 requires this
   sub sp, sp, #16
   str x0, [sp, #8]
   str x1, [sp]
   sub sp, sp, #16
   str x2, [sp, #8]
   str x3, [sp]
   sub sp, sp, #16
   str x4, [sp, #8]
   str x5, [sp]
   sub sp, sp, #16
   str x6, [sp, #8]
   str lr, [sp]

   // Some code

   // Now we will restore the registers
   // by the sequence they are saved
   // Be aware that stack is LIFO (last in first out)
   ldr lr, [sp] 
   ldr x6, [sp, #8]
   add sp, sp, #16 
   ldr x5, [sp] 
   ldr x4, [sp, #8]
   add sp, sp, #16 
   ldr x3, [sp] 
   ldr x2, [sp, #8]
   add sp, sp, #16 
   ldr x1, [sp] 
   ldr x0, [sp, #8]
   add sp, sp, #16 

   ret
```

Noted again AArch64 stack pointer has to be **16-byte aligned**.
Which is why we are subtracting/adding 16 each time. You could also
assign stack space at a single step by subtracting 64 from `sp` it. See [this post](https://community.arm.com/arm-community-blogs/b/architectures-and-processors-blog/posts/using-the-stack-in-aarch32-and-aarch64) for a more in-depth discussion on AArch64 stack. 

Since this alignment requirement is maintained at hardware level, if you do not follow this rule, you program will not proceed after the faulty instruction.

In addition, you could also use this line of assembly instruction to replace the above code for storing two registers and sub/add `sp`:

```assembly
// stp: store pair of registers
// Here we use the pre-index (the `!`) form of it,
// so it will first subtract 16 from `sp`
// then store the `x0` and `x1` onto the stack
// 
// After this instruction:
//    sp = sp - 16
//    Mem[sp] = x0
//    Mem[sp + 8] = x1
stp x0, x1, [sp, #-16]!

// Similarly, to load them back, use
// ldp: load pair of registers
// Here we use the post-index (imm out of brackets) form,
// so it will first read the registers
// then add the 16 to sp
// After this instruction:
//    Mem[sp] = x0
//    Mem[sp + 8] = x1
//    sp = sp + 16
// Note the two registers must not be the same or else
// ARM will prompt for undefined behavior
ldp x0, x1, [sp], #16
```

Again, you will need to follow the LIFO rule of stack to load back the registers properly.

> Note: the pre-index and post-index forms can also be used on `ldr` and `str`, check their manual page for more details.

## 2. ASM with C

In this section, you will be writing assembly program that relies on standard C library functions.

### 2.0 Autograder update

Since the recursion functions might be hard to debug, the autograder now will print the full inputs as well as the expected outputs for problem 2.2, 3.1, and 3.2.

However, as there are more texts to print, the target console might respond a bit slower (takes ~10 seconds to dump the strings to the console, but the actual code execution will finish in an instinct) and a bit difficult to locate the error testcases. Therefore you could now specify which problem you want to test with by substituting the `TEST_ALL` symbol under `test:` label with the predefined ones in the `lab3.S` template. ORing these test flags are supported so you could run any combination of the tests (e.g. `TEST_FIB | TEST_BSEARCH` will just run the last two problem tests).

Be sure to replace the test variable back to `TEST_ALL` when you finishes debugging each problem individually or else a warning will be printed at the end of test output stating not all testcases are run.

> If you run `TEST_ALL`, there will be a total of 120 testcases or 30 per problem.

### 2.1 Better call quicksort

In this problem you will write a function named `void asm_sort_int(int64_t* arr, uint64_t n)` that relies on `qsort` in C standard library to sort in ascending order. The C equivalent implementation is as follow:

```C
void asm_sort_int(int64_t* arr, uint64_t n) {
    // We sort on array `arr`
    // With `n` elements
    // Each elements has size of 8 bytes
    // Using `asm_cmp` as the compare function
    //    You will need to load the memory address
    //    of asm_cmp when passing it.
    qsort(arr, n, 8, asm_cmp);
}

int asm_cmp(const void *a, const void *b) {
    // Compare function used by the qsort
    // You do not need to worry about typecasting in asm
    // just load them as signed double words (64-bit) are fine
    int64_t tmp = *(int64_t *)a - *(int64_t *)b;
    if (tmp < 0)
        return -1;
    else
        return 1;
}
```

> Note: the function signature for `qsort` is:
> ```
> void qsort(void *base, size_t nitems, size_t size, int (*compar)(const void *, const void*))
> ```

> Hint: you might want to consider the pseudo-assembly `ldr xn, =LABEL` to load label address into the register. See [here](https://developer.arm.com/documentation/dui0473/m/writing-arm-assembly-language/load-addresses-to-a-register-using-ldr-rd---label) for more details. If you just use `ldr xn, LABEL`, the cpu will load the memory content pointed by the `LABEL` address, which is wrong as we want a function pointer here.

### 2.2 String concatenation

This problem will ask you to write a function named `char* asm_strconcat(char * str1, char * str2)`. This function will first assign memory space with `malloc`, concatenating `str1` and `str2`, and return the resulted string. The C equivalent implementation is as follow:

```C
char * asm_strconcat(char *str1, char *str2) {
    // Get string length
    int n1 = strlen(str1);
    int n2 = strlen(str2);

    // Assign space for the concatenated string
    // sizeof(char) = 1
    int size = n1 + n2 + 1;
    char * buf = malloc(sizeof(char) * size);

    // Use `memcpy` to copy string
    memcpy(buf, str1, n1);
    memcpy(buf + n1, str2, n2);

    // Write null char and return it
    buf[size - 1] = '\0';
    return buf;
}
```

> Note: `strlen`, `malloc`, and `memcpy` are all standard C library functions. You should checkout their function signatures online.

## 3. Recursion

> Recursion: *noun.*  
> Definition:  
> &nbsp;&nbsp;&nbsp;&nbsp;See *recursion*  
> &nbsp;&nbsp;&nbsp;&nbsp;-- ECE 362 Dictionary

Recursion is simple, basically we divide problem into subproblems, solve them, combining them to get the solution of the original one.

When coding a recursion function in assembly, be aware that your function now become both caller and callee. Thus you will need to consider saving registers of these two types when entering a function and calling a function.

### 3.1 Fibonacci revisited

Let's redo what we have in lab 2 with fibonacci but this time with recursion! You will implement the function `uint64_t asm_fib(uint64_t n)` which will accept an index term `n` and return the $F_n$ fibonacci term (in particular: $F_0 = 0$, $F_1 = 1$). The C equivalent implementation is:

```C
uint64_t asm_fib(uint64_t n) {
    if (n < 2) {
        // Base cases
        // F0 = 0
        // F1 = 1
        return n;
    } else {
        // Inefficient way (O(2^n) time complexity) 
        // to generate the fibonacci series, 
        // but good intro problem for recursion
        // Fn = Fn-1 + Fn-2
        // To see why inefficient, asm_fib(n-2) just redo
        // what asm_fib(n-1) does for the n-2 terms
        return asm_fib(n - 1) + asm_fib(n - 2);
    }
}
```

### 3.2 Binary search in assembly

In this problem, you will implement a binary search algorithm in assembly. The binary search will search an element in a sorted array with time complexity $O(\lg{n})$. Basically it will compare the middle element with the search key and decide which subarray should it continue the search. When the algorithm terminated, the program should either return the index of the first found element or `-1` if the key cannot be found. A C implementation is provided as below:

```C
// Return the index of the element in the array
// if the element does not exist, return -1 instead
// arr: integer array to be searched
// key: the element we want to search on
// start: start index of subarray, inclusive
// end: end index of subarray, inclusive
//
// so the initial search of array
// A = {1, 2, 3, 4, 5} on key = 3
// will be 
// asm_bsearch(A, 3, 0, 4);
int64_t asm_bsearch(int *arr, int key, 
                    int64_t start,
                    int64_t end) {
    if (start > end) {
        // We could not find the element
        return -1;
    } else {
        // Check the middle element
        // to decide which subarray should we
        // search on
        // div by 2 can be done by right shifting by 1
        uint64_t mid = (end + start) / 2;
        if (arr[mid] < key) {
            return asm_bsearch(arr, key, mid + 1, end);
        } else if (arr[mid] > key) {
            return asm_bsearch(arr, key, start, mid - 1);
        } else {
            return mid;
        }
    }
}
```
