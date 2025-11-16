// Initialize registers for LOAD_ACCR test:
    // R1 (High): 0x00000001
    MOVE R1, 1
    // R2 (Middle): 0x00000002
    MOVE R2, 2
    // R3 (Low): 0x00000003
    MOVE R3, 3
    // Address 3: CLR_ACC. Acc96 = 0
    CLR_ACC
    // Address 4: LOAD_ACCR R1, R2, R3. Acc96 = {R1, R2, R3} = 0x00000001_00000002_00000003
    LOAD_ACCR R1, R2, R3
    // Address 5: Read High 32 bits (R1) into R4
    READ_ACCH R4
    // Address 6: Read Middle 32 bits (R2) into R5
    READ_ACCM R5
    // Address 7: Read Low 32 bits (R3) into R6
    READ_ACCL R6
    // Address 8: Run a single MAC to ensure it still works: (1*1) + Acc = 1 + Acc
    MAC R1, R1 
    // Address 9: JUMP back to Address 5 to continually read the stable value.
    JUMP 5