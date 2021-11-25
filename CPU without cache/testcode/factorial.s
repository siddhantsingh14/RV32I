factorial.s:
.align 4
.section .text
.globl factorial
factorial:
        # self note of what registers to use x10-x11 -> a0-a1 & x12-x17 -> a2-a7. these are int types so 4 bytes
        # x1 -> ra the return address so dont use random values in this reg
        # x2 is the stack pointer
        # x5 to x7 are temporaries
        # Register a0 holds the input value
        # Register t0-t6 are caller-save, so you may use them without saving
        # Return value need to be put in register a0
        # Your code starts here
        lw a0, some_label       # contains val
        addi a2, a0, -1         # contains val -1
        la t0, store_mult_a
        sw a0, 0(t0)    # storing in a mem addr to access later
        la t1, store_mult_b     
        sw a2, 0(t1)    # storing in a mem addr to access later
        addi a2, a2, -1         # contains val -2
        la t0, some_label     
        sw a2, 0(t0)    # storing the next number that will need to be multiplied to the mem addr
        beq a2,a2, mult_start   # unconditional jmp to start multiplication

factorial_loop:
        lw t1, some_label
        andi t2, t2, 0
        addi t2, t2, 1
        beq t1, t2, done        # the next number to be multiplied is 1 so that means "store_product has the result"
        lw t3, store_product
        la t4, store_mult_a
        sw t3, 0(t4)    # storing in a mem addr to access later
        la t5, store_mult_b     
        sw t1, 0(t5)    # storing in a mem addr to access later
        addi t1, t1, -1 # sub for next number to be multiplied
        la t0, some_label     
        sw t1, 0(t0)    # storing the next number that will need to be multiplied to the mem addr

mult_start:
        lw t1, store_mult_a
        lw t2, store_mult_b
        andi t3, t3, 0  # clearing loop tracking var
        andi t4, t4, 0  # clearing the partial mult prod 
mult_loop:
        add t4, t4, t1  
        addi t2, t2, -1 # subtract the number of times you still need to add
        bne t2, t3, mult_loop

        la t5, store_product
        sw t4, 0(t5)
        beq t3, t3, factorial_loop

done:
        lw a0, store_product
        

ret: 
        jr ra # Register ra holds the return address
.section .rodata
# if you need any constants
some_label:    .word 0x0000000A        # starting val. factorial to be calculated is some_label!
store_product: .word 0x00000000        # product of a * b 
store_mult_a: .word 0x00000000 # acts as temp store for multiplication and this is obtained from the product of multiplications
store_mult_b: .word 0x00000000        # gets from some_label is generally the some_label -1 every loop till some_label is 1 and then factorial need not be executed