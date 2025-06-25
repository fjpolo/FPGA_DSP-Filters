// =============================================================================
// File        : FixedPointAdder.v
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
// https://www.linkedin.com/pulse/why-dsp-based-algorithms-need-special-attention-rtl-design-eladawy-v3mmf/?trackingId=AEPhXm7Ye41DVtcrosiLFg%3D%3D
`default_nettype none
`timescale 1ps/1ps

module FixedPointAdder #(
    parameter WIDTH=8,                                  // width of numbers in bits (integer and fractional)
    /* verilator lint_off UNUSEDPARAM */
    parameter FBITS=4                                   // fractional bits within WIDTH
    /* verilator lint_on UNUSEDPARAM */
    ) (
    input wire logic i_clk,                             // clock
    input wire logic i_rst,                             // reset
    input wire logic i_start,                           // start calculation
    output      logic o_busy,                           // calculation in progress
    output      logic o_done,                           // calculation is complete (high for one tick)
    output      logic o_valid,                          // result is valid
    output      logic o_overflow,                       // overflow flag
    input wire logic signed [WIDTH-1:0] i_operandA,     // Operand A (Q(WIDTH-FBITS-1).FBITS format)
    input wire logic signed [WIDTH-1:0] i_operandB,     // Operand B (Q(WIDTH-FBITS-1).FBITS format)
    output      logic signed [WIDTH-1:0] o_val          // result value (Q(WIDTH-FBITS-1).FBITS format)
);

// Internal wire for the sum before saturation.
// It needs to be one bit wider than WIDTH to detect overflow.
wire signed [WIDTH:0] sum_extended;

// Calculate the maximum and minimum representable values for the Q(WIDTH-FBITS-1).FBITS format.
// For a signed N-bit number, the max value is 2^(N-1) - 1 and min is -2^(N-1).
// In our case, the output is WIDTH bits.
localparam signed [WIDTH:0] MAX_VAL_EXT  = (2**(WIDTH-1)) - 1;
localparam signed [WIDTH:0] MIN_VAL_EXT  = -(2**(WIDTH-1));

// Perform the addition using the wider intermediate sum_extended
assign sum_extended = i_operandA + i_operandB;

    always @(posedge i_clk) begin
        if(i_rst) begin
            o_val <= '0;                                // Reset output value to all zeros
            o_done <= 1'b0;                             // Reset done signal
            o_valid <= 1'b0;                            // Reset valid signal
            o_busy <= 1'b0;                             // Reset busy signal
        end else begin
            o_done <= 1'b0;                             // Default to 0
            o_valid <= 1'b0;                            // Default to 0
            o_busy <= i_start;                          // Busy while i_start is high (for single-cycle operation)
            o_overflow <= 1'b0;                     // Reset overflow flag

            if(i_start) begin
                o_overflow <= 1'b0;                     // Reset overflow flag
                // Apply saturation logic based on sum_extended
                // Compare sum_extended (WIDTH+1 bits) with MAX_VAL_EXT/MIN_VAL_EXT (also WIDTH+1 bits)
                if (sum_extended > MAX_VAL_EXT) begin
                    // Signal flag
                    o_overflow <= 1'b1;                // Set overflow flag
                    // Assign the WIDTH-bit version of the max value
                    o_val <= MAX_VAL_EXT[WIDTH-1:0];
                end else if (sum_extended < MIN_VAL_EXT) begin
                    // Assign the WIDTH-bit version of the min value
                    o_val <= MIN_VAL_EXT[WIDTH-1:0];
                end else begin
                    // No saturation needed, take the lower WIDTH bits of sum_extended
                    o_val <= $signed(sum_extended[WIDTH-1:0]);
                end
                o_done <= 1'b1;                         // Indicate that the operation is done
                o_valid <= 1'b1;                        // Result is valid
            end
        end
    end

endmodule
