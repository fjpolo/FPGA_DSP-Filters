# RVDSP Co-Processor Instruction Set Architecture (ISA)

This document describes the Instruction Set Architecture (ISA) for the RVDSP Co-Processor. The processor uses a 32-bit fixed-length instruction format and operates on a 16-entry, 32-bit General Purpose Register (GPR) file.

## Key Data Path Widths

| Component | Width | Notes |
| :--- | :--- | :--- |
| **GPRs (Registers)** | 32-bit | General purpose data registers (R0-R15). |
| **Product Register** | 64-bit | Intermediate register for 32x32 $\rightarrow$ 64-bit multiplication result. |
| **Accumulator Register** | 96-bit | Register for Multiply-Accumulate (MAC) operations. Accessed in three 32-bit segments. |
| **Instruction/Data Memory**| 32-bit | Word width for both iMEM and dMEM. |
| **Addresses** | 8-bit (256 words) | Address space for iMEM and dMEM. |

## Instruction Format

All instructions are 32-bits wide. Fields are defined as:

| Bits | Field | Description |
| :--- | :--- | :--- |
| **[31:28]** | **Opcode** | Primary operation code (4 bits). |
| **[27:24]** | **Rd** | Destination Register address (4 bits). |
| **[23:20]** | **Rs1** | Source Register 1 address (4 bits). |
| **[19:16]** | **Rs2** | Source Register 2 address (4 bits). |
| **[19:0]** | **Imm/Addr** | 20-bit Immediate value or Jump/Memory Address. |

---

## Instruction Set Table

| Opcode | Mnemonic | Format | Cycles | Description | Explanation | Example Code |
| :---: | :--- | :---: | :---: | :--- | :--- | :--- |
| **0** | `NOP` | `0xxx xxxx ...` | 1 | No Operation. | Consumes one cycle but performs no action. Used for timing or padding. | `NOP` |
| **1** | `MAC` | `1 Rd, Rs1, Rs2` | 1 | $\text{Acc} \leftarrow \text{Acc} + (\text{Rs1} \times \text{Rs2})$. Writes $\text{Acc}[31:0]$ to Rd. | Performs a signed 32x32 multiply and adds the 64-bit product to the 96-bit **Accumulator (Acc)**. The new $\text{Acc}$ Low Word is written to $\text{Rd}$. | `MAC R0, R1, R2` |
| **2** | `LOAD` | `2 Rd, Addr` | 1 | Load Word: $\text{Rd} \leftarrow \text{dMEM}[\text{Addr}]$. | Loads a 32-bit word from the Data Memory address (0-255) into the destination register $\text{Rd}$. | `LOAD R3, 0x10` |
| **3** | `STORE` | `3 Rs, Addr` | 1 | Store Word: $\text{dMEM}[\text{Addr}] \leftarrow \text{Rs}$. | Stores the 32-bit value in the source register $\text{Rs}$ to the specified Data Memory address (0-255). | `STORE R4, 0x20` |
| **4** | `MOVE` | `4 Rd, Imm` | 1 | Move Immediate: $\text{Rd} \leftarrow \text{SignExtend}(\text{Imm})$. | Loads the 20-bit Immediate value, sign-extended to 32 bits, into the destination register $\text{Rd}$. | `MOVE R5, 0xDEAD` |
| **5** | `JUMP` | `5 Addr` | 1 | Unconditional Jump: $\text{PC} \leftarrow \text{Addr}[7:0]$. | Sets the Program Counter ($\text{PC}$) to the 8-bit $\text{Addr}$, causing execution to resume there on the next cycle. | `JUMP 0xFF` |
| **6** | `READ_ACCH` | `6 Rd` | 1 | Read Accumulator High: $\text{Rd} \leftarrow \text{Acc}[95:64]$. | Reads the **High** 32-bit word of the 96-bit Accumulator into $\text{Rd}$. | `READ_ACCH R6` |
| **7** | `READ_ACCM` | `7 Rd` | 1 | Read Accumulator Middle: $\text{Rd} \leftarrow \text{Acc}[63:32]$. | Reads the **Middle** 32-bit word of the 96-bit Accumulator into $\text{Rd}$. | `READ_ACCM R7` |
| **8 (8)** | `READ_ACCL` | `8 Rd` | 1 | Read Accumulator Low: $\text{Rd} \leftarrow \text{Acc}[31:0]$. | Reads the **Low** 32-bit word of the 96-bit Accumulator into $\text{Rd}$. | `READ_ACCL R8` |
| **9 (9)** | `CLR_ACC` | `9` | 1 | **Clear Accumulator: $\text{Acc} \leftarrow 96'h0$.** | Resets the 96-bit Accumulator register to zero. | `CLR_ACC` |
| **A (10)** | `LOAD_ACCR`| `A Rs_H, Rs_M, Rs_L` | 1 | **Load Accumulator from Registers: $\text{Acc} \leftarrow \{\text{Rs\_H}, \text{Rs\_M}, \text{Rs\_L}\}$.** | Writes the 96-bit concatenation of $\text{Rs\_H}$, $\text{Rs\_M}$, and $\text{Rs\_L}$ directly into the Accumulator. | `LOAD_ACCR R6, R7, R8` |
| **B (11)** | `MUL` | `B Rd, Rs1, Rs2` | 1 | **Multiply: $\{\text{Rd}, \text{Rd}+1\} \leftarrow \text{Rs1} \times \text{Rs2}$.** | Performs a signed 32x32 multiply. The 64-bit result is written to the register pair $\text{Rd}$ (High word) and $\text{Rd}+1$ (Low word). | `MUL R10, R1, R2` |
| **C (12)** | `DIV` | `C Rd, Rs1, Rs2` | 1 | **Divide: $\{\text{Rd}, \text{Rd}+1\} \leftarrow \text{Rs1} / \text{Rs2}$ (Quotient, Remainder).** | Performs a signed 32-bit division ($\text{Rs1} / \text{Rs2}$). The Quotient is written to $\text{Rd}$ and the Remainder is written to $\text{Rd}+1$. | `DIV R12, R1, R2` |
| **D (13)** | `LSETUP` | `D Rd, N, EndAddr` | 1 | **Setup Hardware Loop: $\text{Rd} \leftarrow \text{N}$. Loop $\text{N}$ times from $\text{PC}+1$ up to $\text{EndAddr}$.** | Configures the hardware loop controller. Stores the Loop Count ($\text{N}$, 8-bit immediate) into $\text{Rd}$. The loop iterates $\text{N}$ times, starting at the instruction immediately following `LSETUP` and ending at $\text{EndAddr}$. | `LSETUP R5, 10, 0x1F` |
| **E (14)** | *(Reserved)* | | | | Reserved for future instruction expansion. | |
| **F (15)** | *(Reserved)* | | | | Reserved for future instruction expansion. | |
