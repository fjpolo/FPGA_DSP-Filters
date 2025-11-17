    // Initialize registers for LOAD_ACCR test:
    // R1 (High): 0x00000000
    MOVE R1, 0
    // R2 (Middle): 0x00000000
    MOVE R2, 0
    // R3 (Low): 0x00000002
    MOVE R3, 2
    // Address 3: CLR_ACC. Acc96 = 0
    CLR_ACC
    // Address 4: LOAD_ACCR R1, R2, R3. Acc96 = {R1, R2, R3} = 0x00000000_00000000_00000002
    LOAD_ACCR R1, R2, R3
    // Address 5: Read High 32 bits (R1) into R4
    READ_ACCH R4
    // Address 6: Read Middle 32 bits (R2) into R5
    READ_ACCM R5
    // Address 7: Read Low 32 bits (R3) into R6
    READ_ACCL R6
    // R1 (High): 0x00000002
    MOVE R1, 2
    // R2 (Middle): 0x00000002
    MOVE R2, 2
    // Address 10: Run a single MAC to ensure it still works: (1*1) + Acc = 1 + Acc
    MAC R0, R1, R2
    // R1 (High): 0x00000000
    MOVE R8, 3
    // R2 (Middle): 0x00000000
    MOVE R9, 3
    // Address 13: MUL R10, R8, R9. R10 = High (0), R11 = Low (30)
    MUL R10, R8, R9
    // R12 (High): 0x0000000A
    MOVE R12, 10
    // R13 (Middle): 0x00000003
    MOVE R13, 3
    // Address 15: DIV R14, R12, R13. R14 = Quotient, R15 = Remainder
    DIV R14, R12, R13
    // Address 16: JUMP back to Address 5 to continually read the stable value.
    JUMP 5