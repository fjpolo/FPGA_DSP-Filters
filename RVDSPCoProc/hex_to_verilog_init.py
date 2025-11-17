import sys

def generate_verilog_block(hex_file, output_file=None):
    """
    Reads a .hex file (one instruction per line) and generates a Verilog 
    initial begin...end block for iMEM initialization.
    """
    try:
        with open(hex_file, 'r') as f:
            hex_instructions = [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print(f"Error: Hex file not found: {hex_file}")
        return

    address_bits = 8 # Matches localparam ADDR_BITS in RVDSPCoProc.v
    max_memory_size = 1 << address_bits
    
    if len(hex_instructions) > max_memory_size:
        print(f"Warning: Program size ({len(hex_instructions)}) exceeds iMEM size ({max_memory_size}). Truncating.")
        hex_instructions = hex_instructions[:max_memory_size]

    verilog_output = []
    verilog_output.append(f"// --- Generated from {hex_file} ---")
    verilog_output.append("integer i;")
    verilog_output.append("initial begin")

    # 1. Write Instructions
    for i, hex_code in enumerate(hex_instructions):
        verilog_output.append(f"    iMEM[{i}] = 32'h{hex_code};")

    # 2. Fill the rest of iMEM with NOP (0x00000000)
    if len(hex_instructions) < max_memory_size:
        verilog_output.append("\n    // Initialize the rest of the memory to NOP (0x00000000)")
        verilog_output.append(f"    for (i = {len(hex_instructions)}; i < {max_memory_size}; i++) begin ")
        verilog_output.append("        iMEM[i] = 32'h00000000;")
        verilog_output.append("    end        ")

    # 3. Final block closing and metadata (copied from your original style)
    verilog_output.append("end")
    verilog_output.append("// ----------------------------------")

    output_content = "\n".join(verilog_output)
    
    if output_file:
        try:
            with open(output_file, 'w') as f:
                f.write(output_content + "\n")
            print(f"Successfully generated Verilog block to {output_file}")
        except IOError:
            print(f"Error: Could not write to output file: {output_file}")
    else:
        # Print to console for easy copy/paste
        print("\n" + "="*40)
        print("Generated Verilog initial block (copy/paste into RVDSPCoProc.v):")
        print("="*40)
        print(output_content)
        print("="*40 + "\n")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python hex_to_verilog_init.py <input_hex_file> [output_verilog_file]")
        print("\nExample: python hex_to_verilog_init.py program.hex")
        print("Example: python hex_to_verilog_init.py program.hex imem_init.v")
        sys.exit(1)
        
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    generate_verilog_block(input_file, output_file)