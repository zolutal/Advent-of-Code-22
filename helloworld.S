.data

output:
    .ascii        "Hello world!\n"
len = . - msg

.text

.globl _start
_start:
    // write(1, output, len)
    mov     x0, #1
    ldr     x1, =output
    ldr     x2, =len
    mov     w8, #64
    svc     #0

    // exit(0)
    mov     x0, #0
    mov     w8, #93
    svc     #0
