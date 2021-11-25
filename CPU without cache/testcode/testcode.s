riscv_mp2test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    lw x1, result
    addi x1, x1, 5  # r1 has 5
    addi x2, x1 ,5  # r2 has 10
    lw x6, result_a
    jalr x5, 0(x6)
    # jal x5, offset  # store pc+4 in x5
    addi x4, x1, 2  # r4 has 7

offset:
    add x3, x1, x2  # r3 has r4

threshold:  .word 0x00000040
loading_check:  .word 0xECEBFACE

addr_a: .byte 0x11
addr_b: .byte 0x22
addr_c: .byte 0x33
addr_d: .byte 0x44
addr_word: .word 0x87654321
result: .word 0x00000000
result_a: .word 0x00000080



# all the tested instructions

# lw x1, loading_check
    # la x2, result      # X2 <= Addr of result
    # sh x1, 0(x2)
    # sh x1, 2(x2)
    # sb x1, 0(x2)       # [Result] <= 0xECEBFACE
    # sb x1, 1(x2)       # [Result] <= 0xECEBFACE
    # sb x1, 2(x2)       # [Result] <= 0xECEBFACE
    # sb x1, 3(x2)       # [Result] <= 0xECEBFACE
    # lbu x3, result
    # lhu x4, result
    # lhu x5, result+2
    # la x4, result_addr2
    # sh x3, 0(x4)
    # lh x5, result_addr2
    # la x6, result_addr3
    # sb x5, 0(x6)
    # lb x7, result_addr2
    

    # lw  x1, loading_check
    # lbu x2, addr_a
    # lb x3, addr_b
    # lhu x4, addr_a
    # lh x5, addr_c
    # lw x6, addr_a
    # lb x7, addr_e+1
    # lh x8, addr_word +1
    # lh x8, addr_word + 2
    # addi x1, x2, 4
    # addi x2, x1, 5
    # addi x1, x2, 1  
    # addi works doing further test now  

    # addi x3, x2, 118    # set to 127
    # so R1-10 (1010), R2- 9(1001) and R3 - 127 (01111111)

    # add x4, x1, x2  # r4 should have 19 decimal

    # sub x5, x2, x3  # r5 should have -118
    # sub x6, x1, x2  # r6 should have 1

    # sll x7, x6, x1  # should store 2^10

    # slt x8, x5, x3  # -118 < 127 so set 1 in r8

    # sltu x9, x5, x4 # 118> 19 so store 0 in r9

    # xor x10, x1, x2 # store 3 in r10 and xor 10 and 9

    # or x11, x1, x2  # store 11 in r11

    # and x12, x1, x2  # store 8 in r12

    # srl x13, x7, x1 # store 1 in r13

    # sra x14, x5, x6    # shift right by 1 so store - 59



    # xori x6, x4, 7   # r6 should have 13

    # andi x7, x3, 129    # should store 1 in r7
    

    # ori x8, x5, 6 # should store 15 in r8

    # slli x9, x7, 1  # shift by 1 so r9 should have 2

    # slli x10, x7, 3  # shift by 3 so r10 should have 8

    # slli x11, x7, 5  # shift by 5 so r11 should have 32

    # slli x12, x4, 2  # shift by 2 so r12 should have 40

    # srli x13, x9, 1  # shift by 1 so r13 should have 1

    # srli x14, x10, 3  # shift by 3 so r14 should have 1

    # srli x15, x11, 4  # shift by 5 so r15 should have 2

    # addi x16, x5, -20   # 16 should have -11
    
    # slti x17, x11, 31 # 32>31 so store 0

    # slti x18, x11, 33 # 32<33 so store 1

    # slti x19, x16, 13 # 11<13 so store 1

    # sltiu x20, x5, 10 # 9<10 so store 1

    # lui x21, 1  # store 4096

    # auipc x22, 1    # store 4096 + pc (176)

    # addi x23, x4, -18   # store any -8
    # srai x24, x23, 2    # right shift 2 so store -2

    # bgeu x23, x14, goodpc # pc goes to 

    # addi x25,x5,2   # store 11 in 25

    # lw  x1, threshold
    

    # lui  x1, 2  # should place 2 in the 14th bit

    # goodpc:       
      #  addi x26,x5,4   # store 13 in 26