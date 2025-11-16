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
    if imm_str.startswith('0x'):
        value = int(imm_str, 16)
    else:
        value = int(imm_str, 10)

    if not 0 <= value <= 0xFFFF:
        raise ValueError(f"Immediate/Address value {value} (0x{value:X}) exceeds 16-bit limit.")
    return value

def assemble_line(line, line_num):
    """Parses a single assembly line and returns the 32-bit hex instruction."""
    line = line.split('//')[0].strip() # Remove comments and strip whitespace
    if not line:
        return None # Empty line

    parts = re.split(r'[\s,]+', line)
    mnemonic = parts[0].upper()

    if mnemonic not in ISA:
        raise ValueError(f"Line {line_num}: Unknown instruction mnemonic: {mnemonic}")

    opcode, format_str = ISA[mnemonic]
    instr = opcode << 28 # Start with the 4-bit opcode

    # Register Rd and Rs must be 4 bits
    # Immediate/Address must be 16 bits

    if mnemonic == "NOP":
        return f"{instr:08X}" # 00000000

    elif mnemonic == "MOVE" or mnemonic == "LOAD":
        # Format: MOVE Rd, Imm / LOAD Rd, Addr
        if len(parts) != 3:
            raise ValueError(f"Line {line_num}: Expected {mnemonic} Rd, Imm/Addr")
        Rd = parse_register(parts[1])
        Imm = parse_immediate(parts[2])
        instr |= (Rd << 24) | (Imm & 0xFFFF)
    
    elif mnemonic == "STORE":
        # Format: STORE Rs1, Addr
        if len(parts) != 3:
            raise ValueError(f"Line {line_num}: Expected STORE Rs1, Addr")
        Rs1 = parse_register(parts[1])
        Addr = parse_immediate(parts[2])
        instr |= (Rs1 << 20) | (Addr & 0xFFFF)

    elif mnemonic == "MAC":
        # Format: MAC Rs1, Rs2 (Rd is ignored, so we leave it 0)
        if len(parts) != 3:
            raise ValueError(f"Line {line_num}: Expected MAC Rs1, Rs2")
        Rs1 = parse_register(parts[1])
        Rs2 = parse_register(parts[2])
        instr |= (Rs1 << 20) | (Rs2 << 16) # Rd is assumed 0 (0 << 24)

    elif mnemonic == "JUMP":
        # Format: JUMP Addr
        if len(parts) != 2:
            raise ValueError(f"Line {line_num}: Expected JUMP Addr")
        Addr = parse_immediate(parts[1])
        instr |= (Addr & 0xFFFF)

    elif mnemonic.startswith("READ_ACC"):
        # Format: READ_ACCH/M/L Rd
        if len(parts) != 2:
            raise ValueError(f"Line {line_num}: Expected {mnemonic} Rd")
        Rd = parse_register(parts[1])
        instr |= (Rd << 24)
        
    return f"{instr:08X}"

def main(input_file, output_file):
    """Main function to process the assembly file."""
    print(f"Assembling {input_file}...")
    
    try:
        with open(input_file, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: Input file not found: {input_file}")
        sys.exit(1)

    hex_instructions = []
    
    # Simple placeholder for assembly address tracking (not implemented for JUMP labels)
    address = 0 

    for i, line in enumerate(lines):
        try:
            hex_code = assemble_line(line, i + 1)
            if hex_code:
                hex_instructions.append(hex_code)
                address += 1
        except ValueError as e:
            print(f"Assembly Error on line {i + 1}: {e}")
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
        sys.exit(1)
        
    main(sys.argv[1], sys.argv[2])