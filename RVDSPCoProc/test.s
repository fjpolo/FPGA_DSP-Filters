// 1. Initialize Registers (MAC4 Inputs)
MOVE R4, 5          // R4 = 5 (First pair, first operand)
MOVE R5, 10         // R5 = 10 (First pair, second operand)
MOVE R6, 2          // R6 = 2 (Second pair, first operand)
MOVE R7, 3          // R7 = 3 (Second pair, second operand)

// 2. Setup
CLR_ACC             // Clear the Accumulator (ACC = 0)

// 3. Execution
// ACC += (R4 * R5) + (R6 * R7)
MAC4 R4, R6         // Expected ACC = 56 (0x38)