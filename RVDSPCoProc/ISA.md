## 💻 DSP Coprocessor Documentation

### 1. Instruction Set Architecture (ISA)

The coprocessor uses a 32-bit register-based ISA.

#### Fixed-Point Format
* **Format:** **Q15.16** (1 Sign Bit, 15 Integer Bits, 16 Fractional Bits).
* **Data Size:** 32 bits.
* **Accumulator:** 64 bits (for internal MAC results).

#### Registers
* **Register File (GPRs):** 16 General Purpose Registers (R0-R15), 32-bits wide.

#### Instruction Format
A single 32-bit instruction word:

| Bits [31:28] | Bits [27:24] | Bits [23:20] | Bits [19:0] |
| :--- | :--- | :--- | :--- |
| **Opcode** (4b) | **Rd** (4b) | **Rs1/Rs** (4b) | **Rs2/Addr/Imm** (20b) |

| Field | Description |
| :--- | :--- |
| **Opcode** | Specifies the operation. |
| **Rd** | Destination Register address (Write to). |
| **Rs1** | Source Register 1 address (Read from). |
| **Rs2** | Source Register 2 address (Read from). |
| **Addr/Imm** | Immediate value or Memory/Jump Address. |

#### Instruction Set

| Instruction | Opcode (4b) | Format | Description |
| :--- | :--- | :--- | :--- |
| **NOP** | `4'b0000` | - | No Operation. |
| **MAC** | `4'b0001` | `Rd, Rs1, Rs2` | $R_{d} \leftarrow R_{d} + (R_{s1} \times R_{s2})$ (32x32 $\rightarrow$ 64-bit Accumulation, result truncated to 32 bits if written out). |
| **LOAD** | `4'b0010` | `Rd, Addr` | $R_{d} \leftarrow \text{dMEM}[\text{Addr}]$ (Load word from Data Memory). |
| **STORE** | `4'b0011` | `Rs, Addr` | $\text{dMEM}[\text{Addr}] \leftarrow R_{s}$ (Store word to Data Memory). |
| **MOVE** | `4'b0100` | `Rd, Imm` | $R_{d} \leftarrow \text{Imm}$ (Load 20-bit immediate value, sign-extended if needed, into $R_d$). |
| **JUMP** | `4'b0101` | `Addr` | $\text{PC} \leftarrow \text{Addr}$ (Unconditional jump to 20-bit address). |

---

### 2. Coprocessor Memory Map (Wishbone Access)

The coprocessor acts as a **Wishbone Slave**. All addresses are 32-bit word addresses (`WBS_ADR_I` points to a 4-byte word).

| Base Address (Hex) | End Address (Hex) | Size (Words) | Size (Bytes) | Component | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`0x0000_0000`** | `0x0000_00FF` | 256 | 1024 | **Program BSRAM (iMEM)** | Stores the DSP Instruction sequence. |
| **`0x0000_0100`** | `0x0000_01FF` | 256 | 1024 | **Data BSRAM (dMEM)** | Stores input data, coefficients, and results. |
| **`0x0000_0200`** | `0x0000_020F` | 16 | 64 | **Register File (GPRs)** | External peek/poke access to the 16 GPRs (R0-R15). |
| **`0x0000_0210`** | `0x0000_0213` | 4 | 16 | **Control & Status Registers** | Interface for the host CPU to manage the coprocessor. |

#### Control & Status Registers

| Address Offset (from Base) | Name | Type | Description |
| :--- | :--- | :--- | :--- |
| `0x0000_0210` | **`CONTROL`** | R/W | **Bit 0 (START/STOP):** `1` starts execution, `0` halts. |
| `0x0000_0211` | **`STATUS`** | R/O | **Bit 0 (DONE):** `1` if execution is halted/finished. |
| `0x0000_0212` | **`PC_LATCH`** | R/O | Read-only view of the current **Program Counter**. |
| `0x0000_0213` | **`INT_ENABLE`** | R/W | Enable different interrupt sources (e.g., overflow). |