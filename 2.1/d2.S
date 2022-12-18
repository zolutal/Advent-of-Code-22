.data

input:
    .ascii    "input.txt\0"
out_msg:
    .ascii    "Score:\n\0"
out_len = . - out_msg

out_data:
    .quad     0
    .quad     0
out_data_end:
    .byte     0xa

.text

.globl _start
read_input_file: // read_input_file(char* filename, long size)
    mov     x9, x1      // preserve size in x9
    mov     x10, x0     // preserve filename in x10

    // open input file
    mov     x0, #-100   // AT_FDCWD
    mov     x1, x10     // pathname = filename
    mov     x2, #0      // O_RDONLY
    mov     w8, #56     // SYS_OPENAT
    svc     #0

    // store the resulting fd in x11
    mov     x11, x0

    // mmap input file
    mov     x0, #0      // addr = NULL
    mov     x1, x9      // size = size
    mov     x2, #0x1    // PROT_READ
    mov     x3, #0x2    // MAP_PRIVATE
    mov     x4, x11     // fd = input file
    mov     w8, #222    // SYS_MMAP
    svc     #0

    ret

_start:
    // read_input_file("input.txt", 0x5000)
    ldr     x0, =input
    mov     x1, #0x5000
    bl      read_input_file

    // iterate through input
    mov     x0, x0      // x0 will be the iterator (mmap addr)
    mov     x4, #0      // x2 will be the current sum
    mov     x6, #10     // x6 stores constant ten to multiply for decimal->hex conversion

    loop:
        // byte representation \n[XYZ] [ABC]
        ldr    x7, [x0]   // get bytes for current position
        cmp    w7, #0     // is it a null byte
        beq     output

        bfxil x8, x7, 0x10, 8

        // check for X (+1)
        cmp   x8, 0x58 // X
        add   x4, x4, #1  // inc score
        beq   win_check

        // check for Y (+2)
        cmp   x8, 0x59    // Y
        add   x4, x4, #1  // inc score
        beq   win_check

        // check for Z (+3)
        cmp   x8, 0x5a    // Z
        add   x4, x4, #1  // inc score
        beq   win_check

        win_check:
            bfxil x9, x7, 0x0, 24

            // check results for A (Rock)
            movz x10, 0x2041

            movk x10, 0x58, lsl 16
            cmp x9, x10 // A X
            beq draw

            movk x10, 0x59, lsl 16
            cmp x9, x10  // A Y
            beq win

            movk x10, 0x5a, lsl 16
            cmp x9, x10  // A Z
            beq loss

            // check results for B (Paper)
            movz x10, 0x2042

            movk x10, 0x58, lsl 16
            cmp x9, x10  // B X
            beq loss

            movk x10, 0x59, lsl 16
            cmp x9, x10  // B Y
            beq draw

            movk x10, 0x5a, lsl 16
            cmp x9, x10  // B Z
            beq win

            // check results for C (Scissors)
            movz x10, 0x2043

            movk x10, 0x58, lsl 16
            cmp x9, x10  // C X
            beq win

            movk x10, 0x59, lsl 16
            cmp x9, x10  // C Y
            beq loss

            movk x10, 0x5a, lsl 16
            cmp x9, x10  // C Z
            beq draw

            win:
            add x4, x4, #6
            b continue

            draw:
            add x4, x4, #3
            b continue

            loss:
            b continue

        continue:
        add    x0, x0, #4 //increment iterator
        b      loop // loop if not null

    output:
        mov     x0, #1        // fd = STDOUT
        ldr     x1, =out_msg
        ldr     x2, =out_len
        mov     w8, #64       // SYS_WRITE
        svc     #0

        // print the result
        bl      h2a

    exit:
        mov     x0, #0
        mov     w8, #93       // SYS_EXIT
        svc     #0

    error:
        mov     x0, #-1
        mov     w8, #93       // SYS_EXIT
        svc     #0

    h2a:
        // pass x4 as ptr to convert to ascii
        ldr     x1, =out_data_end // output ptr
        sub     x1, x1, #1        // output ptr--
        mov     x2, #0            // counter
        mov     x6, #10           // const ten for div/mul

        // zero out_data
        str     xzr, [x1, -8]
        str     xzr, [x1, -16]

        // char = 0x30 + result - (10*(result/10))
        h2a_loop:
            udiv x3, x4, x6
            mul x3, x3, x6
            sub x3, x4, x3
            cmp x3, #0
            beq h2a_write

            add x3, x3, #0x30
            strb w3, [x1, x2]
            sub x2, x2, #1
            udiv x4, x4, x6
            b h2a_loop

        h2a_write:
            add     x1, x1, x2    // add negative offset to start of output

            mvn     x2, x2        // length = ~(counter)
            add     x2, x2, #2    // length += 2

            mov     x0, #1        // fd = STDOUT
            mov     w8, #64       // SYS_WRITE
            svc     #0
        ret
