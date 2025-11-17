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

module RVDSPCoProc_top(
    input i_clk,
    input i_rst_n
);

wire    [31:0]  top_imem_data;
wire            top_imem_data_valid;
wire            top_imem_data_ready;
wire            top_imem_read_ce;
wire    [7:0]  top_imem_address;
wire            top_dmem_read_ce;
wire    [7:0]   top_dmem_read_address;
wire    [31:0]  top_dmem_read_data;
wire            top_dmem_read_data_valid;
wire            top_dmem_read_data_ready;
wire            top_dmem_write_ce;
wire    [7:0]   top_dmem_write_address;
wire    [31:0]  top_dmem_write_data;
wire            top_dmem_write_done;
// iMEM
iMEM i_iMEM(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_read_ce(top_imem_read_ce),
    .i_address(top_imem_address),
    .o_data(top_imem_data),
    .o_data_valid(top_imem_data_valid),
    .o_data_ready(top_imem_data_ready)
);

dMEM i_dMEM(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_read_ce(top_dmem_read_ce),
    .i_read_address(top_dmem_read_address),
    .o_read_data(top_dmem_read_data),
    .o_read_data_valid(top_dmem_read_data_valid),
    .o_read_data_ready(top_dmem_read_data_ready),
    .i_write_ce(top_dmem_write_ce),
    .i_write_address(top_dmem_write_address),
    .i_write_data(top_dmem_write_data),
    .o_write_done(top_dmem_write_done)
);

RVDSPCoProc i_RVDSPCoProc(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_imem_data(top_imem_data),
    .i_imem_data_valid(top_imem_data_valid),
    .i_imem_data_ready(top_imem_data_ready),
    .o_imem_read_ce(top_imem_read_ce),
    .o_imem_address(top_imem_address),
    .o_read_ce(top_dmem_read_ce),
    .o_read_address(top_dmem_read_address),
    .i_read_data(top_dmem_read_data),
    .i_read_data_valid(top_dmem_read_data_valid),
    .i_read_data_ready(top_dmem_read_data_ready),
    .o_write_ce(top_dmem_write_ce),
    .o_write_address(top_dmem_write_address),
    .o_write_data(top_dmem_write_data),
    .i_write_done(top_dmem_write_done)
);

endmodule

module dMEM#(
    parameter DEPTH = 256,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input   wire                        i_clk,    // Clock 
    input   wire                        i_rst_n,  // Active low reset
    // READ
    input   wire                        i_read_ce,
    input   wire    [(ADDR_WIDTH-1):0]  i_read_address,
    output  reg     [(DATA_WIDTH-1):0]  o_read_data,
    output  wire                        o_read_data_valid,
    output  wire                        o_read_data_ready,
    // WRITE
    input   wire                        i_write_ce,
    input   wire    [(ADDR_WIDTH-1):0]  i_write_address,
    input   wire    [(DATA_WIDTH-1):0]  i_write_data,
    output  wire                        o_write_done
);
    reg [(DATA_WIDTH-1):0] dMEM [0:DEPTH] /* syn_ramstyle=block_ram */; 
    
    // Data Memory Write 
    always @(posedge  i_clk or negedge  i_rst_n) begin 
        if (! i_rst_n) begin
            // Reset logic for memory data if needed
        end else if (i_write_ce) begin
            // Synchronous Write (for STORE instruction)
            dMEM[i_write_address] <= i_write_data;
        end
    end
    
    // Data Memory Read
    always @(posedge  i_clk or negedge  i_rst_n) begin 
        if (! i_rst_n) begin
            o_read_data <= 32'h0; // Initialize read data
        end else if (i_read_ce) begin
            // Synchronous Read (for LOAD instruction result)
            o_read_data <= dMEM[i_read_address]; 
        end
    end

    // Read Handshake
    reg read_data_valid;
    reg read_data_ready;
    wire read_addres_valid = (i_read_address <= 255);
    always @(posedge i_clk) begin
        if(!i_rst_n) begin
            read_data_valid <= 1'h0;
            read_data_ready <= 1'h0;
        end else begin
            read_data_valid <= 1'b0;
            read_data_ready <= 1'b0;
            if((i_read_ce)&&(read_addres_valid))
                read_data_valid <= 1'b1;
                read_data_ready <= 1'b1;
        end
    end
    assign o_read_data_valid = read_data_valid;
    assign o_read_data_ready = read_data_ready;

    // Write Handshake
    reg write_done;
    wire write_addres_valid = (i_write_address <= 255);
    always @(posedge i_clk) begin
        if(!i_rst_n) begin
            write_done <= 1'h0;
        end else begin
            write_done <= 1'b0;
            if((i_write_ce)&&(write_addres_valid))
                write_done <= 1'b1;
        end
    end
    assign o_write_done = write_done;

endmodule

module iMEM#(
    parameter DEPTH = 256,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input   wire                        i_clk,    // Clock 
    input   wire                        i_rst_n,  // Active low reset
    input   wire                        i_read_ce,
    input   wire    [(ADDR_WIDTH-1):0]  i_address,
    output  reg     [(DATA_WIDTH-1):0]  o_data,
    output  wire                        o_data_valid,
    output  wire                        o_data_ready
);

    //
    // Instruction Memory (iMEM) BSRAM 
    //
    reg [(DATA_WIDTH-1):0] iMEM [0:(DEPTH-1)] /* syn_ramstyle=block_ram */; 
    
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
    iMEM[14] = 32'h4C00000A;
    iMEM[15] = 32'h4D000003;
    iMEM[16] = 32'hCECD0000;
    iMEM[17] = 32'h30D00000;
    iMEM[18] = 32'h30D00001;
    iMEM[19] = 32'h30D00002;
    iMEM[20] = 32'h30D00003;
    iMEM[21] = 32'h30D00004;
    iMEM[22] = 32'h30D00005;
    iMEM[23] = 32'h30D00006;
    iMEM[24] = 32'h30D00007;
    iMEM[25] = 32'h50000005;

    // Initialize the rest of the memory to NOP (0x00000000)
    for (i = 26; i < 256; i++) begin 
        iMEM[i] = 32'h00000000;
    end        
end
// ----------------------------------


    // Read
    always @(posedge i_clk) begin
        if(!i_rst_n) begin
            o_data <= 'h0;
        end else begin
            if(i_read_ce)
                o_data <= iMEM[i_address];
        end
    end

    // Handshake
    reg data_valid;
    reg data_ready;
    wire addres_valid = (i_address <= 255);
    always @(posedge i_clk) begin
        if(!i_rst_n) begin
            data_valid <= 1'h0;
            data_ready <= 1'h0;
        end else begin
            data_valid <= 1'b0;
            data_ready <= 1'b0;
            if((i_read_ce)&&(addres_valid))
                data_valid <= 1'b1;
                data_ready <= 1'b1;
        end
    end
    assign o_data_valid = data_valid;
    assign o_data_ready = data_ready;

endmodule

module RVDSPCoProc(
    // Global Signals
    input   wire            i_clk,    // Clock 
    input   wire            i_rst_n,  // Active low reset
    // iMEM
    input   wire    [31:0]  i_imem_data,
    input   wire            i_imem_data_valid,
    input   wire            i_imem_data_ready,
    output  reg             o_imem_read_ce,
    output  reg      [7:0]  o_imem_address,
    // dMEM
    output  reg             o_read_ce,
    output  reg     [7:0]   o_read_address,
    input   wire    [31:0]  i_read_data,
    input   wire            i_read_data_valid,
    input   wire            i_read_data_ready,
    output  reg             o_write_ce,
    output  reg     [7:0]   o_write_address,
    output  reg     [31:0]  o_write_data,
    input   wire            i_write_done
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
    
    // Multi-write Register Path Controls (for MUL/DIV)
    reg                         reg_we_mul_high; // Write enable for Rd (High word / Quotient)
    reg                         reg_we_mul_low;  // Write enable for Rd+1 (Low word / Remainder)
    reg [3:0]                   rd_addr_low;     // Destination address for Low word/Remainder (Rd+1)
    reg [31:0]                  reg_wdata_high;  // Data for Rd (High word / Quotient)
    reg [31:0]                  reg_wdata_low;   // Data for Rd+1 (Low word / Remainder)
    
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
    parameter [2:0] 
        STATE_IDLE          = 3'h0,
        STATE_FETCH         = 3'h1,
        STATE_READ_IMEM     = 3'h2,
        STATE_DECODE        = 3'h3,
        STATE_READ_DMEM     = 3'h4,
        STATE_EXECUTE       = 3'h5,
        STATE_WRITE_DMEM    = 3'h6;
    reg [2:0] state_reg, state_next; 
        
    // Zero-Overhead Loop Control Registers (LSETUP) ---
    // LSETUP Rd, LC (8-bit), EndAddr (8-bit) - Opcode 1101 (D)
    reg [ADDR_BITS-1:0] r_loop_start_addr; // PC + 1 when LSETUP executes (address to jump back to)
    reg [ADDR_BITS-1:0] r_loop_end_addr;   // instruction[15:8] (address of the last instruction in the loop)
    reg [31:0]          r_loop_counter;    // The current loop iteration count (N+1 initial value)
    reg                 r_loop_active;     // 1 when a hardware loop is active
    reg                 loop_setup_en;     // Enable signal to latch LSETUP parameters in sequential block
    localparam [3:0]    OPCODE_LSETUP = 4'b1101; 
        
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
    
    // Register Write - Handles single (LOAD, READ_ACC, MOVE, MAC) and double (MUL/DIV) writes
    always @(posedge  i_clk or negedge  i_rst_n) begin 
        if (! i_rst_n) begin
            gpr[0] <= 32'h0000_0000;
            // Reset Loop Registers
            r_loop_active     <= 1'b0;
            r_loop_counter    <= 32'h0;
            r_loop_start_addr <= 8'h0;
            r_loop_end_addr   <= 8'h0;
        end else begin
            // 1. Single Write (MAC, LOAD, READ_ACC, MOVE, LSETUP)
            if (reg_we_single) begin
                gpr[rd_addr_single] <= reg_wdata_single;
            end
            
            // 2. Double Write for MUL/DIV: Write High Word / Quotient (Rd)
            if (reg_we_mul_high) begin
                gpr[rd_addr] <= reg_wdata_high;
            end
            
            // 3. Double Write for MUL/DIV: Write Low Word / Remainder (Rd+1). R15 wraps to R0.
            if (reg_we_mul_low) begin
                gpr[rd_addr_low] <= reg_wdata_low;
            end

            // --- Loop Control Register Updates ---
            if (loop_setup_en) begin
                // LSETUP instruction just executed: Setup the loop parameters
                r_loop_active     <= 1'b1;
                // Start address is PC_REG (LSETUP) + 1
                r_loop_start_addr <= pc_reg[ADDR_BITS-1:0] + 1; 
                // End address is instruction[15:8]
                r_loop_end_addr   <= instruction[15:8]; 
                // Counter init: instruction[23:16] is N. Store N+1 for the loop control logic.
                r_loop_counter    <= {24'h0, instruction[23:16]} + 1; 
            end 
            // Loop Iteration Update: Instruction at r_loop_end_addr just executed
            else if (r_loop_active && (state_reg == STATE_EXECUTE) && (pc_reg[ADDR_BITS-1:0] == r_loop_end_addr)) begin
                if (r_loop_counter > 32'h1) begin
                    // Decrement counter for the next loop
                    r_loop_counter <= r_loop_counter - 1;
                end else begin
                    // Counter reached 1, loop terminates on next cycle
                    r_loop_active <= 1'b0;
                    r_loop_counter <= 32'h0;
                end
            end
            // -------------------------------------

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
    // Division Unit (Combinatorial)
    //
    // Rs1 = Dividend, Rs2 = Divisor
    // We use the $signed operator to perform signed division.
    wire [31:0] div_quotient;
    wire [31:0] div_remainder;

    // Handle division by zero to prevent simulation errors. 
    // If Rs2 is 0, set quotient to 0 (or maximum/minimum value) and remainder to Rs1.
    // For simplicity, we just check for non-zero divisor.
    assign div_quotient = (reg_rdata2 != 32'h0) ? ($signed(reg_rdata1) / $signed(reg_rdata2)) : 32'h0;
    assign div_remainder = (reg_rdata2 != 32'h0) ? ($signed(reg_rdata1) % $signed(reg_rdata2)) : reg_rdata1;
    
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
            o_imem_read_ce <= 1'b0;
            o_read_ce <= 1'b0;
            o_write_ce <= 1'b0;
        end else begin
            state_reg <= state_next;
            pc_reg    <= pc_next;
            
            // Default memory control signals
            o_imem_read_ce <= 1'b0;
            o_read_ce <= 1'b0;
            o_write_ce <= 1'b0;
            
            case (state_reg)
                STATE_FETCH: begin
                    o_imem_read_ce <= 1'b1;
                    o_imem_address <= pc_reg[7:0];
                end
                
                STATE_READ_IMEM: begin
                    if((i_imem_data_valid)&&(i_imem_data_ready))
                        instruction <= i_imem_data;
                end
                
                STATE_READ_DMEM: begin
                    o_read_ce <= 1'b1;
                    o_read_address <= dmem_addr[7:0];
                end
                
                STATE_EXECUTE: begin
                    // if ((opcode == 4'b0011)||(opcode == 4'b1000)) begin
                    if (opcode == 4'b0011) begin
                        o_write_ce <= 1'b1;
                        o_write_address <= dmem_addr[7:0];
                        o_write_data <= dmem_wdata;
                    end
                end
            endcase
            
            done_flag <= ((state_reg == STATE_EXECUTE)&&(state_next == STATE_IDLE)||(state_reg == STATE_WRITE_DMEM)&&(state_next == STATE_IDLE));
        end
    end
    
    // Next State Logic (Combinational Block)
    always @* begin 
        state_next = state_reg;
        pc_next    = pc_reg;    
        dmem_we    = 1'b0;
        dmem_re    = 1'b0;
        dmem_addr  = instruction[ADDR_BITS-1:0]; 
        dmem_wdata = reg_rdata1;
        
        // Reset register write paths and loop setup enable
        reg_we_single = 1'b0;
        rd_addr_single = 4'b0;
        reg_wdata_single = 32'h0;
        reg_we_mul_high = 1'b0;
        reg_we_mul_low = 1'b0;
        rd_addr_low = 4'b0;
        reg_wdata_high = 32'h0;
        reg_wdata_low = 32'h0;
        loop_setup_en = 1'b0;
        
        // Instruction Decode 
        opcode   = instruction[31:28];
        rd_addr  = instruction[27:24];
        rs1_addr = instruction[23:20];
        rs2_addr = instruction[19:16]; 
        
        case (state_reg)
            STATE_IDLE: begin
                state_next = STATE_FETCH;
                pc_next    = 32'h0000_0000; 
            end
            
            STATE_FETCH: begin
                state_next = STATE_READ_IMEM;
            end
            
            STATE_READ_IMEM: begin
                if((i_imem_data_valid)&&(i_imem_data_ready))
                    state_next = STATE_DECODE;
                else
                    state_next = STATE_READ_IMEM;
            end
            
            STATE_DECODE: begin
                // Check if instruction needs data memory read (LOAD)
                if (opcode == 4'b0010) begin // LOAD
                    dmem_re = 1'b1;
                    state_next = STATE_READ_DMEM;
                end else begin
                    state_next = STATE_EXECUTE;
                end
            end
            
            STATE_READ_DMEM: begin
                // Wait for dMEM read to complete
                if(i_read_data_valid && i_read_data_ready) begin
                    dmem_rdata = i_read_data;
                    state_next = STATE_EXECUTE;
                end else begin
                    state_next = STATE_READ_DMEM;
                end
            end
            
            STATE_EXECUTE: begin
                // Check if instruction needs data memory write (STORE)
                if (opcode == 4'b0011) begin // STORE
                    dmem_we = 1'b1;
                    state_next = STATE_WRITE_DMEM;
                end else begin
                    state_next = STATE_FETCH;
                    pc_next    = pc_reg + 1; 
                end
                
                case (opcode)
                    // MAC Rd, Rs1, Rs2 (Opcode 1)
                    4'b0001: begin 
                        reg_we_single    = 1'b1;
                        rd_addr_single   = rd_addr;
                        reg_wdata_single = mac_sum_96[31:0]; // Write Low Acc word
                    end
                    
                    // LOAD Rd, Addr (Opcode 2)
                    4'b0010: begin 
                        reg_we_single  = 1'b1;
                        rd_addr_single = rd_addr;
                        reg_wdata_single = dmem_rdata; 
                    end
                    
                    // STORE Rs, Addr (Opcode 3)
                    4'b0011: begin 
                        // Memory write will be handled in STATE_WRITE_DMEM
                    end
                    
                    // MOVE Rd, Imm (Opcode 4)
                    4'b0100: begin 
                        reg_we_single    = 1'b1; 
                        rd_addr_single   = rd_addr;
                        // instruction[19:0] is the 20-bit immediate (sign extended)
                        reg_wdata_single = {{12{instruction[19]}}, instruction[19:0]}; 
                    end
                    
                    // JUMP Addr (Opcode 5)
                    4'b0101: begin 
                        // PC update handled below
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
                    
                    // DIV Rd, Rs1, Rs2 (Opcode C / 12)
                    4'b1100: begin
                        // Write 1: Quotient to Rd
                        reg_we_mul_high = 1'b1;
                        reg_wdata_high  = div_quotient; 
                        
                        // Write 2: Remainder to Rd+1 (R15 wraps to R0)
                        reg_we_mul_low  = 1'b1;
                        rd_addr_low     = rd_addr + 1; 
                        reg_wdata_low   = div_remainder; 
                    end

                    // LSETUP Rd, LC (8-bit), EndAddr (8-bit) (Opcode D / 13)
                    OPCODE_LSETUP: begin 
                        loop_setup_en    = 1'b1; // Trigger sequential update of loop registers
                        
                        // Write the initial loop count N (instruction[23:16]) to the destination register Rd
                        reg_we_single    = 1'b1; 
                        rd_addr_single   = rd_addr; 
                        // The loop count N is 8 bits (sign-extended for 32-bit register)
                        reg_wdata_single = {{24{instruction[23]}}, instruction[23:16]}; 
                    end
                    
                    // NOP (Opcode 0)
                    4'b0000: begin
                        // No control signals
                    end
                    
                    default: begin
                        // HALT or ILLEGAL instruction handling: treat as NOP
                    end
                endcase
                
                // PC Update Logic (only if not going to WRITE_DMEM)
                if (state_next == STATE_FETCH) begin
                    // 1. Check for Loop Branch (highest priority PC update)
                    if (r_loop_active && (pc_reg[ADDR_BITS-1:0] == r_loop_end_addr)) begin
                        if (r_loop_counter > 32'h1) begin 
                            // Loop back to start address
                            pc_next = {24'h0, r_loop_start_addr};
                        end else begin
                            // Last iteration completed, fall through to the next instruction
                            pc_next = pc_reg + 1;
                        end
                    // 2. Check for JUMP
                    end else if (opcode == 4'b0101) begin // JUMP Addr
                        pc_next = {24'h000000, instruction[7:0]}; 
                    // 3. Default: Increment PC
                    end else begin
                        pc_next = pc_reg + 1;
                    end
                end
            end
            
            STATE_WRITE_DMEM: begin
                // Wait for dMEM write to complete
                if(i_write_done) begin
                    state_next = STATE_FETCH;
                    pc_next    = pc_reg + 1;
                end else begin
                    state_next = STATE_WRITE_DMEM;
                end
            end
            
            default: begin
                state_next = STATE_IDLE;
            end
        endcase
    end

endmodule