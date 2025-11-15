// =============================================================================
// File        : RVDSPCoProc.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : <Brief description of the module or file>
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
    input  wire         i_clk,    
    input  wire         i_rst_n,  // Active low reset
    
    // Wishbone Slave Interface (WB B4) - Keeping ports but ignoring internal logic
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [31:0]  wbs_adr_i,  // Address input
    input  wire [31:0]  wbs_dat_i,  // Data input
    input  wire [3:0]   wbs_sel_i,  // Byte select
    input  wire         wbs_we_i,   // Write enable
    input  wire         wbs_cyc_i,  // Cycle valid
    input  wire         wbs_stb_i,  // Strobe
    output wire [31:0]  wbs_dat_o,  // Data output
    output wire         wbs_ack_o,  // Acknowledge
    output wire         wbs_err_o   // Error
    /* verilator lint_on UNUSEDSIGNAL */
);

    // Configuration Constants 
    localparam ADDR_BITS     = 8;             // 256 word memory size (iMEM/dMEM)
    localparam REG_ADDR_BITS = 4;             // 16 registers
    localparam REG_COUNT     = 1 << REG_ADDR_BITS;
    
    // Core Pipeline Signals - Single-Cycle FSM
    reg [31:0]                  pc_reg;       
    reg [31:0]                  pc_next;      // CHANGED: wire -> reg (assigned in always @*)
    reg [31:0]                  instruction;  
    reg [3:0]                   opcode;       // CHANGED: wire -> reg (assigned in always @*)
    reg [REG_ADDR_BITS-1:0]     rd_addr, rs1_addr, rs2_addr; // CHANGED: wire -> reg (assigned in always @*)
    wire [31:0]                 reg_rdata1, reg_rdata2;     
    reg [31:0]                  reg_wdata;                  // CHANGED: wire -> reg (assigned in always @*)
    reg                         reg_we;                     // CHANGED: wire -> reg (assigned in always @*)
    
    // MAC Unit Signals
    wire [31:0] mac_op1, mac_op2; 
    wire [63:0] mac_product_64; 
    reg [63:0]  mac_sum_64; 
    wire [31:0] mac_result_32; 
    /* verilator lint_off UNUSEDSIGNAL */
    reg                         mac_en;  // CHANGED: wire -> reg (assigned in always @*)
    /* verilator lint_on UNUSEDSIGNAL */
    
    // Data Memory Signals
    reg [ADDR_BITS-1:0] dmem_addr;  // CHANGED: wire -> reg (assigned in always @*)
    reg [31:0]          dmem_rdata;          
    reg [31:0]          dmem_wdata; // CHANGED: wire -> reg (assigned in always @*)
    reg                 dmem_we;    // CHANGED: wire -> reg (assigned in always @*)
    reg                 dmem_re;    // CHANGED: wire -> reg (assigned in always @*)

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
    // Wishbone Interface Logic - Placeholder to satisfy Verilator UNDRIVEN
    //
    assign wbs_dat_o = 32'h0;
    assign wbs_ack_o = 1'b0;
    assign wbs_err_o = 1'b0;
    
    //
    // Instruction Memory (iMEM) BSRAM 
    //
    reg [31:0] iMEM [0:255] /* syn_ramstyle=block_ram */; 
    
    // Hardcoded iMEM Initialization
    initial begin
        // Program: Infinite MAC loop (R0 <- R0 + R1 * R2)
        // R1 = 0.5 (0x00008000), R2 = 0.25 (0x00004000) - Must be loaded via WB or MOVE.
        
        // Address 0: MAC R0, R1, R2 (0x10120000)
        iMEM[0] = 32'h10120000; 

        // Address 1: JUMP 0x000 (0x50000000)
        iMEM[1] = 32'h50000000;
        
        // Initialize the rest of the memory to NOP (0x00000000)
        for (integer i = 2; i < 256; i++) begin 
            iMEM[i] = 32'h00000000;
        end
        
        $display("iMEM loaded with infinite MAC loop.");
        
        // Initialize start_flag high for immediate simulation run (Fixes UNDRIVEN)
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
            gpr[rd_addr] <= reg_wdata;
        end
    end

    //
    // Fixed-Point MAC Unit - 32x32 -> 64-bit Accumulation
    //
    
    assign mac_op1 = reg_rdata1;
    assign mac_op2 = reg_rdata2;

    // 32x32 Multiplication -> 64-bit product (Combinational)
    assign mac_product_64 = mac_op1 * mac_op2;
    
    // Accumulation Input Calculation (Combinational)
    // Manual sign extension
    wire [63:0] mac_acc_in;
    assign mac_acc_in = { {32{gpr[rd_addr][31]}}, gpr[rd_addr] } + mac_product_64;
    
    // 64-bit Accumulation Register 
    always @(posedge  i_clk or negedge  i_rst_n) begin
        if (! i_rst_n) begin
            mac_sum_64 <= 64'h0;
        end else if (mac_en) begin
            // Register the accumulation result
            mac_sum_64 <= mac_acc_in; 
        end
    end
    
    // Final 32-bit result (Q15.16)
    assign mac_result_32 = mac_sum_64[63:32]; 
    
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
        pc_next    = pc_reg + 1; // Default next PC
        reg_we     = 1'b0;
        mac_en     = 1'b0;
        dmem_we    = 1'b0;
        dmem_re    = 1'b0;
        dmem_addr  = instruction[ADDR_BITS-1:0];    
        reg_wdata  = 32'h0;
        
        // Instruction Decode (Combinational)
        opcode   = instruction[31:28];
        rd_addr  = instruction[27:24];
        rs1_addr = instruction[23:20];
        rs2_addr = instruction[19:16]; // Rs2 is in bits [19:16] for MAC
        
        case (state_reg)
            STATE_IDLE: begin
                if (start_flag) begin
                    state_next = STATE_FETCH;
                    pc_next    = 32'h0000_0000; // Start at address 0
                end
            end
            
            STATE_FETCH: begin
                // Instruction is already registered in 'instruction'
                state_next = STATE_EXECUTE;
            end
            
            STATE_EXECUTE: begin
                case (opcode)
                    // MAC R0, R1, R2
                    4'b0001: begin 
                        mac_en    = 1'b1;
                        reg_we    = 1'b1;
                        reg_wdata = mac_result_32; 
                    end
                    
                    // LOAD Rd, Addr
                    4'b0010: begin 
                        dmem_re   = 1'b1;
                        reg_we    = 1'b1;
                        reg_wdata = dmem_rdata; 
                    end
                    
                    // STORE Rs, Addr
                    4'b0011: begin 
                        dmem_we   = 1'b1;
                        dmem_wdata = reg_rdata1; 
                    end
                    
                    // MOVE Rd, Imm
                    4'b0100: begin 
                        reg_we    = 1'b1;
                        reg_wdata = {{12{instruction[19]}}, instruction[19:0]}; 
                    end
                    
                    // JUMP Addr
                    4'b0101: begin 
                        pc_next = {12'h000, instruction[19:0]}; 
                    end
                    
                    // NOP
                    4'b0000: begin
                        // Default PC increment handles this
                    end
                    
                    default: begin
                        // HALT or ILLEGAL instruction handling: treat as NOP
                    end
                endcase
                
                // State Transition Logic
                if (!start_flag) begin
                    state_next = STATE_IDLE;
                end else if (opcode != 4'b0101) begin // Not JUMP
                    state_next = STATE_FETCH;
                end
                
            end
            
            default: begin
                state_next = STATE_IDLE;
            end
        endcase
    end

endmodule
