# Lab 4: Computer Organization

In this lab, we will be studying the hardware implementation of a simple, single cycle of a subset of the LEGv8 architecture.

Specifically, we will be implementing some elements of the processor in a C simulator.
The code for this simulator can be written/run on virtually any linux/mac or windows
system with an appropriate C compiler.

After you have pulled down the code, building the tester should
just involve running:

```bash
make
```

from the command line. If you want to test this code on your own ARM-based MAC,
use the command:

```bash
make MacArm
```

To run the test for the lab, run:
```bash
./lab4
```

##  Part A: Implementing the control logic [40 Points]

In this step, you will be implementing the control logic block in the following diagram.

![Single Cycle Processor](img/ss.jpg)

Assume that the control unit takes in the 11-bits of the op code and
outputs the set of control signals necessary to implement:
ADD, ADDI, SUB, SUBI, LDUR, STUR, ORR, and CBZ.
Since this is a C simulator and we are not generating real hardware, for "don't care" signals, nothing has to be set.
For the ALUOp line, assume a 2-bit signal with the following meaning:

| Value |         Meaning      |
| ----- | -------------------- |
|  00   |          Add         |
|  10   |        R-Type        |
|  11   | Pass Through data 2  |



##  Part B: Implementing the sign extender [60 Points]

Similar to Part A, write a C-function that implements the Sign-Extender.
It should take in the 32-bits of the instruction, and output the sign appropriate
sign extended portion of the instruction.

## Some helpful hints

- Recall that you can specify hex constants in C using the ```0x``` format and binary constants using the ```0b``` format.
- Be careful with shifting "1". Since we are using large, 64-bit types, C by default will treat a constant "1" as a 32-bit value. If you want to shift the value "1" to set the higher bits in a number by shifting it over (i.e. "1 << 63"), decare "const uint64_t one = 1;", then do "one << 63".
- Recall, not all instructions have the same number of opcode bits, however, your setControl function is always getting the uppermost 11-bits of the instruction in the lowermost 11-bits of instrBits.

Your final points will be calculated based on the percentage of test cases passed
in each category. Please be sure to hand in your lab4.cc file to Bright Space.
