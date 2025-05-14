// =============================================================================
// File        : Formal Properties for boxcar_filter.v
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
`ifdef	boxcar_filter
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
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

	////////////////////////////////////////////////////
	//
	// Initial
	//
	////////////////////////////////////////////////////
	initial assert(sample_index == 0);
	initial assert(accumulator == 0);
	initial assert(valid_reg == 0);
	initial assert(o_ce == 0);
	initial assert(o_data == 0);
	

    ////////////////////////////////////////////////////
	//
	// Reset
	//
	////////////////////////////////////////////////////
	always @(posdge i_clk)
		if(($past(f_past_valid))&&(!$past(i_reset_n))) begin
			assert(sample_index == 0);
			assert(output_is_valid == 0);
			assert(valid_reg == 0);
			assert(sample_index == 0);
			assert(accumulator == 0);
		end


    ////////////////////////////////////////////////////
	//
	// BMC
	//
	////////////////////////////////////////////////////

    ////////////////////////////////////////////////////
	//
	// Contract
	//
	////////////////////////////////////////////////////   

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
           
`endif

