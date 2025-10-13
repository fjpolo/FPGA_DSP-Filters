// =============================================================================
// File        : Formal Properties for longDivision.v
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
`ifdef	longDivision
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
	// Reset
	//
	////////////////////////////////////////////////////

	// always @(posedge i_clk)
	// 	if(!f_past_valid)
	// 		assume($past(i_rst));

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
	
	// Test 4/2 = 2
	always @(posedge i_clk)
		if(
			($past(f_past_valid,2))&&(!$past(i_rst,2))&&
			($past(f_past_valid))&&(!$past(i_rst))&&
			(f_past_valid)&&(!i_rst)&&
			($past(i_start, 2))&&
			($past(i_a, 2) == 4)&&($past(i_b, 2) == 2)&&
			($stable(f_past_valid))&&($stable(i_rst))&&
			($stable(i_a))&&
			(!o_busy)&&(o_valid)&&(o_done)
		) begin
			assert(o_quot == 2);
			assert(o_rem == 0);
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

	// Test quotient
	localparam MIN_QUOT = 1;
	localparam MAX_QUOT = 99;
	generate
		genvar quot_val;
		for (quot_val = MIN_QUOT; quot_val <= MAX_QUOT; quot_val = quot_val + 1) begin : cover_rem_loop        
			always @(posedge i_clk) begin
				if (
					(f_past_valid) && (!i_rst) &&
					(i_start)
				) begin
					cover(o_quot == (quot_val)&&(o_valid)&&(o_done));
				end
			end
		end
	endgenerate 

	// Test remainder
	localparam MIN_REM = 1;
	localparam MAX_REM = 99;
	generate
		genvar rem_val;
		for (rem_val = MIN_REM; rem_val <= MAX_REM; rem_val = rem_val + 1) begin : cover_rem_loop        always @(posedge i_clk) begin
				if (
					(f_past_valid) && (!i_rst) &&
					(i_start)
				) begin
					cover(o_rem == ((rem_val)&&(o_valid)&&(o_done)));
				end
			end
		end
	endgenerate

`endif

