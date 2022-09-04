// Mark the 'main' label as visible to linker
// meaning other program can call this function
.global main

// the main function
// assign register x0 with val 1
// assign register x1 with val 2
// add x0 and x1 and assign value to register x2
// return to address in register 'lr'
//     (ignore the following screenshots with 'blr lr')
main:
    mov x0, #1
    mov x1, #2
    add x2, x0, x1
    ret