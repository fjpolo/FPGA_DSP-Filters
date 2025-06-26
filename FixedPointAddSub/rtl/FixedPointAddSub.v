// =============================================================================
// File        : FixedPointAddSub.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Parameterizable signed fixed-point adder/subtractor
//               with saturation logic and overflow detection.
//               Controlled by 'i_sub' flag.
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
// Reference: https://www.linkedin.com/pulse/why-dsp-based-algorithms-need-special-attention-rtl-design-eladawy-v3mmf/?trackingId=AEPhXm7Ye41DVtcrosiLFg%3D%3D
`default_nettype none
`timescale 1ps/1ps

module FixedPointAddSub #(
    parameter WIDTH=8,                                  // Total width of signed fixed-point numbers (integer + fractional + sign bit)
    /* verilator lint_off UNUSEDPARAM */
    parameter FBITS=4                                   // Number of fractional bits. Used for format interpretation (Q format is Q(WIDTH-FBITS-1).FBITS)
    /* verilator lint_on UNUSEDPARAM */
    ) (
    input wire logic i_clk,                             // Clock
    input wire logic i_rst,                             // Asynchronous reset (active high)
    input wire logic i_start,                           // Start calculation (pulse high for one cycle to initiate)
    input wire logic i_sub,                             // Operation select: 0 = Add (A+B), 1 = Subtract (A-B)

    output      logic o_busy,                           // High when operation is in progress (registered)
    output      logic o_done,                           // High for one clock cycle when calculation is complete (registered)
    output      logic o_valid,                          // High for one clock cycle when o_val contains a valid result (registered)
                                                        // This implies o_val is ready, regardless of saturation.
    output      logic o_overflow,                       // High for one clock cycle if saturation occurred (registered)

    input wire logic signed [WIDTH-1:0] i_operandA,     // Signed fixed-point Operand A
    input wire logic signed [WIDTH-1:0] i_operandB,     // Signed fixed-point Operand B
    output      logic signed [WIDTH-1:0] o_val          // Signed fixed-point result (saturated if overflowed)
);

// Internal wire for the operand B's value depending on operation (B or -B).
// This is used to implement A + B or A + (-B) for subtraction.
wire signed [WIDTH-1:0] b_for_op;

// The intermediate sum/difference before saturation.
// It needs to be one bit wider than WIDTH to correctly detect both positive and negative overflow.
wire signed [WIDTH:0] result_extended;

// Calculate the maximum and minimum representable values for a WIDTH-bit signed number.
// These are extended to WIDTH+1 bits to match 'result_extended' for comparison.
localparam signed [WIDTH:0] MAX_VAL_EXT = (2**(WIDTH-1)) - 1; // E.g., for WIDTH=8, MAX_VAL=127. Extended: 0_0111_1111
localparam signed [WIDTH:0] MIN_VAL_EXT = -(2**(WIDTH-1));    // E.g., for WIDTH=8, MIN_VAL=-128. Extended: 1_1000_0000

// Determine 'b_for_op': if i_sub is 0, use i_operandB; if i_sub is 1, use two's complement of i_operandB.
// The two's complement of X is (~X + 1).
assign b_for_op = !i_sub ? i_operandB : (~i_operandB + 1);

// Perform the addition or subtraction combinatorially.
// This result is WIDTH+1 bits to hold potential overflow.
assign result_extended = i_operandA + b_for_op;

    always @(posedge i_clk) begin
        if(i_rst) begin
            // Reset all outputs
            o_val      <= '0;
            o_done     <= 1'b0;
            o_valid    <= 1'b0; // Reset valid signal
            o_overflow <= 1'b0;
            o_busy     <= 1'b0;
        end else begin
            // Default de-assertion for pulse-type outputs
            o_done     <= 1'b0;
            o_valid    <= 1'b0; // Default to 0
            o_overflow <= 1'b0; // Default to no overflow

            // Busy remains high for the cycle 'i_start' is high, then low.
            // This assumes a 1-cycle latency from 'i_start' to 'o_done'/'o_valid'.
            o_busy <= i_start;

            if(i_start) begin
                // Apply saturation logic based on result_extended
                // Compare result_extended (WIDTH+1 bits) with MAX_VAL_EXT/MIN_VAL_EXT (also WIDTH+1 bits)
                if (result_extended > MAX_VAL_EXT) begin
                    // Positive saturation
                    o_val      <= MAX_VAL_EXT[WIDTH-1:0]; // Clip to max positive value (original WIDTH)
                    o_overflow <= 1'b1;                   // Set overflow flag
                    o_valid <= 1'b0;
                end else if (result_extended < MIN_VAL_EXT) begin
                    // Negative saturation
                    o_val      <= MIN_VAL_EXT[WIDTH-1:0];    // Clip to min negative value (original WIDTH)
                    o_overflow <= 1'b1;                   // Set overflow flag
                    o_valid <= 1'b0;
                end else begin
                    // No saturation
                    o_val      <= $signed(result_extended[WIDTH-1:0]); // Take the lower WIDTH bits, preserving signedness
                    // o_overflow remains 1'b0 as set by default at the beginning of the else branch
                    o_valid <= 1'b1;
                end
                // Signal completion and validity on the next cycle
                o_done  <= 1'b1;
            end
        end
    end
    
endmodule
