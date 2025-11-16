// =============================================================================
// File        : RVDSPCoProc.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : DSP Coprocessor RTL
// License     : MIT License
//
// Copyright (c) 2025 | @fjpolo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS"
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// =============================================================================

`default_nettype none
`timescale 1ps/1ps

module RVDSPCoProc(
    // Global Signals
    input  wire         i_clk,    // Clock 
    input  wire         i_rst_n  // Active low reset 
    );

    // Configuration Constants 
    localparam ADDR_BITS     = 8;             // 256 word memory size (iMEM/dMEM)
    localparam REG_ADDR_BITS = 4;             // 16 registers
    localparam REG_COUNT     = 1 << REG_ADDR_BITS;
    
    // Core Pipeline Signals - Single-Cycle FSM
    reg [31:0]                  pc_reg;       
    reg [31:0]                  pc_next;      
    reg [31:0]                  instruction;  
    reg [3:0]                   opcode;       
    reg [REG_ADDR_BITS-1:0]     rd_addr, rs1_addr, rs2_addr; 
    wire [31:0]                 reg_rdata1, reg_rdata2;     
    
    // Multi-write Register Path Controls (for MUL)
    reg                         reg_we_mul_high; // Write enable for Rd (High word)
    reg                         reg_we_mul_low;  // Write enable for Rd+1 (Low word)
    reg [3:0]                   rd_addr_low;     // Destination address for Low word (Rd+1)
    reg [31:0]                  reg_wdata_high;  // Data for Rd (High word)
    reg [31:0]                  reg_wdata_low;   // Data for Rd+1 (Low word)
    
    // Single-write Register Path Controls (for MAC, LOAD, READ_ACC, MOVE)
    reg                         reg_we_single;
    reg [3:0]                   rd_addr_single;
    reg [31:0]                  reg_wdata_single;

    // MAC Unit Signals (Dedicated 96-bit Accumulator)
    wire [31:0] mac_op1, mac_op2; 
    // The new term that is actually added to the accumulator: zeroed out if not MAC.
    wire [95:0] mac_add_term_96; 
    wire [95:0] mac_sum_96; // Combinatorial Accumulation Result (96-bit)
    reg [95:0]  r_mac_accum_next_96; // Accumulator next state (used for CLR/LOAD)

    // Data Memory Signals
    reg [ADDR_BITS-1:0] dmem_addr;  
    reg [31:0]          dmem_rdata;          
    reg [31:0]          dmem_wdata; 
    reg                 dmem_we;    
    reg                 dmem_re;    

    // Control/Status Register
    /* verilator lint_off UNUSEDSIGNAL */
    reg start_flag; 
    reg done_flag;  
    /* verilator lint_on UNUSEDSIGNAL */
    
    // FSM States
    parameter [1:0] 
        STATE_IDLE      = 2'b00,
        STATE_FETCH     = 2'b01,
        STATE_EXECUTE   = 2'b10;
    reg [1:0] state_reg, state_next; 
    
    //
    // Instruction Memory (iMEM) BSRAM 
    //
    reg [31:0] iMEM [0:255] /* syn_ramstyle=block_ram */; 
    
    // Hardcoded iMEM Initialization
// --- Generated from program.hex ---
integer i;
initial begin
    iMEM[0] = 32'h41000000;
    iMEM[1] = 32'h42000000;
    iMEM[2] = 32'h43000002;
    iMEM[3] = 32'h90000000;
    iMEM[4] = 32'hA1230000;
    iMEM[5] = 32'h64000000;
    iMEM[6] = 32'h75000000;
    iMEM[7] = 32'h86000000;
    iMEM[8] = 32'h41000002;
    iMEM[9] = 32'h42000002;
    iMEM[10] = 32'h10120000;
    iMEM[11] = 32'h48000003;
    iMEM[12] = 32'h49000003;
    iMEM[13] = 32'hBA890000;
    iMEM[14] = 32'h50000005;

    // Initialize the rest of the memory to NOP (0x00000000)
    for (i = 15; i < 256; i++) begin 
        iMEM[i] = 32'h00000000;
    end        
    $display("iMEM loaded.");
    start_flag = 1'b1;
end
// ----------------------------------

    
    //
    // Data Memory (dMEM) BSRAM 
    //
    reg [31:0] dMEM [0:255] /* syn_ramstyle=block_ram */; 
    
    // Data Memory Write 
    always @(posedge  i_clk or negedge  i_rst_n) begin 
        if (! i_rst_n) begin
            // Reset logic for memory data if needed
        end else if (dmem_we) begin
            // Synchronous Write (for STORE instruction)
            dMEM[dmem_addr] <= dmem_wdata;
        end
    end
    
    // Data Memory Read
    always @(posedge  i_clk or negedge  i_rst_n) begin 
        if (! i_rst_n) begin
            dmem_rdata <= 32'h0; // Initialize read data
        end else if (dmem_re) begin
            // Synchronous Read (for LOAD instruction result)
            dmem_rdata <= dMEM[dmem_addr]; 
        end
    end
    
    //
    // Register File
    //
    reg [31:0] gpr [0:REG_COUNT-1]; 
    
    // Register Read (Combinational)
    assign reg_rdata1 = gpr[rs1_addr];
    assign reg_rdata2 = gpr[rs2_addr];

    // Read signals for LOAD_ACCR (Rs_H, Rs_M, Rs_L)
    wire [31:0] reg_rdata_h = gpr[rd_addr];  // Rd field holds Rs_H
    wire [31:0] reg_rdata_m = gpr[rs1_addr]; // Rs1 field holds Rs_M
    wire [31:0] reg_rdata_l = gpr[rs2_addr]; // Rs2 field holds Rs_L
    
    // Register Write - Handles both single (LOAD, READ_ACC, MOVE, MAC) and double (MUL) writes
    always @(posedge  i_clk or negedge  i_rst_n) begin 
        if (! i_rst_n) begin
            gpr[0] <= 32'h0000_0000;
        end else begin
            // 1. Single Write (MAC, LOAD, READ_ACC, MOVE)
            if (reg_we_single) begin
                gpr[rd_addr_single] <= reg_wdata_single;
            end
            
            // 2. Double Write for MUL: Write High Word (Rd)
            if (reg_we_mul_high) begin
                gpr[rd_addr] <= reg_wdata_high;
            end
            
            // 3. Double Write for MUL: Write Low Word (Rd+1). R15 wraps to R0.
            if (reg_we_mul_low) begin
                gpr[rd_addr_low] <= reg_wdata_low;
            end
        end
    end
    
    //
    // Core MAC/DSP Unit - 96-bit Multiply-Accumulate
    //
    
    // Operands for the Multiplier are R1 and R2
    assign mac_op1 = reg_rdata1; // Use Rs1 (from instruction)
    assign mac_op2 = reg_rdata2; // Use Rs2 (from instruction)

    // Combinatorial 32x32 Signed Multiplier (shared hardware resource)
    wire [63:0] comb_product_64 = $signed(mac_op1) * $signed(mac_op2);

    // MAC accum Control Signals
    wire mac_accum_write = (state_reg == STATE_EXECUTE) && (
        opcode == 4'b0001 || // MAC (Accumulate)
        opcode == 4'b1001 || // CLR_ACC (Clear)
        opcode == 4'b1010    // LOAD_ACCR (Load)
    );

    // Accumulator Register (96-bit)
    reg [63:0] r_mac_product_64; // Dedicated register for MAC product result (feeds accumulator)
    reg [63:0] r_mul_product_64; // Dedicated register for MUL product result (feeds GPRs)
    reg [95:0] r_mac_accum_96;   // Accumulator register (96-bit)
    
    // Sequential block for Products and Accumulator
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            r_mac_accum_96 <= 96'h0; 
            r_mac_product_64 <= 64'h0;
            r_mul_product_64 <= 64'h0;
        end else begin
            // Accumulator Update: Only write if MAC, CLR, or LOAD instruction is active
            if (mac_accum_write) begin
                r_mac_accum_96 <= r_mac_accum_next_96;
            end
            
            // MAC Product Register Update (Opcode 1)
            // Store the product if the current instruction is MAC
            if((state_reg == STATE_EXECUTE) && (opcode == 4'b0001)) begin
                r_mac_product_64 <= comb_product_64;
            end

            // MUL Product Register Update (Opcode B)
            // Store the product if the current instruction is MUL
            if((state_reg == STATE_EXECUTE) && (opcode == 4'b1011)) begin
                r_mul_product_64 <= comb_product_64;
            end
        end
    end
    
    
    // Combinatorial Accumulation Logic
    // 1. Sign-extend the registered MAC product (from the previous cycle)
    wire [95:0] mac_product_96 = {{32{r_mac_product_64[63]}}, r_mac_product_64};
    
    // 2. Control the input to the Adder: only add the product if the current instruction is MAC
    // This uses the MAC opcode to control the addition of the registered product.
    wire is_mac_op = (state_reg == STATE_EXECUTE) && (opcode == 4'b0001);
    assign mac_add_term_96 = is_mac_op ? mac_product_96 : 96'h0;

    // 3. Perform the controlled accumulation
    assign mac_sum_96 = r_mac_accum_96 + mac_add_term_96; 

    // Accumulator Next State Logic (Combinatorial)
    always @* begin
        r_mac_accum_next_96 = r_mac_accum_96; // Default: hold value

        if (state_reg == STATE_EXECUTE) begin
            case (opcode)
                4'b0001: // MAC: Use the controlled sum
                    r_mac_accum_next_96 = mac_sum_96; 
                4'b1001: // CLR_ACC
                    r_mac_accum_next_96 = 96'h0;
                4'b1010: // LOAD_ACCR
                    r_mac_accum_next_96 = {reg_rdata_h, reg_rdata_m, reg_rdata_l};
                default:
                    r_mac_accum_next_96 = r_mac_accum_96;
            endcase
        end
    end

    //
    // Control Unit (FSM, PC, Decode, Execute) 
    //
    
    // FSM State Logic (Sequential Block)
    always @(posedge  i_clk or negedge  i_rst_n) begin 
        if (! i_rst_n) begin
            state_reg <= STATE_IDLE;
            pc_reg    <= 32'h0000_0000;
            instruction <= 32'h00000000; 
            done_flag <= 1'b0;
        end else begin
            state_reg <= state_next;
            pc_reg    <= pc_next;
            if (state_reg == STATE_FETCH) begin
                instruction <= iMEM[pc_reg[ADDR_BITS-1:0]];
            end 
            done_flag <= (state_reg == STATE_EXECUTE) && (state_next == STATE_IDLE);
        end
    end
    
    // Next State Logic (Combinational Block)
    always @* begin 
        state_next = state_reg;
        pc_next    = pc_reg;    
        dmem_we    = 1'b0;
        dmem_re    = 1'b0;
        dmem_addr  = instruction[ADDR_BITS-1:0]; 
        
        // Reset register write paths
        reg_we_single = 1'b0;
        rd_addr_single = 4'b0;
        reg_wdata_single = 32'h0;
        reg_we_mul_high = 1'b0;
        reg_we_mul_low = 1'b0;
        rd_addr_low = 4'b0;
        reg_wdata_high = 32'h0;
        reg_wdata_low = 32'h0;
        
        // Instruction Decode 
        opcode   = instruction[31:28];
        rd_addr  = instruction[27:24];
        rs1_addr = instruction[23:20];
        rs2_addr = instruction[19:16]; 
        
        case (state_reg)
            STATE_IDLE: begin
                if (start_flag) begin
                    state_next = STATE_FETCH;
                    pc_next    = 32'h0000_0000; 
                end
            end
            
            STATE_FETCH: begin
                pc_next    = pc_reg + 1; 
                state_next = STATE_EXECUTE;
            end
            
            STATE_EXECUTE: begin
                
                case (opcode)
                    // MAC Rd, Rs1, Rs2 (Opcode 1)
                    4'b0001: begin 
                        reg_we_single    = 1'b1;
                        rd_addr_single   = rd_addr;
                        reg_wdata_single = mac_sum_96[31:0]; // Write Low Acc word
                    end
                    
                    // LOAD Rd, Addr (Opcode 2)
                    4'b0010: begin 
                        dmem_re        = 1'b1;
                        reg_we_single  = 1'b1;
                        rd_addr_single = rd_addr;
                        reg_wdata_single = dmem_rdata; 
                    end
                    
                    // STORE Rs, Addr (Opcode 3)
                    4'b0011: begin 
                        dmem_we   = 1'b1;
                        dmem_wdata = reg_rdata1; 
                    end
                    
                    // MOVE Rd, Imm (Opcode 4)
                    4'b0100: begin 
                        reg_we_single    = 1'b1; 
                        rd_addr_single   = rd_addr;
                        reg_wdata_single = {{12{instruction[19]}}, instruction[19:0]}; 
                    end
                    
                    // JUMP Addr (Opcode 5)
                    4'b0101: begin 
                        pc_next = {24'h000000, instruction[7:0]}; 
                    end

                    // READ_ACCH Rd (Opcode 6)
                    4'b0110: begin
                        reg_we_single    = 1'b1;
                        rd_addr_single   = rd_addr;
                        reg_wdata_single = r_mac_accum_96[95:64];
                    end
                    
                    // READ_ACCM Rd (Opcode 7)
                    4'b0111: begin
                        reg_we_single    = 1'b1;
                        rd_addr_single   = rd_addr;
                        reg_wdata_single = r_mac_accum_96[63:32];
                    end
                    
                    // READ_ACCL Rd (Opcode 8)
                    4'b1000: begin
                        reg_we_single    = 1'b1;
                        rd_addr_single   = rd_addr;
                        reg_wdata_single = r_mac_accum_96[31:0];
                    end

                    // CLR_ACC (Opcode 9)
                    4'b1001: begin
                        // Accumulator update is handled in the MAC sequential block
                    end

                    // LOAD_ACCR (Opcode A / 10)
                    4'b1010: begin
                        // Accumulator update is handled in the MAC sequential block
                    end
                    
                    // MUL Rd, Rs1, Rs2 (Opcode B / 11)
                    4'b1011: begin
                        // Write 1: High Word to Rd
                        reg_we_mul_high = 1'b1;
                        reg_wdata_high  = r_mul_product_64[63:32]; // Uses dedicated MUL product register
                        
                        // Write 2: Low Word to Rd+1 (R15 wraps to R0)
                        reg_we_mul_low  = 1'b1;
                        rd_addr_low     = rd_addr + 1; 
                        reg_wdata_low   = r_mul_product_64[31:0]; // Uses dedicated MUL product register
                    end
                    
                    // NOP (Opcode 0)
                    4'b0000: begin
                        // No control signals
                    end
                    
                    default: begin
                        // HALT or ILLEGAL instruction handling: treat as NOP
                    end
                endcase
                
                // State Transition Logic 
                if (!start_flag) begin
                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_FETCH; 
                end
                
            end
            
            default: begin
                state_next = STATE_IDLE;
            end
        endcase
    end

endmodule