// =============================================================================
// File        : Formal properties for FixedPointAdder.v mutations
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

parameter WIDTH = 8;  // width of numbers in bits (integer and fractional)
parameter FBITS = 4;  // fractional bits within WIDTH

module testbench (
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
    // Instantiate the dut
    FixedPointAdder ref(
            .i_clk      (i_clk),
            .i_rst      (i_rst),
            .i_start    (i_start),
            .i_operandA (i_operandA),
            .i_operandB (i_operandB),
            .o_busy     (o_busy),
            .o_done     (o_done),
            .o_valid    (o_valid),
            .o_overflow (o_overflow),
            .o_val      (o_val)
        );

    ////////////////////////////////////////////////////
	//
	// f_past_valid register
	//
	////////////////////////////////////////////////////
	reg	f_past_valid;
	initial	f_past_valid = 0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

    always @(*)
        assert((i_clk)||(!i_clk));

    ////////////////////////////////////////////////////
	//
	// Reset
	//
	////////////////////////////////////////////////////

	always @(posedge i_clk) begin
        if((f_past_valid)&&($past(i_rst))) begin
            assert(o_val   == '0);
            assert(o_done  == 1'b0);
            assert(o_valid == 1'b0);
		end
	end

    ////////////////////////////////////////////////////
	//
	// BMC
	//
	////////////////////////////////////////////////////

	// o_valid is valid when adder is done and there's no overflow
	always @(*)
		assert(o_valid == ((o_done)&&(!o_overflow)));
	
    ////////////////////////////////////////////////////
	//
	// Contract
	//
	////////////////////////////////////////////////////   

	// If o_valid && o_done, then o_val is the sum of the operands
 	always @(posedge i_clk) begin
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(i_rst))&&($past(i_start))&&(o_valid)&&(o_done)) begin
			assert(o_val == $past(i_operandA) + $past(i_operandB));
		end
	end
        
endmodule