// =============================================================================
// File        : Formal properties for lcompressor.v mutations
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

module testbench (
    input  wire           [0:0]         i_clk,
    input  wire           [0:0]         i_reset_n,
    input  wire           [0:0]         i_ce,           
    input  wire  signed   [W_TOTAL-1:0] i_data, 			// Q1.15 signed audio input
	input  wire  signed   [W_TOTAL-1:0] i_threshold_pos,    // Q1.15 signed threshold - positive
    input  wire  signed   [W_TOTAL-1:0] i_threshold_neg,    // Q1.15 signed threshold - negative
    output reg   signed   [W_TOTAL-1:0] o_data, 			// Q1.15 signed audio output
    output wire           [0:0]         o_ce            
);
    localparam W_TOTAL = 16;

    // Instantiate the dut
    lcompressor ref(
        .i_clk(i_clk),
        .i_reset_n(i_reset_n),
        .i_data(i_data),
        .o_data(o_data)
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

	always @(posedge i_clk)
		if(!f_past_valid)
			assume(!i_reset_n);

    ////////////////////////////////////////////////////
	//
	// Reset
	//
	////////////////////////////////////////////////////

	// o_data: Output must be zero immediately after reset
    always @(posedge i_clk) begin
        if (($past(!i_reset_n)&&(f_past_valid))) begin
            assert(o_data == 'h0);
        end
    end

    ////////////////////////////////////////////////////
	//
	// BMC
	//
	////////////////////////////////////////////////////

	always @(posedge i_clk) begin
		assume($stable(i_threshold_pos));
		assume($stable(i_threshold_neg));
	end

    ////////////////////////////////////////////////////
	//
	// Contract
	//
	////////////////////////////////////////////////////   

	// o_ce: must be high 4 clocks after i_ce is high
	always @(posedge i_clk) begin
		if(
			($past(f_past_valid))&&($past(i_reset_n))&&
			(f_past_valid)&&(i_reset_n)
		) begin
			if($past(i_ce))
				assert(o_ce);
		end
	end

	// i_data must not exceed full scale
    // The design handles saturation, but this assumes valid input
    always @(*)
		assert($signed(i_data) >= -(1 << (W_TOTAL - 1)));
    always @(*)
    	assert($signed(i_data) <= (1 << (W_TOTAL - 1)) - 1);	

	// o_data
	always @(posedge i_clk) begin
		if(
			($past(f_past_valid))&&($past(i_reset_n))&&
			(f_past_valid)&&(i_reset_n)
		) begin
			if(o_ce)
				if($past(i_data) > i_threshold_pos)
					assert(o_data == i_threshold_pos);
				else if($past(i_data) < i_threshold_neg)
					assert(o_data == i_threshold_neg);
				else
					assert(o_data == $past(i_data));
		end
	end

    ////////////////////////////////////////////////////
	//
	// Induction
	//
	////////////////////////////////////////////////////

	// Output must never exceed the maximum positive value (No Clipping/Overflow)
    always @(posedge i_clk) begin
        if ((f_past_valid)&&(i_reset_n)&&(o_ce)) begin
            assert($signed(o_data) <= (1 << (W_TOTAL - 1)) - 1);
        end
    end

	// Output must never exceed the maximum negative value (No Clipping/Overflow)
    always @(posedge i_clk) begin
        if ((f_past_valid) && (i_reset_n) && (o_ce)) begin
            assert($signed(o_data) >= -(1 << (W_TOTAL - 1)));
        end
    end
    
	////////////////////////////////////////////////////
	//
	// Cover
	//
	////////////////////////////////////////////////////     
	
	// o_ce
	always @(posedge i_clk) begin
		if((f_past_valid)&&(i_reset_n)&&(i_ce))
			cover(o_ce);
	end

	// o_data
	always @(posedge i_clk) begin
		if((f_past_valid)&&(i_reset_n)&&(i_ce))
			cover(o_data == $past(i_data));
	end
	always @(posedge i_clk) begin
		if((f_past_valid)&&(i_reset_n)&&(i_ce))
			cover(o_data == i_threshold_pos);
	end
	always @(posedge i_clk) begin
		if((f_past_valid)&&(i_reset_n)&&(i_ce))
			cover(o_data == i_threshold_neg);
	end
        
endmodule