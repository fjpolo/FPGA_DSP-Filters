import re
import sys

# Instruction Set Architecture (Opcode, Format, Fields)
# Fields: Rd (27:24), Rs1 (23:20), Rs2 (19:16), Imm/Addr (15:0)
ISA = {
    "NOP":         (0b0000, "NOP"),
    "MAC":         (0b0001, "MAC Rd, Rs1, Rs2"), # Acc96 = Acc96 + (Rs1 * Rs2)
    "LOAD":        (0b0010, "LOAD Rd, Addr"),
    "STORE":       (0b0011, "STORE Rs1, Addr"),
    "MOVE":        (0b0100, "MOVE Rd, Imm"),
    "JUMP":        (0b0101, "JUMP Addr"),
    "READ_ACCH":   (0b0110, "READ_ACCH Rd"), # Read High 32 bits (95:64)
    "READ_ACCM":   (0b0111, "READ_ACCM Rd"), # Read Middle 32 bits (63:32)
    "READ_ACCL":   (0b1000, "READ_ACCL Rd"), # Read Low 32 bits (31:0)
    "CLR_ACC":     (0b1001, "CLR_ACC"),      # Clear Accumulator
    "LOAD_ACCR":   (0b1010, "LOAD_ACCR Rs_H, Rs_M, Rs_L"), # Load Acc from 3 Registers
    "MUL":         (0b1011, "MUL Rd, Rs1, Rs2"), # Multiply 32x32 -> 64 bits (Rd=High, Rd+1=Low)
    "DIV":         (0b1100, "DIV Rd, Rs1, Rs2"), # Divide 32/32 -> Quotient (Rd), Remainder (Rd+1)
}

def parse_register(reg_str):
    """Converts Rx string to 4-bit integer."""
    match = re.match(r'^R(\d+)$', reg_str.strip())
    if not match:
        raise ValueError(f"Invalid register format: {reg_str}")
    reg_val = int(match.group(1))
    if not 0 <= reg_val <= 15:
        raise ValueError(f"Register index out of range (0-15): {reg_val}")
    return reg_val

def parse_immediate(imm_str):
    """Converts immediate/address string (decimal or hex) to 16-bit integer."""
    imm_str = imm_str.strip()
    # Check for empty string before attempting conversion
    if not imm_str:
        raise ValueError("Immediate/Address cannot be empty.")
        
    if imm_str.startswith('0x'):
        value = int(imm_str, 16)
    else:
        value = int(imm_str, 10)

    # Limiting to 16 bits (0xFFFF) for safety, although the field is 20 bits.
    if not 0 <= value <= 0xFFFF:
        raise ValueError(f"Immediate/Address value {value} (0x{value:X}) exceeds 16-bit limit (0xFFFF).")
    return value

def assemble_line(line, line_num):
    """Parses a single assembly line and returns the 32-bit hex instruction."""
    line = line.split('//')[0].strip() # Remove comments and strip whitespace
    if not line:
        return None # Empty line

    # Replace commas and multiple spaces with a single space for consistent splitting
    parts = re.split(r'[\s,]+', line)
    
    # Filter out empty strings that might result from splitting (e.g., if input had 'MAC R1, , R2')
    parts = [p for p in parts if p]
    
    if not parts:
        return None
        
    mnemonic = parts[0].upper()

    if mnemonic not in ISA:
        raise ValueError(f"Unknown instruction mnemonic: {mnemonic}")

    opcode, format_str = ISA[mnemonic]
    instr = opcode << 28 # Start with the 4-bit opcode

    # --- Instruction Encoding Logic ---

    if mnemonic == "NOP" or mnemonic == "CLR_ACC":
        return f"{instr:08X}" 

    elif mnemonic == "MOVE" or mnemonic == "LOAD":
        # Format: MOVE Rd, Imm / LOAD Rd, Addr
        if len(parts) != 3:
            raise ValueError(f"Expected {mnemonic} Rd, Imm/Addr")
        Rd = parse_register(parts[1])
        Imm = parse_immediate(parts[2])
        instr |= (Rd << 24) | (Imm & 0xFFFF)
    
    elif mnemonic == "STORE":
        # Format: STORE Rs1, Addr
        if len(parts) != 3:
            raise ValueError(f"Expected STORE Rs1, Addr")
        Rs1 = parse_register(parts[1])
        Addr = parse_immediate(parts[2])
        instr |= (Rs1 << 20) | (Addr & 0xFFFF)

    elif mnemonic == "MAC" or mnemonic == "MUL" or mnemonic == "DIV":
        # Format: MAC Rd, Rs1, Rs2 / MUL Rd, Rs1, Rs2 / DIV Rd, Rs1, Rs2
        if len(parts) != 4:
            raise ValueError(f"Expected {mnemonic} Rd, Rs1, Rs2")
            
        Rd = parse_register(parts[1])
        Rs1 = parse_register(parts[2])
        Rs2 = parse_register(parts[3])
        
        # Encoding: Rd << 24 | Rs1 << 20 | Rs2 << 16
        instr |= (Rd << 24) | (Rs1 << 20) | (Rs2 << 16)


    elif mnemonic == "JUMP":
        # Format: JUMP Addr
        if len(parts) != 2:
            raise ValueError(f"Expected JUMP Addr")
        Addr = parse_immediate(parts[1])
        instr |= (Addr & 0xFFFF)

    elif mnemonic.startswith("READ_ACC"):
        # Format: READ_ACCH/M/L Rd
        if len(parts) != 2:
            raise ValueError(f"Expected {mnemonic} Rd")
        Rd = parse_register(parts[1])
        instr |= (Rd << 24)
        
    elif mnemonic == "LOAD_ACCR":
        # Format: LOAD_ACCR Rs_H, Rs_M, Rs_L
        if len(parts) != 4:
            raise ValueError(f"Expected LOAD_ACCR Rs_H, Rs_M, Rs_L (3 registers)")
        
        Rs_H = parse_register(parts[1]) # High word source (uses Rd field)
        Rs_M = parse_register(parts[2]) # Middle word source (uses Rs1 field)
        Rs_L = parse_register(parts[3]) # Low word source (uses Rs2 field)
        
        # Encoding: Rd(Rs_H) << 24 | Rs1(Rs_M) << 20 | Rs2(Rs_L) << 16
        instr |= (Rs_H << 24) | (Rs_M << 20) | (Rs_L << 16)
        
    return f"{instr:08X}"

def main(input_file, output_file):
    """Main function to process the assembly file."""
    try:
        with open(input_file, 'r') as f:
            lines = f.readlines()
        
        hex_instructions = []
        for i, line in enumerate(lines):
            try:
                hex_instr = assemble_line(line, i + 1)
                if hex_instr:
                    hex_instructions.append(hex_instr)
            except ValueError as e:
                print(f"Error on line {i+1}: {line.strip()}\n  {e}", file=sys.stderr)
                # Exit gracefully or skip line, depending on required robustness
                sys.exit(1)

        with open(output_file, 'w') as f:
            for hex_instr in hex_instructions:
                f.write(f"{hex_instr}\n")
        
        # print(f"Successfully assembled {len(hex_instructions)} instructions to {output_file}")

    except FileNotFoundError:
        print(f"Error: Input file not found at {input_file}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    # Simplified main for in-context execution:
    if len(sys.argv) != 3:
        pass
    else:
        main(sys.argv[1], sys.argv[2])
    pass