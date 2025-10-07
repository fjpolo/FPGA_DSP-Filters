// =============================================================================
// File        : lcompressor.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Basic linear compressor
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

module lcompressor #(
    // --- Format Parameters ---
    parameter W_TOTAL = 16      // Total bit width (Q1.15)
) (
    input  wire           [0:0]         i_clk,
    input  wire           [0:0]         i_reset_n,
    input  wire           [0:0]         i_ce,           
    input  wire  signed   [W_TOTAL-1:0] i_data,             // Q1.15 signed audio input
    input  wire  signed   [W_TOTAL-1:0] i_threshold_pos,    // Q1.15 signed threshold - positive
    input  wire  signed   [W_TOTAL-1:0] i_threshold_neg,    // Q1.15 signed threshold - negative
    output reg   signed   [W_TOTAL-1:0] o_data,             // Q1.15 signed audio output
    output wire           [0:0]         o_ce            
);

// --- Clock Enable (CE) Register (1 cycle of latency) ---
// o_ce_reg is the registered version of i_ce, giving 1 cycle latency
reg o_ce_reg;
initial o_ce_reg = 1'b0;

assign o_ce = o_ce_reg;

//
// --- Stage 1 (Combinational Logic): Hard Clipping ---
//
wire signed [W_TOTAL-1:0] clipped_data;

// Clipping Logic: Operates directly on i_data (restoring the correct combinatorial logic)
// If data exceeds positive threshold, clamp to positive threshold.
// Else if data is below negative threshold, clamp to negative threshold.
// Else, pass through.
assign clipped_data = (i_data > i_threshold_pos) ? i_threshold_pos :
                      (i_data < i_threshold_neg) ? i_threshold_neg :
                      i_data;


//
// --- Stage 1 (Register): Output Registration ---
//

// Register the Clock Enable signal
always @(posedge i_clk) begin
    o_ce_reg <= i_ce;
    if(!i_reset_n)
        o_ce_reg <= 1'b0;
end

// Register the final, correctly clipped data to the output
always @(posedge i_clk) begin
    if (!i_reset_n) begin
        o_data <= {W_TOTAL{1'b0}};
    end else if (i_ce) begin // Gate registration using the input CE
        o_data <= clipped_data; // Register the result of the combinatorial logic
    end
end

endmodule
