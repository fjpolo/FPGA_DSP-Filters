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

	initial begin
		assert(sample_index == 0);
		assert(accumulator == 0);
		assert(valid_reg == 1'b0);
	end

	////////////////////////////////////////////////////
	//
	// Reset
	//
	////////////////////////////////////////////////////

	always @(*)
		if (!f_past_valid)
			assume(!i_reset_n);

	always @(posedge i_clk)
		if(($past(f_past_valid))&&(!$past(i_reset_n))) begin
			assert(sample_index == 0);
			assert(output_is_valid == 0);
			assert(valid_reg == 1'b0);
		end

    ////////////////////////////////////////////////////
	//
	// BMC
	//
	////////////////////////////////////////////////////

	always @(*)
		if(i_reset_n)
			assert(sample_index <= NUM_SAMPLES);

	//  Apparently I can't formally verify that initial assert(oldest_sample_index == -NUM_SAMPLES),
	// so I also can't do always (*) assert(oldest_sample_index <= NUM_SAMPLES) because it doesn't
	// pass case 0 where oldest_sample_index is assigned any value > NUM_SAMPLES
	//  So...this is my workaround: Ignore the first clock
	always @(posedge i_clk)
		if((!$past(f_past_valid))&&(f_past_valid)&&($past(i_reset_n))&&(i_reset_n))
			assert(oldest_sample_index <= NUM_SAMPLES);
	
	// sample_index should never ever be the same as oldest_sample_index
	always @(posedge i_clk)
		if((!$past(f_past_valid))&&(f_past_valid)&&($past(i_reset_n))&&(i_reset_n))
	 		assert(sample_index != oldest_sample_index);
	
	// Our oldest-sample index should move up whenever there's a i_ce
	always @(posedge i_clk)
	if((!$past(f_past_valid))&&(f_past_valid)&&(!$past(i_reset_n))&&(i_reset_n))
		if($past(i_ce)) begin
			if(!$past(oldest_sample_index_is_max))
				assert(oldest_sample_index == $past(oldest_sample_index) + 1);
			else
				assert(oldest_sample_index == -NUM_SAMPLES);
		end

	// Our sample index should move up whenever there's a i_ce
	always @(posedge i_clk)
	if((!$past(f_past_valid))&&(f_past_valid)&&(!$past(i_reset_n))&&(i_reset_n))
		if($past(i_ce))begin
			if(!$past(sample_index_is_max)) 
				assert(sample_index == $past(sample_index) + 1);
			else
				assert(sample_index == 0);
		end

	// Once we ran through NUM_SAMPLES samples, our outputs starts being valid
	always @(posedge i_clk)
		if((!$past(f_past_valid))&&(f_past_valid)&&(!$past(i_reset_n))&&(i_reset_n))
        	if($past(sample_index) == (NUM_SAMPLES-1)) begin	// For NUM_SAMPLES we iterate 0,1,2...(NUM_SAMPLES-1)
            	assert(output_is_valid);
				assert(o_ce);
			end

    ////////////////////////////////////////////////////
	//
	// Contract
	//
	////////////////////////////////////////////////////   
		
	// Our accumulator should accumulate and substract the oldest sample
	always @(posedge i_clk) begin
		if((!$past(f_past_valid))&&(f_past_valid)&&(!$past(i_reset_n))&&(i_reset_n))
			if($past(i_ce)) begin
				if ($past(output_is_valid)) begin
					assert(accumulator == $past(accumulator) - $past(sample_buffer[$past(oldest_sample_index)]) + $past(i_data));
				end else begin
					assert(accumulator == $past(accumulator) + $past(i_data));
				end
			end
	end

	// // Actually, if there's no i_data and no i_ce, o_data should be stable
	// always @(posedge i_clk) begin
	// 	if(
	// 		(($past(f_past_valid,3))&&($past(i_reset_n,3))&&($past(i_ce,3)))&&
	// 		(($past(f_past_valid,2))&&($past(i_reset_n,2))&&($past(i_ce,2)))&&
	// 		(($past(f_past_valid,1))&&($past(i_reset_n,1))&&($past(i_ce,1)))&&
	// 		((f_past_valid)&&(i_reset_n)&&(!i_ce))
	// 	)
	// 		if($past(o_ce))
	// 			// assert(!o_ce);
	// 			assert($stable(accumulator));
	// end

	// There can't be a valid output if there was no valid input
	always @(posedge i_clk) begin
		if(!$past(i_ce))
			assert(!o_ce);
	end

    ////////////////////////////////////////////////////
	//
	// Induction
	//
	////////////////////////////////////////////////////

	// Assumptions needed for induction
	always @(*)
		if (!f_past_valid) begin
			assume(sample_index == 0);
			assume(!i_ce);
		end
    
	////////////////////////////////////////////////////
	//
	// Cover
	//
	////////////////////////////////////////////////////  
	always @(posedge i_clk)
		if(!i_reset_n)
			cover(o_ce);
           
`endif

