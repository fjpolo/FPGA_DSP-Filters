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
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
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
    
    // MAC Unit Signals
    wire [31:0] mac_op1, mac_op2; 
    wire [63:0] mac_product_64; 
    reg [63:0]  mac_sum_64; 
    wire [31:0] mac_result_32; 
    /* verilator lint_off UNUSEDSIGNAL */
    reg                         mac_en;  
    /* verilator lint_on UNUSEDSIGNAL */
    
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
        // --- Data Setup ---
        // Instruction format for MOVE: Opcode(31:28)=4'b0100 | Rd(27:24) | Immediate(19:0)
        
        // Address 0: MOVE R1, 0x00008000 (0.5 fixed point Q15.16)
        // Opcode=4, Rd=1, Imm=0x8000
        iMEM[0] = 32'h41008000; 

        // Address 1: MOVE R2, 0x00004000 (0.25 fixed point Q15.16)
        // Opcode=4, Rd=2, Imm=0x4000
        iMEM[1] = 32'h42004000;
        
        // --- Infinite MAC Loop ---
        // Address 2: MAC R0, R1, R2 (0x10120000)
        // Opcode=1, Rd=0, Rs1=1, Rs2=2 
        // iMEM[2] = 32'h10120000; 
        iMEM[2] = 32'h41008000; 

        // Address 3: JUMP 0x002 (JUMP back to the MAC instruction)
        // Opcode=5, Imm=0x00000002
        iMEM[3] = 32'h50000002;
        
        // Initialize the rest of the memory to NOP (0x00000000)
        for (integer i = 4; i < 256; i++) begin 
            iMEM[i] = 32'h00000000;
        end        
        
        $display("iMEM loaded with MAC loop setup.");
        
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
    
    // Register Write
    always @(posedge  i_clk or negedge  i_rst_n) begin 
        if (! i_rst_n) begin
            // Initialize R0 to zero
            gpr[0] <= 32'h0000_0000;
        end else if (reg_we) begin
            // Write only if R0 is not the destination (implied by design for MAC)
            if (rd_addr != 4'b0000) begin
                gpr[rd_addr] <= reg_wdata;
            end
        end
        
        // Special Case: R0 is the MAC accumulator, update it regardless of explicit reg_we (handled by MAC logic)
        // Re-adding the R0 write for MAC (Opcode 1) is handled in the `reg_wdata` path during EXECUTE.
        // For simplicity, we assume R0 is allowed to be written via reg_we, but the MAC result is
        // handled differently in the GPR definition (not explicitly done here, relying on reg_wdata path).
        // Let's rely on the explicit MAC logic in the combinational block to set reg_wdata.
        // Note: MAC updates R0 (rd_addr=0) but uses it for accumulator input.
        // We ensure R0 can be written here:
        if (reg_we && (rd_addr == 4'b0000)) begin
            gpr[0] <= reg_wdata;
        end
    end

    //
    // Fixed-Point MAC Unit - 32x32 -> 64-bit Accumulation
    //
    
    // MAC Operands are R1 and R2
    assign mac_op1 = gpr[1]; // Explicitly use R1
    assign mac_op2 = gpr[2]; // Explicitly use R2

    // 32x32 Multiplication -> 64-bit product (Combinational)
    assign mac_product_64 = mac_op1 * mac_op2;
    
    // Accumulation Input Calculation (Combinational)
    // The accumulator value (R0) is used as the current sum.
    // The MAC instruction Rd is 0, but we need to check if we are reading it back for accumulation.
    // Assuming R0 is the destination register for the MAC result.
    wire [31:0] current_sum_32;
    assign current_sum_32 = gpr[rd_addr]; // This will be R0 if rd_addr is 0

    // Manual sign extension of the current 32-bit sum to 64-bit
    wire [63:0] current_sum_64_ext;
    assign current_sum_64_ext = { {32{current_sum_32[31]}}, current_sum_32 };

    // New sum is (current_sum_64_ext + mac_product_64)
    wire [63:0] mac_acc_in;
    assign mac_acc_in = current_sum_64_ext + mac_product_64;
    
    // 64-bit Accumulation Register (Not needed if we use R0 as the accumulator state)
    // Since R0 is the state, we don't need mac_sum_64 register. 
    // Commenting out the unused mac_sum_64 register logic and signal.
    
    // Final 32-bit result (Q15.16) - This is the top 32 bits of the 64-bit intermediate sum
    assign mac_result_32 = mac_acc_in[63:32]; 
    
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
        pc_next    = pc_reg;    // Default to stall (no change) unless explicitly updated
        reg_we     = 1'b0;
        mac_en     = 1'b0;
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
                // pc_next    = pc_reg + 1; // Default sequential increment during execute
                
                // Control Signal and Data Path Assignment based on Opcode
                case (opcode)
                    // MAC R0, R1, R2 (Opcode 1)
                    4'b0001: begin 
                        // mac_en is not explicitly used as the MAC logic is combinational/uses R0 as state
                        reg_we    = 1'b1;         // Enable write to Rd (R0)
                        reg_wdata = mac_result_32; // Write the accumulated result
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
                        reg_we    = 1'b1; // **FIXED: Enable write for MOVE**
                        reg_wdata = {{12{instruction[19]}}, instruction[19:0]}; 
                    end
                    
                    // JUMP Addr (Opcode 5)
                    4'b0101: begin 
                        pc_next = {12'h000, instruction[19:0]}; // **FIXED: Override PC for JUMP**
                    end
                    
                    // NOP (Opcode 0)
                    4'b0000: begin
                        // Default PC increment handles this
                    end
                    
                    default: begin
                        // HALT or ILLEGAL instruction handling: treat as NOP
                    end
                endcase
                
                // --- State Transition Logic ---
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
