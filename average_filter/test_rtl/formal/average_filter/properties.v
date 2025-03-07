// =============================================================================
// File        : Formal Properties for average_filter.v
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
`ifdef	FORMAL
// Change direction of assumes
`define	ASSERT	assert
`ifdef	average_filter
`define	ASSUME	assume
`else
`define	ASSUME	assert
`endif

    ////////////////////////////////////////////////////
	//
	// f_past_valid register
	//
	////////////////////////////////////////////////////
	reg	f_past_valid;
	initial	f_past_valid = 0;
		always @(posedge clk)
			f_past_valid <= 1'b1;
	
	// initial assume(!reset_n);

    ////////////////////////////////////////////////////
	//
	// Reset
	//
	////////////////////////////////////////////////////
	always @(posedge clk) begin
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(reset_n))&&(reset_n)) begin
			assert(!sum_ce);
			assert(!o_ce);
			assert(last_sample == 'h00);
			assert(sum_ff == 'h00);
			assert(data_out == 'h00);
		end
	end

    ////////////////////////////////////////////////////
	//
	// BMC
	//
	////////////////////////////////////////////////////

	always @(posedge clk) begin
		if ((f_past_valid)&&($past(reset_n))&&(reset_n)) 
		  if($past(i_ce))
			assert(sum_ce == 1);
	end

	always @(posedge clk) begin
		if ((f_past_valid)&&($past(reset_n))&&(reset_n)) 
		  if($past(sum_ce))
			assert(o_ce == 1);
	end

	always @(posedge clk) begin
		if ((f_past_valid)&&($past(reset_n))&&(reset_n)) 
		  if($past(i_ce))
			assert(last_sample == $past(data_in));
	end

	always @(posedge clk) begin
		if ((f_past_valid)&&($past(reset_n))&&(reset_n)) 
		  if($past(i_ce))
			assert(sum_ff == $past(data_in) + $past(last_sample));
	end

	always @(posedge clk) begin
		if ((f_past_valid)&&($past(reset_n))&&(reset_n)) 
		  if($past(sum_ce))
			assert(data_out == $past(sum_ff[8:1]));
	end

    ////////////////////////////////////////////////////
	//
	// Contract
	//
	//////////////////////////////////////////////////// 
	
	// Once a i_ce is issued, with valid data, after two clocks, o_ce must be high and data_out must be valid
	always @(posedge clk) begin
		if (($past(f_past_valid,2))&&($past(f_past_valid))&&(f_past_valid)&&(!$past(reset_n))&&(reset_n)) 
		  if(($past(i_ce,2))&&(!$past(i_ce))&&($past(sum_ce))&&(!sum_ce)&&(!$past(o_ce))) begin
			assert(o_ce);
			assert(data_out == ($past(data_in, 2) + $past(last_sample, 2)));
		  end
	end

    ////////////////////////////////////////////////////
	//
	// Induction
	//
	////////////////////////////////////////////////////
    
	////////////////////////////////////////////////////
	//
	// Cover
	//
	////////////////////////////////////////////////////
	always @(posedge clk) begin
		assume(reset_n);
		assume(data_in != $past(data_in));
		assume(data_in != 0);
		if((f_past_valid)&&($past(f_past_valid)))
			if(i_ce)
				cover(o_ce);
	end     
           
`endif

