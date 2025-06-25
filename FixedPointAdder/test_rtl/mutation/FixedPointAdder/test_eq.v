// =============================================================================
// File        : Equivalence Check for FixedPointAdder.v mutations
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

module miter(
    input wire logic i_clk,                             // clock
    input wire logic i_rst,                             // reset
    input wire logic i_start,                           // start calculation
    output      logic o_busy,                           // calculation in progress
    output      logic o_done,                           // calculation is complete (high for one tick)
    output      logic o_valid,                          // result is valid
    output      logic o_overflow,                       // overflow flag
    input wire logic signed [WIDTH-1:0] i_operandA,     // Operand A (Q(WIDTH-FBITS-1).FBITS format)
    input wire logic signed [WIDTH-1:0] i_operandB,     // Operand B (Q(WIDTH-FBITS-1).FBITS format)
    output     logic signed [WIDTH-1:0] o_val           // result value (Q(WIDTH-FBITS-1).FBITS format)
    );
    parameter WIDTH=8;     // width of numbers in bits (integer and fractional)
    parameter FBITS=4;     // fractional bits within WIDTH
    
    // Reference signals
    logic signed    [WIDTH-1:0] i_operandA_ref;
    logic signed    [WIDTH-1:0] i_operandB_ref;
    logic signed    [WIDTH-1:0] o_val_ref;
    logic signed    [0:0]       o_busy_ref;
    logic signed    [0:0]       o_done_ref;
    logic signed    [0:0]       o_valid_ref;
    logic signed    [0:0]       o_overflow_ref;

    // DUT signals
    logic signed    [WIDTH-1:0] i_operandA_uut;
    logic signed    [WIDTH-1:0] i_operandB_uut;
    logic signed    [WIDTH-1:0] o_val_uut;
    logic signed    [0:0]       o_busy_uut;
    logic signed    [0:0]       o_done_uut;
    logic signed    [0:0]       o_valid_uut;
    logic signed    [0:0]       o_overflow_uut;

    // Instantiate the reference
    FixedPointAdder ref(
        .i_clk      (i_clk),
        .i_rst      (i_rst),
        .i_start    (i_start),
        .i_operandA (i_operandA),
        .i_operandB (i_operandB),
        .o_busy     (o_busy_ref),
        .o_done     (o_done_ref),
        .o_valid    (o_valid_ref),
        .o_overflow (o_overflow_ref),
        .o_val      (o_val_ref)
    );

    // Instantiate the UUT
    FixedPointAdder uut (
        .i_clk      (i_clk),
        .i_rst      (i_rst),
        .i_start    (i_start),
        .i_operandA (i_operandA),
        .i_operandB (i_operandB),
        .o_busy     (o_busy_uut),
        .o_done     (o_done_uut),
        .o_valid    (o_valid_uut),
        .o_overflow (o_overflow_uut),
        .o_val      (o_val_uut)
    );

    // Assumptions
    always @(*) begin
        assume(i_operandA == i_operandA_ref == i_operandA_uut);
    end
    always @(*) begin
        assume(i_operandB == i_operandB_ref == i_operandB_uut);
    end
    always @(posedge i_clk) begin
        assume(o_busy == o_busy_ref == o_busy_uut);
    end

    // // Assertions
    always @(posedge i_clk) begin
        assume(o_done == o_done_ref == o_done_uut);
    end
    always @(posedge i_clk) begin
        assume(o_valid == o_valid_ref == o_valid_uut);
    end
    always @(posedge i_clk) begin
        assert(o_overflow == o_overflow_ref == o_overflow_uut);
    end

endmodule