.data

input:
    .ascii    "input.txt\0"
out_msg:
    .ascii    "Max Value:\n\0"
out_len = . - out_msg

out_data:
    .quad     0
    .quad     0
out_data_end:
    .byte     0xa

.text

.globl _start
_start:
    // open input file
    mov     x0, #-100   // AT_FDCWD
    ldr     x1, =input  // pathname = input
    mov     x2, #0      // O_RDONLY
    mov     w8, #56     // SYS_OPENAT
    svc     #0

    // store the resulting fd in x10
    mov     x10, x0

    // mmap input file
    mov     x0, #0      // addr = NULL
    mov     x1, #0x5000 // size = pagesize*5
    mov     x2, #0x1    // PROT_READ
    mov     x3, #0x2    // MAP_PRIVATE
    mov     x4, x10     // fd = input file
    mov     w8, #222    // SYS_MMAP
    svc     #0

    // iterate through input
    mov     x0, x0      // x0 will be the iterator (mmap addr)
    mov     x1, #0      // x1 will be the count of elves so far
    mov     x2, #0      // x2 will be the current sum
    mov     x3, #0      // x3 will be the current max elf
    mov     x4, #0      // x4 will be the current max value
    mov     x5, #0      // x5 will be the current value
    mov     x6, #10     // x6 stores constant ten to multiply for decimal->hex conversion

    get_elf_ct:
        ldrb    w7, [x0]   // get value from current position
        cmp     w7, #0xa   // is it a newline?
        bne     not_newline
        newline:
            // if it is a newline:
            add     x2, x2, x5    // add current value to current sum
            mov     x5, #0        // reset current value

            add     x0, x0, #1    //increment iterator
            ldrb    w7, [x0]      // get value from next position
            cmp     w7, #0xa      // is it a newline?
            bne     not_newline
            double_newline:
                // if it is a second newline:
                cmp    x2, x4     // compare current sum with current max
                blt    no_new_max
                new_max:
                    // greater than current max
                    mov    x4, x2     // set current max to current sum
                    mov    x3, x1     // set max elf to current elf
                no_new_max:
                    // not greater than current max
                    add    x1, x1, #1 // two consec newlines, increment elves
                    mov    x2, #0     // reset current value
                b   continue          // skip ascii to hex conversion and continue

        not_newline:
            sub     w8, w7, #0x30     // ascii to hex
            madd    x5, x5, x6, x8    // deci = curr * 10 + deci
        continue:
        add    x0, x0, #1 //increment iterator
        cmp    w7, #0     // is it a null byte
        bne    get_elf_ct // loop if not null

    output:
        mov     x0, #1        // fd = STDOUT
        ldr     x1, =out_msg
        ldr     x2, =out_len
        mov     w8, #64       // SYS_WRITE
        svc     #0

        // hex to ascii
        // char = 0x30 + result - (10*(result/10))
        ldr     x1, =out_data_end // output ptr
        sub     x1, x1, #1        // output ptr--
        mov     x2, #0            // counter
        mov     x6, #10           // const ten

        h2a:
            udiv x3, x4, x6
            mul x3, x3, x6
            sub x3, x4, x3
            cmp x3, #0
            beq h2a_write

            add x3, x3, #0x30
            strb w3, [x1, x2]
            sub x2, x2, #1
            udiv x4, x4, x6
            b h2a

        h2a_write:
        add     x1, x1, x2    // add negative offset to end of output

        mvn     x2, x2        // length = ~(x2)
        add     x2, x2, #2    // length += 2

        mov     x0, #1        // fd = STDOUT
        mov     w8, #64       // SYS_WRITE
        svc     #0

    exit:
        mov     x0, #0
        mov     w8, #93       // SYS_EXIT
        svc     #0

    error:
        mov     x0, #-1
        mov     w8, #93       // SYS_EXIT
        svc     #0

