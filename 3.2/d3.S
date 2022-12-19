.data

input:
    .ascii    "input.txt\0"
out_msg:
    .ascii    "Score:\n\0"
out_len = . - out_msg

.global _start
.section .text

_start:
    // read_input_file("input.txt", 0x5000)
    ldr     x0, =input
    mov     x1, #0x5000
    bl      read_input_file

    // iterate through input
    mov     x5, x0      // main iterator (addr of line 1)
    mov     x6, #0      // current sum

    loop:
        // byte representation \n[XYZ] [ABC]
        mov    x0, x5
        bl     strlen
        mov    x7, x0 // length of line 1

        // next line
        add    x8, x5, x0
        add    x8, x8, #1 // addr of line 2

        mov    x0, x8
        bl     strlen

        // next line
        add    x9, x8, x0
        add    x9, x9, #1 // addr of line 3

        // nested loop to compare every byte in the 1st comparment with the second
        mov    x10, #0 // outer counter
        loop_find_items:
            ldrb w11, [x5, x10]

            // find (line_2, line_1[iter])
            mov x0, x8
            mov w1, w11
            bl find

            cmp x0, #-1 // not found
            beq item_not_found

            // find (line_3, line_1[iter])
            mov x0, x9
            mov w1, w11
            bl find

            cmp x0, #-1 // not found
            beq item_not_found

            // item was in both
            b item_found

            item_not_found:
                add x10, x10, #1
                b loop_find_items

            item_found:
                mov w13, #0
                bfxil w13, w11, 5, 1 // extract lowercase bit
                eor w13, w13, #1     // flip bit

                mov w14, #26
                mul w13, w13, w14    // zero for lower, 26 for upper

                mov w14, #0xdf
                and w11, w11, w14    // to_lower
                sub w11, w11, #0x40  // 1-26
                add w11, w11, w13    // uppercase value

                // add to total
                add x6, x6, x11

        continue:
        // strlen(line_3)
        mov    x0, x9
        bl     strlen     // get len of line_3
        add    x5, x9, x0 // curr -> end of line_3
        add    x5, x5, #1 // account for newline

        ldrb   w8, [x5]   // get byte for current position
        cmp    w8, #0     // is it a null byte?
        bne    loop     // loop if not null

    output:
        mov     x0, #1        // fd = STDOUT
        ldr     x1, =out_msg
        ldr     x2, =out_len
        mov     w8, #64       // SYS_WRITE
        svc     #0

        // print the result
        mov     x0, x6
        bl      h2a

    exit:
        mov     x0, #0
        mov     w8, #93       // SYS_EXIT
        svc     #0

    error:
        mov     x0, #-1
        mov     w8, #93       // SYS_EXIT
        svc     #0

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

h2a:  // prints register x0's contents as decimal
    mov     x29, sp            // base pointer
    sub     sp, sp, #64

    mov     x1, #0             // counter
    mov     x10, #10           // const ten for div/mul

    // zero out_data
    str     xzr, [x29]
    str     xzr, [x29, 8]

    // char = 0x30 + result - (10*(result/10))
    h2a_loop:
        udiv x3, x0, x10
        mul x3, x3, x10
        sub x3, x0, x3

        add x3, x3, #0x30
        strb w3, [x29, x1] // base pointer + counter
        add x1, x1, #1
        udiv x0, x0, x10

        cmp x0, #0
        bne h2a_loop

    h2a_reverse: // need to reverse the values
        mov x28, x29
        sub x28, x28, #64 // base pointer -64
        mov x2, #0        // new counter

        h2a_reverse_loop:
            sub x1, x1, #1
            ldrb w3, [x29, x1]
            strb w3, [x28, x2]
            add x2, x2, #1

            cmp x1, #0
            bne h2a_reverse_loop

    h2a_write:
        mov     x0, #1         // fd = STDOUT
        mov     x1, x28        // output (bp - 64)
        add     x2, x2, #1     // length += 1
        strb    wzr, [x28, x2] // null terminate

        mov     w8, #64        // SYS_WRITE
        svc     #0

    add sp, sp, #64
    ret

strlen: // length of string in x0
    str x1, [sp, #-16]!
    str x2, [sp, #-16]!

    mov x1, #0 // counter
    mov x2, #0
    strlen_loop:
        ldrb w2, [x0], #1
        cmp w2, #0
        beq strlen_exit
        cmp w2, #0xa
        beq strlen_exit
        add x1, x1, #1
        b strlen_loop

    strlen_exit:
        mov x0, x1 // result in x0
        ldr x2, [sp], #16
        ldr x1, [sp], #16
        ret

find: // str to search in x0, char to find in w1
    str x30, [sp, #-16]!
    str x1, [sp, #-16]!
    str x2, [sp, #-16]!
    str x3, [sp, #-16]!
    str x4, [sp, #-16]!

    mov x4, x0 // preserve str ptr

    bl strlen

    mov x2, #0 // counter
    find_loop:
        ldrb w3, [x4, x2]

        cmp x2, x0
        beq find_not_found

        cmp w3, w1
        beq find_found

        add x2, x2, #1
        b find_loop

    find_found:
        mov x0, x2
        b find_exit

    find_not_found:
        mov x0, #-1
        b find_exit

    find_exit:
        ldr x4, [sp], #16
        ldr x3, [sp], #16
        ldr x2, [sp], #16
        ldr x1, [sp], #16
        ldr x30, [sp], #16
        ret
