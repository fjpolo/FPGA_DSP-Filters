import re
import sys

# Instruction Set Architecture (Opcode, Format, Fields)
# Fields: Rd (27:24), Rs1 (23:20), Rs2 (19:16), Imm/Addr (15:0)
ISA = {
    "NOP":         (0b0000, "NOP"),
    "MAC":         (0b0001, "MAC Rs1, Rs2"),  # Acc96 = Acc96 + (Rs1 * Rs2)
    "LOAD":        (0b0010, "LOAD Rd, Addr"),
    "STORE":       (0b0011, "STORE Rs1, Addr"),
    "MOVE":        (0b0100, "MOVE Rd, Imm"),
    "JUMP":        (0b0101, "JUMP Addr"),
    "READ_ACCH":   (0b0110, "READ_ACCH Rd"), # Read High 32 bits (95:64)
    "READ_ACCM":   (0b0111, "READ_ACCM Rd"), # Read Middle 32 bits (63:32)
    "READ_ACCL":   (0b1000, "READ_ACCL Rd"), # Read Low 32 bits (31:0)
    "CLR_ACC":     (0b1001, "CLR_ACC"),      # Clear Accumulator
    "LOAD_ACCR":   (0b1010, "LOAD_ACCR Rs_H, Rs_M, Rs_L"), # Load Acc from 3 Registers
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

    # Allow 20-bit Imm/Addr, although Python uses 16 bits in the instruction format logic
    # The ISA defines the Imm/Addr field as 20 bits [19:0], but the encoding only uses [19:0] if no Rs fields are present.
    # Given the current implementation only uses bits [19:0] for Imm/Addr or split fields (Rs1, Rs2), 
    # and the assembler limits it to 16 bits (0xFFFF) for safety, we'll keep that limit.
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
        # This is the point where the error from the user's prompt occurred.
        raise ValueError(f"Unknown instruction mnemonic: {mnemonic}")

    opcode, format_str = ISA[mnemonic]
    instr = opcode << 28 # Start with the 4-bit opcode

    # --- Instruction Encoding Logic ---

    if mnemonic == "NOP" or mnemonic == "CLR_ACC":
        # NOP: 00000000, CLR_ACC: 90000000
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

    elif mnemonic == "MAC":
        # Format: MAC Rs1, Rs2 (Rd is implicitly 0, but the field must be present)
        if len(parts) != 3:
            raise ValueError(f"Expected MAC Rs1, Rs2")
        # MAC output is written to R0 implicitly, but the instruction structure 
        # is just Rs1 and Rs2, ignoring Rd. We must ensure Rs1/Rs2 are in the right place.
        Rs1 = parse_register(parts[1])
        Rs2 = parse_register(parts[2])
        # Rd is implicitly 0, so we just set Rs1 and Rs2 fields.
        instr |= (Rs1 << 20) | (Rs2 << 16) 

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
        # Uses Rd, Rs1, Rs2 fields for the three source registers
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
    print(f"Assembling {input_file}...")
    
    try:
        # We explicitly assume the input file is the assembly source (.asm)
        with open(input_file, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: Input file not found: {input_file}")
        sys.exit(1)

    hex_instructions = []
    
    # Assembly address tracking for debugging (not used for label resolution here)
    # address = 0 

    for i, line in enumerate(lines):
        try:
            hex_code = assemble_line(line, i + 1)
            if hex_code:
                hex_instructions.append(hex_code)
                # address += 1
        except ValueError as e:
            # Report the error with context
            print(f"Assembly Error on line {i + 1} ('{line.strip()}'): {e}")
            sys.exit(1)

    try:
        with open(output_file, 'w') as f:
            for hex_code in hex_instructions:
                f.write(f"{hex_code}\n")
        print(f"Successfully assembled {len(hex_instructions)} instructions to {output_file}")
        
    except IOError:
        print(f"Error: Could not write to output file: {output_file}")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python assembler.py <input_asm_file> <output_hex_file>")
        print("\nExample Assembly Syntax:")
        print("MOVE R1, 5")
        print("MOVE R2, 0xA")
        print("MAC R1, R2")
        print("READ_ACCL R3")
        print("JUMP 2")
        print("CLR_ACC")
        print("LOAD_ACCR R1, R2, R3")
        sys.exit(1)
        
    main(sys.argv[1], sys.argv[2])