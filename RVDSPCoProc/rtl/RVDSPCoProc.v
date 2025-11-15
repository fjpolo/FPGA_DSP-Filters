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
    input  logic        clk,
    input  logic        rst_n,      // Active low reset
    
    // Wishbone Slave Interface (WB B4) - Keeping ports but ignoring internal logic
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [31:0] wbs_adr_i,  // Address input
    input  logic [31:0] wbs_dat_i,  // Data input
    input  logic [3:0]  wbs_sel_i,  // Byte select
    input  logic        wbs_we_i,   // Write enable
    input  logic        wbs_cyc_i,  // Cycle valid
    input  logic        wbs_stb_i,  // Strobe
    output logic [31:0] wbs_dat_o,  // Data output
    output logic        wbs_ack_o,  // Acknowledge
    output logic        wbs_err_o   // Error
    /* verilator lint_on UNUSEDSIGNAL */
);

    // Configuration Constants 
    localparam ADDR_BITS     = 8;             // 256 word memory size (iMEM/dMEM)
    localparam REG_ADDR_BITS = 4;             // 16 registers
    localparam REG_COUNT     = 1 << REG_ADDR_BITS;
    
    // Memory Map Constants - Word Addresses (Removed unused ones)
    // localparam IMEM_BASE     = 32'h0000_0000;
    // localparam DMEM_BASE     = 32'h0000_0100;
    // localparam RF_BASE       = 32'h0000_0200;
    // localparam CTRL_BASE     = 32'h0000_0210;
    // localparam CTRL_REG_ADDR = 32'h0000_0210;
    // localparam STATUS_REG_ADDR = 32'h0000_0211;
    // localparam PC_LATCH_ADDR = 32'h0000_0212;
    
    // Core Pipeline Signals - Single-Cycle FSM
    logic [31:0]                pc_reg, pc_next;
    logic [31:0]                instruction;
    logic [3:0]                 opcode;
    logic [REG_ADDR_BITS-1:0]   rd_addr, rs1_addr, rs2_addr;
    logic [31:0]                reg_rdata1, reg_rdata2;
    logic [31:0]                reg_wdata;
    logic                       reg_we;  
    
    // MAC Unit Signals
    logic [31:0] mac_op1, mac_op2;
    /* verilator lint_off UNUSEDSIGNAL */ // Suppress for mac_sum_64[31:0]
    logic [63:0] mac_product_64, mac_sum_64;
    /* verilator lint_on UNUSEDSIGNAL */
    logic [31:0] mac_result_32;
    /* verilator lint_off UNUSEDSIGNAL */
    logic        mac_en;  
    /* verilator lint_on UNUSEDSIGNAL */
    
    // Data Memory Signals
    logic [ADDR_BITS-1:0] dmem_addr;
    logic [31:0] dmem_rdata, dmem_wdata;
    logic        dmem_we;  
    logic        dmem_re;  

    // Control/Status Register
    /* verilator lint_off UNUSEDSIGNAL */
    logic start_flag, done_flag;
    /* verilator lint_on UNUSEDSIGNAL */
    
    // FSM States
    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_FETCH,
        STATE_EXECUTE
    } fsm_state_t;
    fsm_state_t state_reg, state_next;
    
    //
    // Wishbone Interface Logic - Placeholder to satisfy Verilator UNDRIVEN
    //
    assign wbs_dat_o = 32'h0;
    assign wbs_ack_o = 1'b0;
    assign wbs_err_o = 1'b0;
    
    //
    // Instruction Memory (iMEM) BSRAM 
    //
    logic [31:0] iMEM [0:255] /* syn_ramstyle=block_ram */;
    
    // Synchronous Read: Instruction Fetch is registered/combinational path
    // For simplicity, we model a single-cycle combinational read here.
    assign instruction = iMEM[pc_reg[ADDR_BITS-1:0]];
    
    // Hardcoded iMEM Initialization
    initial begin
        // Program: Infinite MAC loop (R0 <- R0 + R1 * R2)
        // R1 = 0.5 (0x00008000), R2 = 0.25 (0x00004000) - Must be loaded via WB or MOVE.
        
        // Address 0: MAC R0, R1, R2 (0x10120000)
        iMEM[0] = 32'h10120000; 

        // Address 1: JUMP 0x000 (0x50000000)
        iMEM[1] = 32'h50000000;
        
        // Initialize the rest of the memory to NOP (0x00000000)
        for (int i = 2; i < 256; i++) begin
            iMEM[i] = 32'h00000000;
        end
        
        $display("iMEM loaded with infinite MAC loop.");
        
        // Initialize start_flag high for immediate simulation run (Fixes UNDRIVEN)
        start_flag = 1'b1;
    end
    
    //
    // Data Memory (dMEM) BSRAM 
    //
    logic [31:0] dMEM [0:255] /* syn_ramstyle=block_ram */;
    
    // Data Memory Write (Converted to Asynchronous Reset)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic for memory data if needed
        end else if (dmem_we) begin
            // Synchronous Write (for STORE instruction)
            dMEM[dmem_addr] <= dmem_wdata;
        end
    end
    
    // Data Memory Read (Converted to Asynchronous Reset)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dmem_rdata <= 32'h0; // Initialize read data
        end else if (dmem_re) begin
            // Synchronous Read (for LOAD instruction result)
            dmem_rdata <= dMEM[dmem_addr]; 
        end
    end
    
    //
    // Register File
    //
    logic [31:0] gpr [0:REG_COUNT-1];
    
    // Register Read (Combinational)
    assign reg_rdata1 = gpr[rs1_addr];
    assign reg_rdata2 = gpr[rs2_addr];
    
    // Register Write (Synchronous - Converted to Asynchronous Reset)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize R0 to zero
            gpr[0] <= 32'h0000_0000;
        end else if (reg_we) begin
            // R0 is generally hardwired to zero/ignored in RISC designs, 
            // but for simplicity, we allow writing to it here.
            gpr[rd_addr] <= reg_wdata;
        end
    end

    //
    // Fixed-Point MAC Unit - 32x32 -> 64-bit Accumulation
    //
    
    // The MAC unit is modeled as combinational logic for a single-cycle design.
    // ⚠️ In a high-speed design, this would be heavily pipelined.
    assign mac_op1 = reg_rdata1;
    assign mac_op2 = reg_rdata2;

    // 32x32 Multiplication -> 64-bit product
    assign mac_product_64 = $signed({mac_op1, 1'b0}) * $signed({mac_op2, 1'b0});
    // Note: The extra bit is not strictly necessary for 32x32, 
    // but useful for signed multiplication in Verilog, though $signed() handles it.
    // mac_product_64 = $signed(mac_op1) * $signed(mac_op2); // Simpler form.
    
    // 64-bit Accumulation: Rd holds the running 64-bit total (conceptually)
    // Here, we use R0 to hold the 32-bit result and conceptualize the 64-bit process.
    // To properly support the MAC R0, R1, R2, R0 must hold the previous result.
    // We will simplify and assume R0 holds the previous value:
    // This requires R0 to be the destination for the MAC.
    
    // Accumulation (R_old + P)
    // The previous value (R0) is sign-extended to 64-bits for accumulation.
    // We will use the *actual* 32-bit register value for R_old.
    assign mac_sum_64 = $signed({{32{$signed(gpr[rd_addr])[31]}}, gpr[rd_addr]}) + mac_product_64;
    
    // Final 32-bit result (Q15.16)
    // The result of the accumulation needs to be written back. We take the upper 32 bits 
    // of the 64-bit sum, representing the Q15.16 format.
    assign mac_result_32 = mac_sum_64[63:32]; // Simplistic Q15.16 extraction after MAC
    
    //
    // Control Unit (FSM, PC, Decode, Execute) 
    //
    
    // FSM State Logic (Reset is Active Low -> !rst_n)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= STATE_IDLE;
            pc_reg    <= 32'h0000_0000;
            done_flag <= 1'b0;
        end else begin
            state_reg <= state_next;
            pc_reg    <= pc_next;
            // Only flag done when transitioning from EXECUTE to IDLE
            done_flag <= (state_reg == STATE_EXECUTE) && (state_next == STATE_IDLE);
        end
    end
    
    // Next State Logic (Combinational)
    always_comb begin
        state_next = state_reg;
        pc_next    = pc_reg + 1; // Default next PC
        reg_we     = 1'b0;
        mac_en     = 1'b0;
        dmem_we    = 1'b0;
        dmem_re    = 1'b0;
        dmem_addr  = instruction[19:0][ADDR_BITS-1:0]; // Default dMEM address
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
                // Instruction is ready in `instruction` (combinational read)
                state_next = STATE_EXECUTE;
            end
            
            STATE_EXECUTE: begin
                case (opcode)
                    // MAC R0, R1, R2
                    4'b0001: begin 
                        mac_en    = 1'b1;
                        reg_we    = 1'b1;
                        reg_wdata = mac_result_32; // Result from MAC unit
                    end
                    
                    // LOAD Rd, Addr
                    4'b0010: begin 
                        dmem_re   = 1'b1;
                        reg_we    = 1'b1;
                        // Data from dMEM read is registered, so the write occurs
                        // one cycle later in a full pipeline. Here, we simplify:
                        reg_wdata = dmem_rdata; // Assuming read data is ready
                    end
                    
                    // STORE Rs, Addr
                    4'b0011: begin 
                        dmem_we   = 1'b1;
                        dmem_wdata = reg_rdata1; // Rs is the source register
                    end
                    
                    // MOVE Rd, Imm
                    4'b0100: begin 
                        reg_we    = 1'b1;
                        // Use 20-bit immediate value, sign-extend if needed (not shown)
                        reg_wdata = {{12{instruction[19]}}, instruction[19:0]}; 
                    end
                    
                    // JUMP Addr
                    4'b0101: begin 
                        pc_next = {12'h000, instruction[19:0]}; // New PC is the 20-bit address
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
                // Special case: if start_flag is cleared, return to IDLE
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
