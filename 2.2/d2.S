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

        mov x8, xzr
        bfxil x8, x7, 0x10, 8 // your move
        mov x9, xzr
        bfxil x9, x7, 0, 8    // opponents move

        // check for X (+0)
        cmp   x8, 0x58 // X
        beq   do_lose

        // check for Y (+3)
        cmp   x8, 0x59    // Y
        beq   do_draw

        // check for Z (+6)
        cmp   x8, 0x5a    // Z
        beq   do_win

        do_lose:
            add x4, x4, #0  // inc score
            cmp x9, #0x41 // Rock
            beq scissors

            cmp x9, #0x42 // Paper
            beq rock

            cmp x9, #0x43 // Scissors
            beq paper

        do_draw:
            add x4, x4, #3  // inc score
            cmp x9, #0x41 // Rock
            beq rock

            cmp x9, #0x42 // Paper
            beq paper

            cmp x9, #0x43 // Scissors
            beq scissors

        do_win:
            add x4, x4, #6  // inc score
            cmp x9, #0x41 // Rock
            beq paper

            cmp x9, #0x42 // Paper
            beq scissors

            cmp x9, #0x43 // Scissors
            beq rock

        rock:
            add x4, x4, 1
            b continue
        paper:
            add x4, x4, 2
            b continue
        scissors:
            add x4, x4, 3
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

            add x3, x3, #0x30
            strb w3, [x1, x2]
            sub x2, x2, #1
            udiv x4, x4, x6

            cmp x4, #0
            bne h2a_loop

        h2a_write:
            add     x1, x1, x2    // add negative offset to start of output

            mvn     x2, x2        // length = ~(counter)
            add     x2, x2, #2    // length += 2

            mov     x0, #1        // fd = STDOUT
            mov     w8, #64       // SYS_WRITE
            svc     #0
        ret
