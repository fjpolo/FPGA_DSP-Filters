# RVDSP Co-Processor Instruction Set Architecture (ISA)

This document describes the Instruction Set Architecture (ISA) for the RVDSP Co-Processor. The processor uses a 32-bit fixed-length instruction format and operates on a 16-entry, 32-bit General Purpose Register (GPR) file.

## Key Data Path Widths

| Component | Width | Notes |
| :----- | :----- | :----- |
| **GPRs (Registers)** | 32-bit | General purpose data registers (R0-R15). |
| **Product Register** | 64-bit | Intermediate register for 32x32 $\rightarrow$ 64-bit multiplication result. |
| **Accumulator Register** | 96-bit | Register for Multiply-Accumulate (MAC) operations. Accessed in three 32-bit segments. |
| **Instruction/Data Memory** | 32-bit | Word width for both iMEM and dMEM. |
| **Addresses** | 8-bit (256 words) | Address space for iMEM and dMEM. |

## Instruction Format

All instructions are 32-bits wide. Fields are defined as:

| Bits | Field | Description |
| :----- | :----- | :----- |
| **\[31:28\]** | **Opcode** | Primary operation code (4 bits). |
| **\[27:24\]** | **Rd** | Destination Register address (4 bits). |
| **\[23:20\]** | **Rs1** | Source Register 1 address (4 bits). |
| **\[19:16\]** | **Rs2** | Source Register 2 address (4 bits). |
| **\[19:0\]** | **Imm/Addr** | 20-bit Immediate value or Jump/Memory Address. |

## Instruction Set Table

| Opcode | Mnemonic | Format | Description |
| :---: | :--- | :--- | :--- |
| **0** | `NOP` | `0xxx xxxx xxxx xxxx xxxx xxxx xxxx` | No Operation. |
| **1** | `MAC` | `1 Rd, Rs1, Rs2` | Multiply-Accumulate: $\text{Acc} \leftarrow \text{Acc} + (\text{Rs1} \times \text{Rs2})$. Writes $\text{Acc}[31:0]$ (Low Word) to Rd. |
| **2** | `LOAD` | `2 Rd, Addr` | Load Word: $\text{Rd} \leftarrow \text{dMEM}[\text{Addr}]$. |
| **3** | `STORE` | `3 Rs, Addr` | Store Word: $\text{dMEM}[\text{Addr}] \leftarrow \text{Rs}$. |
| **4** | `MOVE` | `4 Rd, Imm` | Move Immediate: $\text{Rd} \leftarrow \text{SignExtend}(\text{Imm}[19:0])$. |
| **5** | `JUMP` | `5 Addr` | Unconditional Jump: $\text{PC} \leftarrow \text{Addr}[7:0]$ (20-bit field truncated to 8-bit address). |
| **6** | `READ_ACCH` | `6 Rd` | Read Accumulator High: $\text{Rd} \leftarrow \text{Acc}[95:64]$ (High Word). |
| **7** | `READ_ACCM` | `7 Rd` | Read Accumulator Middle: $\text{Rd} \leftarrow \text{Acc}[63:32]$ (Middle Word). |
| **8** | `READ_ACCL` | `8 Rd` | Read Accumulator Low: $\text{Rd} \leftarrow \text{Acc}[31:0]$ (Low Word). |

## Detailed Instruction Descriptions

### 1. `MAC Rd, Rs1, Rs2` (Opcode 1)

This is the core DSP instruction. It performs a 32-bit signed multiplication of $\text{Rs1}$ and $\text{Rs2}$, stores the 64-bit result in the Product Register, and then adds the 64-bit Product Register (sign-extended to 96 bits) to the 96-bit Accumulator.

**Operation:**

1. $\text{Product64} \leftarrow \text{Rs1} \times \text{Rs2}$

2. $\text{Acc96} \leftarrow \text{Acc96} + \text{Product64}_{extended}$

3. $\text{Rd} \leftarrow \text{Acc96}[31:0]$

### 2. `LOAD Rd, Addr` (Opcode 2)

Reads a 32-bit word from the Data Memory (dMEM) at the 8-bit address specified by the lower bits of the instruction's address field and writes it to the destination register $\text{Rd}$.

### 3. `STORE Rs, Addr` (Opcode 3)

Writes the 32-bit content of $\text{Rs1}$ to the Data Memory (dMEM) at the 8-bit address specified by the lower bits of the instruction's address field.

### 4. `MOVE Rd, Imm` (Opcode 4)

Writes the 20-bit Immediate value, sign-extended to 32 bits, into the destination register $\text{Rd}$.

### 5. `JUMP Addr` (Opcode 5)

Sets the Program Counter ($\text{PC}$) to the 8-bit address specified by the lower bits of the instruction's address field, causing an unconditional jump.

### Accumulator Read Instructions

These instructions allow the programmer to access the full 96-bit result stored in the accumulator register (`r_mac_accum_96`) by reading it out in three 32-bit segments.

| Mnemonic | Opcode | Segment Accessed |
| :----- | :---: | :----- |
| **`READ_ACCH`** | 6 | $\text{Rd} \leftarrow \text{Acc96}[95:64]$ (High Word) |
| **`READ_ACCM`** | 7 | $\text{Rd} \leftarrow \text{Acc96}[63:32]$ (Middle Word) |
| **`READ_ACCL`** | 8 | $\text{Rd} \leftarrow \text{Acc96}[31:0]$ (Low Word) |