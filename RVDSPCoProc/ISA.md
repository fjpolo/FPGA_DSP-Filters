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
| **9** | `CLR_ACC` | `9` | **Clear Accumulator: $\text{Acc} \leftarrow 96'h0$.** |
| **A (10)** | `LOAD_ACCR`| `A Rs_H, Rs_M, Rs_L` | **Load Accumulator from Registers: $\text{Acc} \leftarrow \{\text{Rs\_H}, \text{Rs\_M}, \text{Rs\_L}\}$.** |

---

## Detailed Instruction Descriptions (New)

### 9. `CLR_ACC` (Opcode 9)

Resets the entire 96-bit Accumulator register to zero in a single cycle.

**Operation:**
$\text{Acc96} \leftarrow 96'h000000000000000000000000$

### 10. `LOAD_ACCR Rs_H, Rs_M, Rs_L` (Opcode A)

Loads the 96-bit Accumulator from three General Purpose Registers (GPRs) in a single cycle.

* **Rs\_H** (Register High) is taken from the **Rd** field (`[27:24]`).
* **Rs\_M** (Register Middle) is taken from the **Rs1** field (`[23:20]`).
* **Rs\_L** (Register Low) is taken from the **Rs2** field (`[19:16]`).

**Operation:**
$\text{Acc96}[95:64] \leftarrow \text{Rs\_H}$
$\text{Acc96}[63:32] \leftarrow \text{Rs\_M}$
$\text{Acc96}[31:0] \leftarrow \text{Rs\_L}$