// Initialize R1 = 5
    MOVE R1, 5
    // Initialize R2 = 10
    MOVE R2, 10
    
    // Address 2: MAC R0, R1, R2. Acc96 = 0 + (5 * 10) = 50. R0 = 50 (Low 32 bits)
    MAC R1, R2
    
    // Address 3: MAC R0, R1, R2. Acc96 = 50 + (5 * 10) = 100. R0 = 100
    MAC R1, R2
    
    // Address 4: Read Low 32 bits (100) into R3
    READ_ACCL R3
    
    // Address 5: Read Middle 32 bits (0) into R4
    READ_ACCM R4

    // Address 6: Read High 32 bits (0) into R5
    READ_ACCH R5
    
    // Address 7: End of program. JUMP back to Address 4 to continually read the stable value.
    JUMP 4