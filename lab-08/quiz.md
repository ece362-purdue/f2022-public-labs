# Lab 8 Sanity Quiz

A simple quiz to test basic debugger usage.

Copy the following code into the `lab8.S` of lab 8, and use the debugger to find answers to the 3 questions down below.

```asm
.global main
main:
    li a0, 0xECE00362
    li a1, 0x09012023
    li a2, 0xDEADBEEF

question_1:
    add a3, a0, a1

question_2:
    and a4, a0, a2
    xor a4, a4, a1

question_3:
    not a5, a0
    or a5, a5, a1
    and a5, a5, a2
    add a5, a5, a0

    ret
```

## Questions

### Question 1

What is the value inside register `a3` when the program runs to the end of `question_1`? I.e. after line 8 `add a3, a0, a1`?

### Question 2

What is the value of register `a4` when the program runs to the end of `question_2`? I.e. after line 12 `eor a4, a4, a1`?

### Question 3

What is the value of register `a5` when the program runs to the end of `question_3`? I.e. after line 17 `add a5, a5, a0`?
