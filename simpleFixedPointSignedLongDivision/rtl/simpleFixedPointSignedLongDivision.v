// =============================================================================
// File        : simpleFixedPointSignedLongDivision.v
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

module simpleFixedPointSignedLongDivision #(
    parameter WIDTH=8,  // width of numbers in bits (integer and fractional)
    parameter FBITS=4   // fractional bits within WIDTH
    ) (
    input wire logic i_clk,    // clock
    input wire logic i_rst,    // reset
    input wire logic i_start,  // i_start calculation
    output     logic o_busy,   // calculation in progress
    output     logic o_done,   // calculation is complete (high for one tick)
    output     logic o_valid,  // result is o_valid
    output     logic o_dbz,    // divide by zero
    output     logic o_ovf,    // overflow
    input wire logic signed [WIDTH-1:0] a,      // dividend (numerator)
    input wire logic signed [WIDTH-1:0] b,      // divisor (denominator)
    output     logic signed [WIDTH-1:0] o_val   // result value: quotient
    );

    localparam WIDTHU = WIDTH - 1;                 // unsigned widths are 1 bit narrower
    localparam FBITSW = (FBITS == 0) ? 1 : FBITS;  // avoid negative vector width when FBITS=0
    localparam SMALLEST = {1'b1, {WIDTHU{1'b0}}};  // smallest negative number

    localparam ITER = WIDTHU + FBITS;  // iteration count: unsigned input width + fractional bits
    logic [$clog2(ITER):0] i;          // iteration counter (allow ITER+1 iterations for rounding)

    logic a_sig, b_sig, sig_diff;      // signs of inputs and whether different
    logic [WIDTHU-1:0] au, bu;         // absolute version of inputs (unsigned)
    logic [WIDTHU-1:0] quo, quo_next;  // intermediate quotients (unsigned)
    logic [WIDTHU:0] acc, acc_next;    // accumulator (unsigned but 1 bit wider)

    // input signs
    always_comb begin
        a_sig = a[WIDTH-1+:1];
        b_sig = b[WIDTH-1+:1];
    end

    // division algorithm iteration
    always_comb begin
        if (acc >= {1'b0, bu}) begin
            acc_next = acc - bu;
            {acc_next, quo_next} = {acc_next[WIDTHU-1:0], quo, 1'b1};
        end else begin
            {acc_next, quo_next} = {acc, quo} << 1;
        end
    end

    // calculation state machine
    enum {IDLE, INIT, CALC, ROUND, SIGN} state;
    always_ff @(posedge i_clk) begin
        o_done <= 0;
        case (state)
            INIT: begin
                state <= CALC;
                o_ovf <= 0;
                i <= 0;
                {acc, quo} <= {{WIDTHU{1'b0}}, au, 1'b0};  // initialize calculation
            end
            CALC: begin
                if (i == WIDTHU-1 && quo_next[WIDTHU-1:WIDTHU-FBITSW] != 0) begin  // overflow
                    state <= IDLE;
                    o_busy <= 0;
                    o_done <= 1;
                    o_ovf <= 1;
                end else begin
                    if (i == ITER-1) state <= ROUND;  // calculation complete after next iteration
                    i <= i + 1;
                    acc <= acc_next;
                    quo <= quo_next;
                end
            end
            ROUND: begin  // Gaussian rounding
                state <= SIGN;
                if (quo_next[0] == 1'b1) begin  // next digit is 1, so consider rounding
                    // round up if quotient is odd or remainder is non-zero
                    if (quo[0] == 1'b1 || acc_next[WIDTHU:1] != 0) quo <= quo + 1;
                end
            end
            SIGN: begin  // adjust quotient sign if non-zero and input signs differ
                state <= IDLE;
                if (quo != 0) o_val <= (sig_diff) ? {1'b1, -quo} : {1'b0, quo};
                o_busy <= 0;
                o_done <= 1;
                o_valid <= 1;
            end
            default: begin  // IDLE
                if (i_start) begin
                    o_valid <= 0;
                    if (b == 0) begin  // divide by zero
                        state <= IDLE;
                        o_busy <= 0;
                        o_done <= 1;
                        o_dbz <= 1;
                        o_ovf <= 0;
                    end else if (a == SMALLEST || b == SMALLEST) begin  // overflow
                        state <= IDLE;
                        o_busy <= 0;
                        o_done <= 1;
                        o_dbz <= 0;
                        o_ovf <= 1;
                    end else begin
                        state <= INIT;
                        au <= (a_sig) ? -a[WIDTHU-1:0] : a[WIDTHU-1:0];  // register abs(a)
                        bu <= (b_sig) ? -b[WIDTHU-1:0] : b[WIDTHU-1:0];  // register abs(b)
                        sig_diff <= (a_sig ^ b_sig);  // register input sign difference
                        o_busy <= 1;
                        o_dbz <= 0;
                        o_ovf <= 0;
                    end
                end
            end
        endcase
        if (i_rst) begin
            state <= IDLE;
            o_busy <= 0;
            o_done <= 0;
            o_valid <= 0;
            o_dbz <= 0;
            o_ovf <= 0;
            o_val <= 0;
        end
    end
endmodule
