# Lab 1: Intro to basic assembly

## Due week of 1/16 in your lab section

You will not use the microcontroller to complete this lab. Use the development environment setup on Lab 0 (either Dev Studio or VS Code with FVP).

In this lab we will briefly discuss the process of program generation to understand how C source files and assembly source files get translated into program that machine could understand.

We will also walk through several types of assembly instructions used with ARMv8-A architecture, specifically from the [Arm A64 Instruction Set Architecture](https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions) (ISA). In addition, some assembly directives will also be discussed to let you be prepared for the next two labs.
The ISA used in the lab is slightly different from the one covered in the book (the ARMv8 ISA is actually a little easier to program that the LEG covered in the book).
The flip-side is that ARMv8 is harder to design hardware for. For this lab, don't worry about this minutia we'll be using ARMv8.
**Be sure to upload your lab1.s file to BrightSpace after your checkoff**

A reference manual for the Arm A64 ISA could be found [here](https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions).

- (100 points total) [Lab 1: Intro to basic assembly](#lab-1-intro-to-basic-assembly)
  - [Due week of 9/12 in your lab section](#due-week-of-912-in-your-lab-section)
  - [1. A tutorial on program generation](#1-a-tutorial-on-program-generation)
    - [1.1 Intro](#11-intro)
    - [1.2 ISA and Compiler](#12-isa-and-compiler)
    - [1.3 Assembler](#13-assembler)
    - [1.4 Linker](#14-linker)
    - [1.5 Summary](#15-summary)
  - (20 points) [2. Assembly instruction: arithmetic](#2-assembly-instruction-arithmetic)
    - [2.0 Import template](#20-import-template)
    - [2.1 Example](#21-example)
      - [2.1.1 Solution for the example](#211-solution-for-the-example)
      - [2.1.2 Another solution for the example](#212-another-solution-for-the-example)
    - (10 points) [2.2 Calculating the discriminant of a quadratic equation](#22-calculating-the-discriminant-of-a-quadratic-equation)
    - (10 points) [2.3 Calculating the dot product of two 2-D vectors](#23-calculating-the-dot-product-of-two-2-d-vectors)
  - (30 points) [3. Assembly instruction: bit-wise/logical](#3-assembly-instruction-bit-wiselogical)
    - (10 points) [3.1 Taking one byte from a 64-bit word](#31-taking-one-byte-from-a-64-bit-word)
    - (10 points) [3.2 Turning a flag on/off](#32-turning-a-flag-onoff)
    - (10 points) [3.3 Swaping the LSB and MSB of a 64-bit word](#33-swaping-the-lsb-and-msb-of-a-64-bit-word)
  - (50 points) [4. Assembly instruction: memory](#4-assembly-instruction-memory)
    - [4.0 Crash course on assembly directives](#40-crash-course-on-assembly-directives)
    - (15 points) [4.1 Uppercase formatter](#41-uppercase-formatter)
    - (15 points) [4.2 Swapping two integers](#42-swapping-two-integers)
    - (20 points) [4.3 String cutter](#43-string-cutter)
    - (Bonus 15 points) [4.4 Endianness: which side are you with?](#44-endianness-which-side-are-you-with)

## 1. A tutorial on program generation

### 1.1 Intro

You might have written some programs in C or other languages like JavaScript or Python before, just like the one below:

```C
// HelloWorld.c
#include <stdio.h>

int main (int argc, char * argv[]) {
    printf("Hello World!");
    int x = 1 + 2;
    return 0;
}
```

With a click of button in an IDE or some terminal commands, Vola! The program just works. Nevertheless, how exactly does the CPU recognize and execute the program?

### 1.2 ISA and Compiler

For us, we could just read the source code above and know this is just printing the string `Hello World!` to the screen.
Unfortunately, computers cannot understand English, even a small set of the English language like a programming language.

Instead, what the CPU understands is machine language, which is just a set of bits that map to some operations in hardware.
For instance, in AA64 ISA (the one we are using), `1 0001011001 00000 000 000 00001 00010` maps to a 64-bit addition on register `x0` and `x1` that saves the sum to register `x2`. Recognition of these bits is hard-wired into the chip and are the machine language representation of the instruction set architecture.

But hey, the bit strings are just `1` and `0`, how did we get those from the program we just wrote?
Well you might already know the answer: through compilers and assemblers like those used by `gcc` or `clang`.

The compiler is programmed to understand specific programming languages and translate programs written in them
to the assembly language corresponding to the hardware platform.
For instance, if we compile the example above in ARM A64 ISA, the `int x = 1 + 2`, it might become something like this:

```asm
mov w0, #1
mov w1, #2
add w1, w0, w1
str w1, [sp, #12]
```

The step of generating assembly from a high level language is done by the compiler.
The assembly then needs to be translated into the 1's and 0's that correspond to machine code the computer understands, which is done my an assembler.
You can also try seeing the machine instructions for your personal computer with the command `gcc -S [C source file]` if you are using Linux. 
The type of assembly generated depends on the architecture of your host computer, it might generate Intel's x86 assembly instead if ARM's for example.
All of these details are generally hidden from the application developer who just relies on the compiler/assembler toolchain to generate binaries
that the computer can understand.

> Note: If you do try it with a modern compiler, the `int x = 1 + 2` part will likely just become:
> ```mov w8, #3;```
> ```str w8, [sp, #12]```
> This is because the compiler is actually smart enough to evaluate the value for you! Saving time for the actual execution!
> Also if you have an Apple Silicon machine, you could try `arch -arm64e gcc -S HelloWorld.c` to generate ARM assembly instead of x86 to run natively.

### 1.3 Assembler

Converting assembly instructions to the bitstrings is handled by yet another program called an assembler.
The assembler will do the final translation from plain text assembly to bit strings:

As a reference, here is the hello world main function in assembly:
```asm
...
_main:                                  ; @main
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #48
	stp	x29, x30, [sp, #32]             ; 16-byte Folded Spill
	add	x29, sp, #32
    ...
```

Now if we invoke the assembler and check the file content:

```bash
# NOTE: This is just an example. You are not expected to
# understand these instructions or what it is doing
# yet.
# All of following was ran on a mac m1pro machine
# and is just an illustrative example.

# Assemble the helloworld assembly code into an object
# file called HelloWorld.o
arch -arm64e as HelloWorld.s -o HelloWorld.o

# Examine the HelloWorld.o content
# Use objdump to disassemble the object file
# You could also use xxd to examine the object file
#     xxd: create a hexdump of the binary file
#     xxd HelloWorld.o
# Note: In ARM Development Studio, you could view 
#       the disassembly during debugging.
arch -arm64e objdump -D HelloWorld.o

HelloWorld.o:   file format mach-o arm64

Disassembly of section __TEXT,__text:

0000000000000000 <ltmp0>:
       0: ff c3 00 d1   sub     sp, sp, #48
       4: fd 7b 02 a9   stp     x29, x30, [sp, #32]
       8: fd 83 00 91   add     x29, sp, #32
       c: 08 00 80 52   mov     w8, #0
      10: e8 0b 00 b9   str     w8, [sp, #8]
      14: bf c3 1f b8   stur    wzr, [x29, #-4]
      18: a0 83 1f b8   stur    w0, [x29, #-8]
      1c: e1 0b 00 f9   str     x1, [sp, #16]
      20: 00 00 00 90   adrp    x0, 0x0 <ltmp0+0x20>
      24: 00 00 00 91   add     x0, x0, #0
      28: 00 00 00 94   bl      0x28 <ltmp0+0x28>
      2c: e0 0b 40 b9   ldr     w0, [sp, #8]
      30: 68 00 80 52   mov     w8, #3
      34: e8 0f 00 b9   str     w8, [sp, #12]
      38: fd 7b 42 a9   ldp     x29, x30, [sp, #32]
      3c: ff c3 00 91   add     sp, sp, #48
      40: c0 03 5f d6   ret
```

We can see that at the start, there is a 32-bit word `ffc3 00d1`, which is `sub sp, sp, #48`, followed by `fd7b 02a9`, corresponding to the next line `stp x29, x30, [sp, #32]`, which is the start of our main function.

### 1.4 Linker

Generally, you cannot just run the generated object file on a computer running OS (though you might able to run it on a baremetal CPU).
There are some additional tasks that need to be done to create an executable file and since we have use the `stdio.h`,
we will have to link to it so that the program know where to find `printf()`.
To do so, simply use `gcc HelloWorld.o -o HelloWorld`,
which will automatically handle all the tasks of invoking the compiler, assembler, and
a final tool called a linker that will create the final executable binary.

```shell
# Again the `arch -arm64e` just make sure the gcc compiles
# to ARM machine on the mac m1pro machine
arch -arm64e gcc HelloWorld.o -o HelloWorld
./HelloWorld
> Hello World! 
```

If you have multiple source files, the linker will manage merging these object files together into a single executable.
We actually use this feature to in the following exercises to link the auto grader object
file with your solutions. This way the grader could run your code and see if the results are correct.

### 1.5 Summary

The following figure provides an overview of the flow necessary to generate an executable from
the source code you are familiar with.

```text
┌─────────────┐  Compiler   ┌──────────┐  Assembler  ┌─────────────┐
│ Source Code ├────────────►│ Assembly ├────────────►│ Object File │
└─────────────┘             └──────────┘             └──────┬──────┘
                                          Linker            │
                                 ┌──────────────────────────┘
                                 │
                          ┌──────▼───────┐
                          │  Executable  │
                          └──────────────┘
```

## 2. Assembly instruction: arithmetic

In this sections, we will discuss the arithmetic instructions of ARM A64 ISA and write some code with them.

> Note: for this section and the following assembly practices in the rest of the lab, please only use registers `x0-x7` and `x9-x15` to save temporary results. For those of you are interested, this is to maintain proper caller-callee register saving convention for ARM (a more detailed explanation is [here](https://developer.arm.com/documentation/den0024/a/The-ABI-for-ARM-64-bit-Architecture/Register-use-in-the-AArch64-Procedure-Call-Standard/Parameters-in-general-purpose-registers)).

### 2.0 Import template

In the rest of the lab and furture ARMv8 assembly labs, you will need to either clone or download the lab template zip file from course GitHub webpage. After downloading the template, you will need to unzip it. If using ARM Development Studio: import the folder as a project. A guide to import the project is [here](https://developer.arm.com/documentation/101469/2022-1/Projects-and-examples-in-Arm-Development-Studio/Importing-and-exporting-projects/Import-an-existing-Eclipse-project). 

After importing the folder, expand it and click the `Lab_x_FVP.launch` (`x` is the lab number) script to open up the debugger config. Hit `Debug` to begin debugging.

<!--
FVP Not used 
If you are using the VS Code method on the lab computers, unzip and run ```./labx_setup.sh``` in the lab folder, where `x` is the lab number. -->

### 2.1 Example

Fill in the subroutine body for `q2_1_example` with instructions that will set the value of `x0` to `x0 + x1 + x2 + x3`. For instance, if you set the values x0 through x3 like this:

```asm
mov x0, #1
mov x1, #2
mov x2, #4
mov x3, #8
```  

You should expect that the x0 register will contain the value 15 when execution reaches the nop following the subroutine invocation. It does not matter what values are left in x1, x2, and x3 after the return from example. Remember to use only the registers x0 through x3 when you write your instructions.

#### 2.1.1 Solution for the example

The operation cannot be implemented with a single instruction. You must compose multiple instructions to produce the result.

```asm
.global q2_1_example
q2_1_example:
    /* Enter your code after this comment */
    
    add x1, x0, x1 // now, x1 = x0 + x1
    add x1, x1, x2 // now, x1 = x0 + x1 + x2
    add x1, x1, x3 // finally, x1 = x0 + x1 + x2 + x3
    mov x0, x1     // put the result into x0
    
    /* Enter your code above this comment */
    ret lr
```

You should copy this into the example subroutine in the file, and trace through the execution with the debugger to make sure you understand how it works.

#### 2.1.2 Another solution for the example

There are usually many ways to write the same high-level operation in assembly language. The fewer instructions you can use, the faster the code will run to completion. Here is another solution for the previous problem that has fewer instructions:

```asm
.global q2_1_example
q2_1_example:
    /* Enter your code after this comment */
    
    add x0, x0, x1 // now, x0 = x0 + x1
    add x2, x2, x3 // now, x2 = x2 + x3
    add x0, x0, x2 // finally, x0 = (x0 + x1) + (x2 + x3)

    /* Enter your code above this comment */
    ret lr
```

Since some registers are reused, it may be a little more difficult to understand.
You should study it to discover how it works. For today's exercises,
it does not matter how slowly your solution works (within reason).
What does matter is that no registers other than x0, x1, x2, or x3 are
modified by the code. The reasons for doing so may seem a little arbitrary,
but you'll understand once when we talk about the ARM Cortex Application Binary Interface (ABI) specifications.

### 2.2 Calculating the discriminant of a quadratic equation

For a quadratic equation $ ax^2 + bx + c = 0 $, its discriminant, commonly represented by the Greek symbol Delta, determines if the equation has any real roots:

$$
\begin{align*}
  \Delta &= b^2-4ac
\end{align*}
$$

If $ \Delta = 0 $, the equation has two identical real roots; if $ \Delta > 0 $, two distinct real roots exist; if $ \Delta < 0 $, no real roots exist.

Use the assembly function `q2_2_delta` to write the assembly necessary to compute
the discrminiant of a quadratic equation with the coefficents given in registers `x0-x2`.
You will need to put the final result back in `x0` when the function return.
Specifically, the coefficients and registers mapping is:

```C
// For the equation ax^2 + bx + c = 0
a: reg x0
b: reg x1
c: reg x2

// Final result need to be put in register x0 
Delta: reg x0
```

After completing the problem, you could build and run the lab 1 executable. The autograder will grade your function by compared its result with the C equivalent function on random inputs.

> Hint: You might find the instructions `sub`, `mov`, `mul` to be useful. Also a reference manual to the ARM A64 ISA can be found [here](https://developer.arm.com/documentation/ddi0596/2021-12/Base-Instructions/MUL--Multiply--an-alias-of-MADD-?lang=en)

### 2.3 Calculating the dot product of two 2-D vectors

For two vectors in $ \mathbb{R}^2 $ space, $ \vec{A} = (a_1, a_2) $ and $ \vec{B} = (b_1, b_2) $, the dot product between them is commonly defined as:

$$
\begin{align*}
  \vec{A} \cdot \vec{B} = a_1b_1 + a_2b_2
\end{align*}
$$

In this problem, you will fill up the assembly function `q2_3_dot_product` to compute the dot product of two 2D integer vectors with their components specified in registers `x0-x3`. Similar to previous problem, you will need to put the result back in `x0` when the function return. The mapping of the arguments and registers mapping is:

```C
// For two vector A, B
// A = (a1, a2)
// B = (b1, b2)
a1: reg x0
a2: reg x1
b1: reg x2
b2: reg x3

// Final result
a1b1 + a2b2: reg x0
```

After completing the problem, you could build and run the lab 1 executable. The autograder will grade your function by compared its result with the C equivalent function on random inputs.

> Hint: You might find the instructions `add` and `mul` to be useful. 

## 3. Assembly instruction: bit-wise/logical

In this section, we will use some of the logical/bit-wise instructions of ARM A64 ISA and write some code with them.

<!-- 
// Comment out as you can just use NEG, and if use XOR, kinda of repeating 3.2 turning
// flags on and off
### 3.1 Two's complement representation

Two's complement is the most widely used way to represented signed integer in binary form. With a positive integer $N$, its Two's complement negative value is given by: `~N + 1`, where `~` is the bit-wise negation in `C` language. To see how it works, with a 4-bit number `6`, we have:

```
N = b0110 (6 in decimal) = 0 * 2^3 + 1 * 2^2 + 1 * 2^1 + 0 * 2^0 
  = 4 + 2 = 6
-N = (~N) + 1 = b1001 + 1 = b1010 = 1 * (-2^3) + 0 * 2^2 + 1 * 2^1 + 0 * 2^0
   = -8 + 2 = -6
-(-N) = (~(-N)) + 1 = b0101 + 1 = b0110 = 6
```

In this problem, you will implement the `q3_1_two_comp_neg` assembly function to give the negative value of a signed integer. The input integer is given in register `x0`, and you need to put the result value in register `x0` as well. -->

### 3.1 Taking one byte from a 64-bit word

Often time in embedding programming, you will need to extract one byte from a word and perform some operations on it.
In this problem, you will need to extract the MSB (most significant byte, the byte to the leftmost)
and the LSB (least significant byte, the byte at the rightmost position) of a **64-bit** word.
There are two functions you will need to implement: `q3_1_MSB` amd `q3_1_LSB`.
Both functions will be passed in with the word in register `x0`, and you will put the result back in `x0`.

> Note: Suppose the word is `0x11223344AABBCCDD`, its MSB will be `0x11` and its LSB will be `0xDD`

> Hint: You will need to use logical shift operation and bit-wise AND operation to extract one byte from a 64-bit word. You might find the instructions `lsr` and `and` useful. Also, you might also want to consider loading a register with value `0xFF`.

### 3.2 Turning a flag on/off

In embedding programming, usually you will need to configure the peripherals associated with the microcontroller. For instance, you might need to enable certain pins on the development board or configure the clock frequency of the CPU. An normal practice to enable or disable them is by setting or resetting certin bits in some so-called control registers, which just holds a 32-bit or 64-bit value with each bit correspond to different functionalities. You can imagine each bit as a tiny switch to control one part of the microcontroller.

Another common name for these individual bit (tiny switch) is *flag*, which is a value with only one bit set to 1 and the rest to 0, like `0x1000000` or `16b0001 0000 0000 0000`.

In this problem, you will implement 3 functions to:

1. Set the bit of a value `x0` corresponding to a flag `x1` to `1` (function `q3_2_flag_set`)
2. Set the bit of a value `x0` corresponding to a flag `x1` to `0` (function `q3_2_flag_reset`)
3. Toggle the bit of a value `x0` corresponding to a flag `x1` (function `q3_2_flag_toggle`)

For all three of them, the value will be passed in `x0` and the flag will be passed in `x1`. You will again save the modified value to `x0`.

> Hint: Instruction `and`, `orr`, `eor`, and `mvn` might come in handy

> Also I think they named the bit flag as flag can be raised up or down, like `1` and `0` : )

<!-- 
/* Require conditional branching/execution stuff */

### 3.3 Testing if a flag is set or not

> Note: Make sure you complete 3.2 before starting on this section as we will use your functions to set/reset/toggle the flags!

Okay so you have finished assembly functions to set/reset/toggle the flags, it is now the time to actually check the state of the flags!

In this problem, you will implement the function `q3_3_test_flag` to check if the flag `x1` of a value `x0` is set (means the bit at the flag position is `1`) or not (means the bit is `0`). The value will be passed in register `x0` and the flag will be passed in register `x1`. If the flag is set, you will put an `1` in register `x0`; if not, you will put a `0` in `x0`.

> Example:
> If `x0` has value `0xFF00000011223344`
> And `x1` has value `0x1000000000000000`
> `q3_3_test_flag(x0, x1)` should have `1` in `x0` at finish -->

### 3.3 Swaping the LSB and MSB of a 64-bit word

> Note: You could reuse what you have in section 3.1 to extract LSB and MSB

In this problem you will implement the function `q3_3_swap_byte` that swap the LSB and MSB of a 64-bit word passed in from `x0` and store the swapped word in `x0`.

> Note: You should only swap the LSB and MSB and leave the rest of the bytes intact.

> Hint: `lsl` could shift to the left and `lsr` will shift to the right, both will pad with `0`. Also you might want to review what you have done for [*3.2 Turning a flag on/off*](#32-turning-a-flag-onoff).

## 4. Assembly instruction: memory

So far what you have done in assembly was only manipulating the register values. However, as you might already know, there are simply not enough registers to hold all the variables within a program. This is where memory steps in.

With memory, we could stored the values in our registers to memory and leave space to perform other calculations. When we are done, we could just loaded the values back from memory and continue doing our work. You can think of memory as a gigantic hash table or array with `address` as the key or index:

```C
// Pseudo-code for memory store and load

// Storing to memory, or writing
Mem[addr] = variable

// Loading from memory, or reading
variable = Mem[addr]
```

In this section, we will work with memory instructions to perform some simple stores and loads, but first, we will have a crash course on assembly directives that helps programs know where a variable is in memory and what size does it has.

### 4.0 Crash course on assembly directives

In this lab, you will only work with the `.global` and `.asciz` directives. You could safely ignore the others.

1. `.global SYMBOL`: make the symbol `SYMBOL` visible to other object files during linking, which could either be a variable or a function.
2. `.asciz`/`.string "SOME_STRING"`: specify a null-terminating C-string
   1. This means that the assembler will append a `\0` char to the end of the string.
  
In a high-level view, these directives provide some meta info beyond the actual instructions so that both [assembler](#13-assembler) and [linker](#14-linker) can utilize to generate the executable.

### 4.1 Uppercase formatter
<!--
Lowercase letters are boring, so we would like to improve them by uppercasing!

> Note: sorry to fans of lowercase letters : )
-->
In this problem, you will implement the assembly function `q4_1_toupper` that will take in an address of a lowercase letter and save its uppercase form to the same address like the C program below:

```C
// Assume we have this function implemented
void toupper(char *c) {...}

char chr = 'a';
char *string = "hello";

toupper(&chr);
toupper(string);

// After the above function calls, we will have
  chr = 'A'
  string = "Hello"
```

The address will be passed in register `x0`, you will need to read the value at the address in `x0`, modify it, and then store back to the same address.

In addition, the autograder will use your function to modify the string at label `lowercase_string` and print it out! You could also change the string to whatever you like and observe the effect (autograder won't use this string for grading).

> Note: You can safely assume that the character at the address passed in will always be lowercase.

> Hint#1: Check out `ldrb` and `strb` to read and write one byte from and to an address within a register. Also noted they won't load byte to/store byte from a 64-bit register like `x0`; instead, try using the register in 32-bit mode by using the name `w0`. 

> Note: `x0` and `w0` are the same register except that when using `w0`, only the bottom 32 bits will be modified. That being said, both `x0` and `w0` will hold the incoming function argument, but `w0` will set the top 32 bits to zeros. See the reference manual [here](https://developer.arm.com/documentation/102374/0100/Registers-in-AArch64---general-purpose-registers) for more details. 

> Hint #2: To load a value from memory, the semantic is `ldr xn, [xm]`. The square bracket means to treat the value in register `xm` as the address to load. The same semantic applies to store operation.

> Hint#3: Also check out the ASCII table (try `man ascii` on linux or mac terminal) and find the relation between lowercase and uppercase letter!

> Hint#4: Actually, using `ldr` and `str` will also work for this problem! But why? ([Ans](#44-endianness-which-side-are-you-with))

> Hint#5: Using the memory tab during debugging can be helpful to figure out what is the value before and after the store. A guide to use it can be found [here](https://developer.arm.com/documentation/101470/2022-0/Perspectives-and-Views/Memory-view).

### 4.2 Swapping two integers

> Swap: <br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;take part in an exchange of <br>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-- from Oxford dictionary

In this section, you will implement the assembly function `q4_2_swap` that will take two 64-bit integers addresses and swap the content, similar to the C program below:

```C
void swap(int64_t *a, int64_t *b) {...}

int64_t x = 362;
int64_t y = 270;

swap(&x, &y);

// After the above function call
x = 270
y = 362
```

The two addresses will be passed in register `x0` and `x1` respectively.

### 4.3 String cutter

> Sometimes, string is just too long.

In this problem, you will implement the assembly function `q4_3_cutter` that will take two arguments, a C character string starting address and a cut position, passed in from `x0` and `x1`. The function will be similar to the C program below:

```C
void cutter(char * str, uint64_t pos) {
  *(str + pos) = '\0'
}

char string[50] = "Hello World!";
cutter(string, 5);
printf(string);

// After the above function call, printf will print
// 'Hello' instead of 'Hello World !' to the console
// as the positon 5 is being replaced with the null
// character '\0'
```

### 4.4 Endianness: which side are you with?

> From *Gulliver's Travels* by **Jonathan Swift**
> 
> It is allowed on all hands, that the primitive way of breaking eggs before we eat them, was upon the larger end: but his present Majesty's grandfather, while he was a boy, going to eat an egg, and breaking it according to the ancient practice, happened to cut one of his fingers. Whereupon the Emperor his father published an edict, commanding all his subjects, upon great penalties, to break the smaller end of their eggs.
>
> [reference](https://www.ling.upenn.edu/courses/Spring_2003/ling538/Lecnotes/ADfn1.htm)

Although there is not a physical egg within a computer, we did find a way to start a "war" on which end should we break the egg: the Big-Endian or the Little-Endian.

Before we actually explain these two vague terms, let's consider how does a computer store a 32-bit integer inside memory. 

We all know that (or know by now) that modern computer store data at byte (8 bits) granularity inside memory.
However, for a 32-bit integer like `0x11223344`, it has `4` bytes, in what order should we store it?
Well there are `4! = 24` ways to do so, and we could just store it randomly.
But to make our life easier, and to make the computer life easier, we should
probably store them in consecutive order starting at a memory address.

That is, we store one byte at address `x`, and then store the next byte
in order at `x + 1`, and continue until we finish all `4` bytes.
Still, there exist two ways to do this: store the MSB first or LSB first:

|address  |   `x`  | `x + 1` | `x + 2` | `x + 3` |
|:--      |  :--:  |  :--:   |  :--:   |  :--:   |
|LSB first| `0x44` | `0x33`  | `0x22`  | `0x11`  |
|MSB first| `0x11` | `0x22`  | `0x33`  | `0x44`  |

> Note: MSB refers to most significant byte and LSB refers to least significant byte, check [3.1](#31-taking-one-byte-from-a-64-bit-word) for more explanation on them.

If we store the MSB first, it is Big-Endian; if we store the LSB first, it is Little-Endian.

Now back to `section 4.1`, using `ldr` instead of `ldrb` will work is because when we read using `ldr`, it will load 8 bytes (or 4, depends on whether you use `xn` or `wn`) to the register. Since the architecture we use is `ARMv8-A`, which is Little-Endian by default, the LSB of the register will hold the character at the memory address, which is the one we want to modify. If you convert the lower case character to upper case by modifying it at the bottom 8 bits of the register, you will see that `ldr` and `str` will work.

In this part you will need to implement the function `q4_4_cvt_endian` that will take in a 64-bit integer and reverse its endianness. That is, if it is little-endian, we want it to be big-endian, and vice-versa.

Again like the previous problem, the integer will be passed by reference with its address passed in register `x0`. You will have to store the reversed endianness integer back the same address.

> Hint: You might find yourself copy paste a lot, which is normal, as we won't cover loops until next lab. 

<!--
> Note: Also FYI, the copying and pasting is a common compiler optimization called [loop-unrolling](https://en.wikipedia.org/wiki/Loop_unrolling) that is actually faster compared with loop. Why? Branch prediction! (This note is way beyond the scope of this course, you can safely ignore it if this does not make any sense : )
-->
