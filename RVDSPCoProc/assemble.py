import re
import sys

# --- Instruction Definitions ---
# The 'fields' tuple defines (field_name, field_bit_width, field_start_position)
INSTRUCTION_MAP = {
    # Opcode 0
    'NOP': {
        'opcode': 0x0, 
        'format': '',
        'fields': []
    },
    
    # Opcode 1: MAC Rd, Rs1, Rs2
    'MAC': {
        'opcode': 0x1,
        'format': 'Rd,Rs1,Rs2',
        'fields': [('Rd', 4, 24), ('Rs1', 4, 20), ('Rs2', 4, 16)]
    },
    
    # Opcode 2: LOAD Rd, Addr
    'LOAD': {
        'opcode': 0x2,
        'format': 'Rd,Addr',
        'fields': [('Rd', 4, 24), ('Addr', 8, 0)]
    },
    
    # Opcode 3: STORE Rs1, Addr (Rs1 is the register being stored)
    'STORE': {
        'opcode': 0x3,
        'format': 'Rs1,Addr',
        'fields': [('Rs1', 4, 20), ('Addr', 8, 0)]
    },
    
    # Opcode 4: MOVE Rd, Imm (20-bit immediate)
    'MOVE': {
        'opcode': 0x4,
        'format': 'Rd,Imm',
        'fields': [('Rd', 4, 24), ('Imm', 20, 0)]
    },
    
    # Opcode 5: JUMP Addr (8-bit address)
    'JUMP': {
        'opcode': 0x5,
        'format': 'Addr',
        'fields': [('Addr', 8, 0)]
    },

    # Opcode 6: READ_ACCH Rd (Read Accumulator High)
    'READ_ACCH': {
        'opcode': 0x6,
        'format': 'Rd',
        'fields': [('Rd', 4, 24)]
    },
    
    # Opcode 7: READ_ACCM Rd (Read Accumulator Middle)
    'READ_ACCM': {
        'opcode': 0x7,
        'format': 'Rd',
        'fields': [('Rd', 4, 24)]
    },

    # Opcode 8: READ_ACCL Rd (Read Accumulator Low)
    'READ_ACCL': {
        'opcode': 0x8,
        'format': 'Rd',
        'fields': [('Rd', 4, 24)]
    },

    # Opcode 9: CLR_ACC
    'CLR_ACC': {
        'opcode': 0x9,
        'format': '',
        'fields': []
    },
    
    # Opcode A (10): LOAD_ACCR Rs_H, Rs_M, Rs_L
    # Rs_H uses Rd field, Rs_M uses Rs1 field, Rs_L uses Rs2 field
    'LOAD_ACCR': {
        'opcode': 0xA,
        'format': 'Rs_H,Rs_M,Rs_L',
        'fields': [('Rs_H', 4, 24), ('Rs_M', 4, 20), ('Rs_L', 4, 16)]
    },

    # Opcode B (11): MUL Rd, Rs1, Rs2
    'MUL': {
        'opcode': 0xB,
        'format': 'Rd,Rs1,Rs2',
        'fields': [('Rd', 4, 24), ('Rs1', 4, 20), ('Rs2', 4, 16)]
    },

    # Opcode C (12): DIV Rd, Rs1, Rs2 (Rd = Quotient, Rd+1 = Remainder)
    'DIV': {
        'opcode': 0xC,
        'format': 'Rd,Rs1,Rs2',
        'fields': [('Rd', 4, 24), ('Rs1', 4, 20), ('Rs2', 4, 16)]
    },
    
    # Opcode D (13): LSETUP Rd, N (Loop Count), EndAddr
    'LSETUP': {
        'opcode': 0xD,
        'format': 'Rd,N,EndAddr',
        'fields': [('Rd', 4, 24), ('N', 8, 16), ('EndAddr', 8, 8)]
    },

    # Placeholder for Opcode E (14) - RSHR
    'RSHR': {
        'opcode': 0xE,
        'format': 'Rd,Rs1,Imm',
        'fields': [('Rd', 4, 24), ('Rs1', 4, 20), ('Imm', 5, 0)]
    },

    # Placeholder for Opcode F (15) - MAC4
    'MAC4': {
        'opcode': 0xF,
        'format': 'Rs1,Rs2',
        'fields': [('Rs1', 4, 20), ('Rs2', 4, 16)]
    },
}

# --- Utility Functions ---

def parse_operand(op_str):
    """
    Parses an operand string (e.g., "R10", "15", "0xdead").
    Returns the numeric value.
    """
    op_str = op_str.strip()
    
    # Check for register format R<num>
    reg_match = re.match(r'^R(\d+)$', op_str, re.IGNORECASE)
    if reg_match:
        val = int(reg_match.group(1))
        if 0 <= val <= 15:
            return val
        else:
            raise ValueError(f"Register number '{val}' is out of range (0-15).")

    # Check for hex immediate
    if op_str.lower().startswith('0x'):
        return int(op_str, 16)

    # Check for decimal immediate
    try:
        return int(op_str)
    except ValueError:
        raise ValueError(f"Invalid operand format or value: '{op_str}'")

def assemble_line(line_number, line):
    """
    Assembles a single line of assembly code.
    Returns the 32-bit machine code as an integer.
    """
    # --- FIX: Handle both '//' (C-style) and ';' (Assembly-style) comments ---
    # 1. Split by C-style comment (//) first
    line = line.split('//')[0] 
    
    # 2. Split by Assembly-style comment (;) and trim whitespace
    line = line.split(';')[0].strip()
    
    if not line:
        return None

    # Use regex to split instruction and operands
    match = re.match(r'(\w+)\s*(.*)', line)
    if not match:
        raise ValueError(f"Syntax error on line {line_number}: Invalid instruction format.")

    mnemonic = match.group(1).upper()
    operands_str = match.group(2).strip()

    if mnemonic not in INSTRUCTION_MAP:
        raise ValueError(f"Unknown instruction '{mnemonic}' on line {line_number}.")

    instr_def = INSTRUCTION_MAP[mnemonic]
    
    # Parse operands
    if operands_str:
        operands = [op.strip() for op in operands_str.split(',')]
    else:
        operands = []

    # Check operand count
    expected_count = len(instr_def['format'].split(',')) if instr_def['format'] else 0
    if len(operands) != expected_count:
        raise ValueError(f"Incorrect number of operands for '{mnemonic}' on line {line_number}. Expected {expected_count}, got {len(operands)}.")

    # Initialize instruction word with opcode
    instruction_word = instr_def['opcode'] << 28
    
    # Process fields
    for i, (field_name, width, start_bit) in enumerate(instr_def['fields']):
        op_val = parse_operand(operands[i])
        
        # Check value bounds
        max_val = (1 << width) - 1
        if op_val < 0 or op_val > max_val:
            # Note: 20-bit MOVE Imm allows signed, but we check max unsigned here
            if field_name != 'Imm' or op_val < -(1 << (width - 1)) or op_val >= (1 << (width - 1)):
                # For 20-bit immediate, allow signed range check for MOVE
                if field_name == 'Imm' and mnemonic == 'MOVE':
                    # Value is okay, just needs to fit in 20 bits
                    pass
                else:
                    raise ValueError(f"Value '{op_val}' for field '{field_name}' exceeds {width}-bit unsigned limit on line {line_number}.")
            
        # Apply mask and shift
        # The '& max_val' ensures only the lower 'width' bits are used.
        instruction_word |= ((op_val & max_val) << start_bit)

    return instruction_word

def assemble(assembly_code):
    """
    Main assembly function.
    Returns a list of 32-bit integers (machine code).
    """
    machine_code = []
    lines = assembly_code.split('\n')
    
    for line_number, line in enumerate(lines, 1):
        try:
            instruction = assemble_line(line_number, line)
            if instruction is not None:
                machine_code.append(instruction)
        except ValueError as e:
            print(f"Assembly Error: {e}", file=sys.stderr)
            # Exit on the first error to keep error messages simple
            sys.exit(1) 
            
    return machine_code

if __name__ == '__main__':
    # We expect two arguments: <assembly_file.asm> and <output_file.hex>
    if len(sys.argv) < 3:
        print("Usage: python assembler.py <assembly_file.asm> <output_file.hex>", file=sys.stderr)
        sys.exit(1)

    input_file_path = sys.argv[1]
    output_file_path = sys.argv[2]

    try:
        with open(input_file_path, 'r') as f:
            asm_code = f.read()
    except FileNotFoundError:
        print(f"Error: Input assembly file not found: {input_file_path}", file=sys.stderr)
        sys.exit(1)

    # 1. Assemble the code
    code = assemble(asm_code)
    
    # 2. Write the machine code to the specified output file in HEX format
    try:
        with open(output_file_path, 'w') as f:
            for word in code:
                # Prints in 8-digit hexadecimal format (32 bits), followed by a newline
                f.write(f"{word:08X}\n")
        print(f"Successfully assembled {len(code)} instructions to '{output_file_path}'.")
    except Exception as e:
        print(f"Error writing output file '{output_file_path}': {e}", file=sys.stderr)
        sys.exit(1)