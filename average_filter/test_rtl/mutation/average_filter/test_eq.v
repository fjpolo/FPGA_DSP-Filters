// =============================================================================
// File        : Equivalence Check for average_filter.v mutations
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
    input   wire    [0:0]   i_clk,
    input   wire    [0:0]   i_reset_n,
    input   wire    [0:0]   i_ce,
    input   wire    [7:0]   i_data,
    output  reg     [7:0]   o_data,
    output  reg     [0:0]   o_ce
);

    // Reference signals
    wire    [7:0]   i_data_ref;
    wire    [7:0]   o_data_ref;
    wire    [0:0]   o_ce_ref;

    // DUT signals
    wire    [7:0]   i_data_uut;
    wire    [7:0]   o_data_uut;
    wire    [0:0]   o_ce_uut;

    // Instantiate the reference
    average_filter ref(
        .clk(i_clk),
        .reset_n(i_reset_n),
        .i_ce(i_ce),
        .data_in(i_data_ref),
        .data_out(o_data_ref),
        .o_ce(o_ce_ref),
        .mutsel(1'b0)
        );
        
        // Instantiate the UUT
        average_filter uut(
        .clk(i_clk),
        .reset_n(i_reset_n),
        .i_ce(i_ce),
        .data_in(i_data_uut),
        .data_out(o_data_uut),
        .o_ce(o_ce_uut),
        .mutsel(1'b1)
    );

    // Assumptions
    always @(*)
        assume(i_data == i_data_ref == i_data_ref);

    // Assertions
    always @(posedge i_clk)
        if(!$past(i_reset_n))
            assert(o_data_ref == o_data_uut);

    always @(*)
        assert(o_data_ref == o_data_uut);

    always @(*)
        assert(o_ce_ref == o_ce_uut);

endmodule