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
    reg [31:0]                  reg_wdata;                  
    reg                         reg_we;                     
    
    // MAC Unit Signals (Dedicated 96-bit Accumulator)
    wire [31:0] mac_op1, mac_op2; 
    wire [95:0] mac_mul_96; // Combinatorial Accumulation Result (96-bit, used for next state if MAC)
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
    initial begin
        // Data Setup 
        // Instruction format for MOVE: Opcode(31:28)=4'b0100 | Rd(27:24) | Immediate(19:0)
        
        // Address 0: MOVE R1, 0x00000005 (Integer 5)
        // Opcode=4, Rd=1, Imm=0x0005
        iMEM[0] = 32'h41000005; 

        // Address 1: MOVE R2, 0x0000000A (Integer 10)
        // Opcode=4, Rd=2, Imm=0x000A
        iMEM[1] = 32'h4200000A;
        
        // Infinite MAC Loop 
        // Address 2: MAC R0, R1, R2 (R0 = Low 32 bits of Acc)
        // Opcode=1, Rd=0, Rs1=1, Rs2=2 
        iMEM[2] = 32'h10120000; 

        // Address 3: JUMP 0x002 (JUMP back to the MAC instruction)
        // Opcode=5, Imm=0x00000002
        iMEM[3] = 32'h50000002;
        
        // Initialize the rest of the memory to NOP (0x00000000)
        for (integer i = 4; i < 256; i++) begin 
            iMEM[i] = 32'h00000000;
        end        
                
        // Initialize start_flag high for immediate simulation run
        start_flag = 1'b1;
    end
    
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
    
    // Register Write - Registered write from the execution result (reg_wdata)
    always @(posedge  i_clk or negedge  i_rst_n) begin 
        if (! i_rst_n) begin
            // Initialize R0 to zero
            gpr[0] <= 32'h0000_0000;
        end else if (reg_we) begin
            // Write to any register specified by rd_addr, including R0 (Opcode 1 sets rd_addr=0)
            gpr[rd_addr] <= reg_wdata;
        end
    end
    
    //
    // Core MAC/DSP Unit - 96-bit Multiply-Accumulate
    //

    // MAC accum Control Signals
    wire mac_accum_write = (state_reg == STATE_EXECUTE) && (
        opcode == 4'b0001 || // MAC (Accumulate)
        opcode == 4'b1001 || // CLR_ACC (Clear)
        opcode == 4'b1010    // LOAD_ACCR (Load)
    );

    // Accumulator Register (96-bit)
    reg [63:0] r_mac_mul_64;   // Product register (64-bit)
    reg [95:0] r_mac_accum_96; // Accumulator register (96-bit)
    
    // Sequential block for Product and Accumulator
    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            r_mac_accum_96 <= 96'h0; // Initialize 96-bit accum
            r_mac_mul_64 <= 64'h0;   // Initialize 64-bit product
        end else begin
            // Accumulator Update: Only write if MAC, CLR, or LOAD instruction is active
            if (mac_accum_write) begin
                r_mac_accum_96 <= r_mac_accum_next_96;
            end
            
            // Product Update: Only calculate and store product if it's a MAC instruction
            if((state_reg == STATE_EXECUTE) && (opcode == 4'b0001)) begin
                r_mac_mul_64 <= $signed(mac_op1) * $signed(mac_op2); // Store 32x32 signed product
            end
        end
    end
    
    // Operands for the Multiplier are R1 and R2
    assign mac_op1 = reg_rdata1; // Use Rs1 (from instruction)
    assign mac_op2 = reg_rdata2; // Use Rs2 (from instruction)
    
    // Combinatorial Accumulation
    // The 64-bit registered product (r_mac_mul_64) is sign-extended to 96 bits for addition.
    wire [95:0] mac_product_96 = {{32{r_mac_mul_64[63]}}, r_mac_mul_64};
    assign mac_mul_96 = r_mac_accum_96 + mac_product_96; // Accumulation result

    // Accumulator Next State Logic (Combinatorial)
    always @* begin
        r_mac_accum_next_96 = r_mac_accum_96; // Default: hold value

        if (state_reg == STATE_EXECUTE) begin
            case (opcode)
                4'b0001: // MAC
                    r_mac_accum_next_96 = mac_mul_96;
                4'b1001: // CLR_ACC
                    r_mac_accum_next_96 = 96'h0;
                4'b1010: // LOAD_ACCR
                    // Concatenate the three GPRs (Rs_H, Rs_M, Rs_L) into the 96-bit accumulator
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
            // Register the instruction here, after fetching
            if (state_reg == STATE_FETCH) begin
                instruction <= iMEM[pc_reg[ADDR_BITS-1:0]];
            end 
            // Only flag done when transitioning from EXECUTE to IDLE
            done_flag <= (state_reg == STATE_EXECUTE) && (state_next == STATE_IDLE);
        end
    end
    
    // Next State Logic (Combinational Block)
    always @* begin 
        state_next = state_reg;
        pc_next    = pc_reg;    // Default to stall (no change) unless explicitly updated (e.g., FETCH or JUMP)
        reg_we     = 1'b0;
        dmem_we    = 1'b0;
        dmem_re    = 1'b0;
        dmem_addr  = instruction[ADDR_BITS-1:0]; 
        reg_wdata  = 32'h0;
        
        // Instruction Decode (Combinational) - Always decode based on registered instruction
        opcode   = instruction[31:28];
        rd_addr  = instruction[27:24];
        rs1_addr = instruction[23:20];
        rs2_addr = instruction[19:16]; 
        
        case (state_reg)
            STATE_IDLE: begin
                if (start_flag) begin
                    state_next = STATE_FETCH;
                    pc_next    = 32'h0000_0000; // Start at address 0
                end
            end
            
            STATE_FETCH: begin
                pc_next    = pc_reg + 1; // Explicitly set increment for fetch
                state_next = STATE_EXECUTE;
            end
            
            STATE_EXECUTE: begin
                // PC advancement is now exclusively handled in STATE_FETCH and JUMP.
                
                // Control Signal and Data Path Assignment based on Opcode
                case (opcode)
                    // MAC R0, R1, R2 (Opcode 1) -> R0 = Low 32 bits of Acc
                    4'b0001: begin 
                        // Write the low 32 bits back to R0 for compatibility.
                        reg_we    = 1'b1;               // Enable write to Rd (R0)
                        reg_wdata = mac_mul_96[31:0];   // Write the Low 32 bits of the Accumulator
                    end
                    
                    // LOAD Rd, Addr (Opcode 2)
                    4'b0010: begin 
                        dmem_re   = 1'b1;
                        reg_we    = 1'b1;
                        reg_wdata = dmem_rdata; 
                    end
                    
                    // STORE Rs, Addr (Opcode 3)
                    4'b0011: begin 
                        dmem_we   = 1'b1;
                        dmem_wdata = reg_rdata1; 
                    end
                    
                    // MOVE Rd, Imm (Opcode 4)
                    4'b0100: begin 
                        reg_we    = 1'b1; 
                        reg_wdata = {{12{instruction[19]}}, instruction[19:0]}; 
                    end
                    
                    // JUMP Addr (Opcode 5)
                    4'b0101: begin 
                        pc_next = {12'h000, instruction[19:0]}; // Override PC for JUMP
                    end

                    // READ_ACCH Rd (Opcode 6) -> Read High 32 bits (95:64)
                    4'b0110: begin
                        reg_we    = 1'b1;
                        reg_wdata = r_mac_accum_96[95:64];
                    end
                    
                    // READ_ACCM Rd (Opcode 7) -> Read Middle 32 bits (63:32)
                    4'b0111: begin
                        reg_we    = 1'b1;
                        reg_wdata = r_mac_accum_96[63:32];
                    end
                    
                    // READ_ACCL Rd (Opcode 8) -> Read Low 32 bits (31:0)
                    4'b1000: begin
                        reg_we    = 1'b1;
                        reg_wdata = r_mac_accum_96[31:0];
                    end

                    // CLR_ACC (Opcode 9)
                    4'b1001: begin
                        // Accumulator update is handled in the MAC sequential block
                    end

                    // LOAD_ACCR (Opcode A / 10)
                    4'b1010: begin
                        // Accumulator update is handled in the MAC sequential block
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
                    // ALWAYS go to FETCH after execution 
                    state_next = STATE_FETCH; 
                end
                
            end
            
            default: begin
                state_next = STATE_IDLE;
            end
        endcase
    end

endmodule