// =============================================================================
// File        : Equivalence Check for lcompressor.v mutations
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

module miter (
    input  wire           [0:0]         i_clk,
    input  wire           [0:0]         i_reset_n,
    input  wire           [0:0]         i_ce,           
    input  wire  signed   [W_TOTAL-1:0] i_data,             // Q1.15 signed audio input
    input  wire  signed   [W_TOTAL-1:0] i_threshold_pos,    // Q1.15 signed threshold - positive
    input  wire  signed   [W_TOTAL-1:0] i_threshold_neg,    // Q1.15 signed threshold - negative
    output reg   signed   [W_TOTAL-1:0] o_data,             // Q1.15 signed audio output
    output wire           [0:0]         o_ce     
);

    localparam W_TOTAL = 16;

    // Reference signals
    reg   signed   [W_TOTAL-1:0] i_data_ref;
    reg   signed   [W_TOTAL-1:0] i_threshold_pos_ref;
    reg   signed   [W_TOTAL-1:0] i_threshold_neg_ref;
    reg   signed   [W_TOTAL-1:0] o_data_ref;
    reg            [0:0]         o_ce_ref;  

    // DUT signals
    reg   signed   [W_TOTAL-1:0] i_data_uut;
    reg   signed   [W_TOTAL-1:0] i_threshold_pos_uut;
    reg   signed   [W_TOTAL-1:0] i_threshold_neg_uut;
    reg   signed   [W_TOTAL-1:0] o_data_uut;
    reg            [0:0]         o_ce_uut;  

    // Instantiate the reference
    lcompressor ref(
        .i_clk      (i_clk),
        .i_reset_n  (i_reset_n),
        .i_ce       (i_ce),
        .i_data     (i_data_ref),
        .i_threshold_pos(i_threshold_pos_ref),
        .i_threshold_neg(i_threshold_neg_ref),
        .o_data     (o_data_ref),
        .o_ce       (o_ce_ref)
    );

    // Instantiate the UUT
    lcompressor uut(
        .i_clk      (i_clk),
        .i_reset_n  (i_reset_n),
        .i_ce       (i_ce),
        .i_data     (i_data_uut),
        .i_threshold_pos(i_threshold_pos_uut),
        .i_threshold_neg(i_threshold_neg_uut),
        .o_data     (o_data_uut),
        .o_ce       (o_ce_uut)
    );

    // Assumptions
    always @(*) begin
        assume(i_data == i_data_ref == i_data_uut);
        assume(i_data == i_threshold_pos_ref == i_threshold_pos_uut);
        assume(i_data == i_threshold_neg_ref == i_threshold_neg_uut);
    end

    // Assertions
    always @(posedge i_clk) begin
        if(!$past(i_reset_n))
            assert(o_data_ref == o_data_uut);
    end

    always @(*)
        assert(o_data_ref == o_data_uut);

    always @(*)
        assert(o_ce_ref == o_ce_uut);

endmodule