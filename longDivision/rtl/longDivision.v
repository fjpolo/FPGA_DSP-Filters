// =============================================================================
// File        : longDivision.v
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
//  https://projectf.io/posts/division-in-verilog/
// =============================================================================
`default_nettype none
`timescale 1ps/1ps

module longDivision #(
        parameter WIDTH=32                   // width of numbers in bits
    ) ( 
        input wire logic i_clk,              // clock
        input wire logic i_rst,              // reset
        input wire logic i_start,            // start calculation
        output     logic o_busy,             // calculation in progress
        output     logic o_done,             // calculation is complete (high for one tick)
        output     logic o_valid,            // result is o_valid
        output     logic o_dbz,              // divide by zero
        input wire logic [WIDTH-1:0] i_a,    // dividend (numerator)
        input wire logic [WIDTH-1:0] i_b,    // divisor  (denominator)
        output     logic [WIDTH-1:0] o_quot,  // result value: quotient
        output     logic [WIDTH-1:0] o_rem   // result: remainder
    );

    logic [WIDTH-1:0] b1;             // copy of divisor
    logic [WIDTH-1:0] quo, quo_next;  // intermediate quotient
    logic [WIDTH:0] acc, acc_next;    // accumulator (1 bit wider)
    logic [$clog2(WIDTH)-1:0] i;      // iteration counter

    // division algorithm iteration
    always_comb begin
        if (acc >= {1'b0, b1}) begin
            acc_next = acc - b1;
            {acc_next, quo_next} = {acc_next[WIDTH-1:0], quo, 1'b1};
        end else begin
            {acc_next, quo_next} = {acc, quo} << 1;
        end
    end

    // calculation control
    always_ff @(posedge i_clk) begin
        o_done <= 0;
        if (i_start) begin
            o_valid <= 0;
            i <= 0;
            if (i_b == 0) begin  // catch divide by zero
                o_busy <= 0;
                o_done <= 1;
                o_dbz <= 1;
            end else begin
                o_busy <= 1;
                o_dbz <= 0;
                b1 <= i_b;
                {acc, quo} <= {{WIDTH{1'b0}}, i_a, 1'b0};  // initialize calculation
            end
        end else if (o_busy) begin
            if (i == WIDTH-1) begin  // we're o_done
                o_busy <= 0;
                o_done <= 1;
                o_valid <= 1;
                o_quot <= quo_next;
                o_rem <= acc_next[WIDTH:1];  // undo final shift
            end else begin  // next iteration
                i <= i + 1;
                acc <= acc_next;
                quo <= quo_next;
            end
        end
        if (i_rst) begin
            o_busy <= 0;
            o_done <= 0;
            o_valid <= 0;
            o_dbz <= 0;
            o_quot <= 0;
            o_rem <= 0;
        end
    end
endmodule
