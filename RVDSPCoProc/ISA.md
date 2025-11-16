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

| Opcode | Mnemonic | Format | Cycles | Description |
| :---: | :--- | :---: | :---: | :--- |
| **0** | `NOP` | `0xxx xxxx ...` | 1 | No Operation. |
| **1** | `MAC` | `1 Rd, Rs1, Rs2` | 1 | $\text{Acc} \leftarrow \text{Acc} + (\text{Rs1} \times \text{Rs2})$. Writes $\text{Acc}[31:0]$ to Rd. |
| **2** | `LOAD` | `2 Rd, Addr` | 1 | Load Word: $\text{Rd} \leftarrow \text{dMEM}[\text{Addr}]$. |
| **3** | `STORE` | `3 Rs, Addr` | 1 | Store Word: $\text{dMEM}[\text{Addr}] \leftarrow \text{Rs}$. |
| **4** | `MOVE` | `4 Rd, Imm` | 1 | Move Immediate: $\text{Rd} \leftarrow \text{SignExtend}(\text{Imm})$. |
| **5** | `JUMP` | `5 Addr` | 1 | Unconditional Jump: $\text{PC} \leftarrow \text{Addr}[7:0]$. |
| **6** | `READ_ACCH` | `6 Rd` | 1 | Read Accumulator High: $\text{Rd} \leftarrow \text{Acc}[95:64]$. |
| **7** | `READ_ACCM` | `7 Rd` | 1 | Read Accumulator Middle: $\text{Rd} \leftarrow \text{Acc}[63:32]$. |
| **8 (8)** | `READ_ACCL` | `8 Rd` | 1 | Read Accumulator Low: $\text{Rd} \leftarrow \text{Acc}[31:0]$. |
| **9 (9)** | `CLR_ACC` | `9` | 1 | **Clear Accumulator: $\text{Acc} \leftarrow 96'h0$.** |
| **A (10)** | `LOAD_ACCR`| `A Rs_H, Rs_M, Rs_L` | 1 | **Load Accumulator from Registers: $\text{Acc} \leftarrow \{\text{Rs\_H}, \text{Rs\_M}, \text{Rs\_L}\}$.** |
| **B (11)** | `MUL` | `B Rd, Rs1, Rs2` | 1 | **Multiply: $\{\text{Rd}, \text{Rd}+1\} \leftarrow \text{Rs1} \times \text{Rs2}$.** |
| **C (12)** | `DIV` | `C Rd, Rs1, Rs2` | 1 | **Divide: $\{\text{Rd}, \text{Rd}+1\} \leftarrow \text{Rs1} / \text{Rs2}$ (Quotient, Remainder).** |
| **D (13)** | `LSETUP` | `D Rd, N, EndAddr` | 1 | **Setup Hardware Loop: $\text{Rd} \leftarrow \text{N}$. Loop $\text{N}$ times from $\text{PC}+1$ up to $\text{EndAddr}$.** |
| **E (14)** | `RSHR` | `E Rd, Rs1, Imm` | 1 | **Rounding Shift Right: $\text{Rd} \leftarrow \text{Round}(\text{Rs1} \gg \text{Imm}[4:0])$.** |
| **F (15)** | `MAC4` | `F Rs1, Rs2` | 1 | **4-way 16-bit MAC: Acc $\leftarrow$ Acc + (Rs1[15:0] * Rs2[15:0]) + (Rs1[31:16] * Rs2[31:16])** (Lower two 16-bit products). Result is 64-bit and accumulated. |
