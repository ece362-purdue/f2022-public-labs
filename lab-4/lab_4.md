# Lab 4: Computer Organization v0

<b>NOTE: This is an early version of the lab, meant to give people a chance to get a head start.
Everything you implement here can be used in the final version of the lab.</b>

In this lab, we will be studying the hardware implementation a simple, single cycle implementation of a subset of the LEGv8 architecture.

Specifically, we will be implementing some elements of the processor in a C simulator.
The code for this simulator can be written/run on virtually any linux/mac or windows
system with an appropriate C compiler.


A github code repo will be released soon, but for now, you can assume you will start with the following code:

```c
include <stdint.h>

// Assume that only the LSB of the 64-bit values
// are used to store the value of the control signal.
// Since this is a C-simulator and not a real piece of hardware
// wasting space on making all the types 64-bits is not a important
// but lets us keep the software flexible.
struct ControlSignals {
    uint64_t Reg2Loc;
    uint64_t Branch;
    uint64_t MemRead;
    uint64_t MemtoReg;
    uint64_t ALUOp;
    uint64_t MemWrite;
    uint64_t ALUSrc;
    uint64_t RegWrite;
};

// Assume that the least significant 10 bits of instBits
// contain the instruction bits [31-21].
// Set the output signals as follows:
//  outputSignals.Reg2Loc = 1;
void setControl(uint64_t instBits,  ControlSignals& outputSignals) {

}

// Assume that the lower 32-bits of instBits contain the instruction.
uint64_t getExtendedBits(uint64_t instBits) {
    uint64_t returnVal = 0;
    return returnVal;
}
```

## Part A: Implementing the control logic

In this step, you will be implementing the control logic block in the following diagram.

![Single Cycle Processor](img/ss.jpg)

Assume that the control unit takes in the 11-bits of the op code and
outputs the set of control signals necessary to implement:
ADD, ADDI, SUB, SUBI, LDUR, STUR, EOR, EORI, and CBZ.
Since this is a C simulator and we are not generating real hardware, for "don't care" signals, nothing has to be set.
For the ALUOp line, assume a 2-bit signal with the following meaning:

| Value |         Meaning      |
| ----- | -------------------- |
|  00   |          Add         |
|  10   |        R-Type        |
|  11   | Pass Through data 2  |



## Part B: Implementing the sign extender

Similar to Part A, write a C-function that implements the Sign-Extender.
It should take in the 32-bits of the instruction, and output the sign appropriate
sign extended portion of the instruction.
