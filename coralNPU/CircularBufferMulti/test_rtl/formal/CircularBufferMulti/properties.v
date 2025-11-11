// =============================================================================
// File        : Formal Properties for CircularBufferMulti.v
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
`ifdef	CircularBufferMulti
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
	always @(posedge clock)
		f_past_valid <= 1'b1;
	always @(posedge clock)
		if(!f_past_valid)
			assume(reset);



    ////////////////////////////////////////////////////
	//
	// Reset
	//
	////////////////////////////////////////////////////

	// Flush resets the count to zero
	always @(posedge clock) begin
		if(($past(f_past_valid))&&(f_past_valid)&&($past(reset))&&(!reset))
			if (io_flush) begin
				assert (io_nEnqueued == 4'h0);
			end
	end

    ////////////////////////////////////////////////////
	//
	// BMC
	//
	////////////////////////////////////////////////////

	// // Calculate change in count
	// wire [3:0] delta_count = {1'b0, io_enqValid} - {1'b0, io_deqReady};
	// // Expected next count
	// reg [3:0] nEnqueued_prev;
	// always @(posedge clock) begin
	// 	if (reset) begin
	// 		nEnqueued_prev <= 4'h0;
	// 	end else begin
	// 		nEnqueued_prev <= io_nEnqueued; 
	// 	end
	// end
	// wire [3:0] next_nEnqueued_expected = nEnqueued_prev + delta_count;
	// // Count logic update is correct
	// always @(posedge clock) begin
	// 	if(($past(f_past_valid))&&(f_past_valid)&&(!$past(reset))&&(!reset))
	// 		if ((!$past(init))&&(!reset)&&(!io_flush)) begin
	// 			assert (io_nEnqueued == next_nEnqueued_expected);
	// 		end
	// end

	// Space is always the complement of count
  	// assign io_nEnqueued = nEnqueued;
  	// assign io_nSpace = 4'h8 - nEnqueued;
	always @(*) 
			assert (io_nEnqueued == nEnqueued);
	always @(*) 
			assert (io_nSpace == (4'h8 - nEnqueued));
	always @(*) 
			assert ((io_nEnqueued + io_nSpace) == 4'h8);

	// Empty and Full checks
	always @(posedge clock) begin
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(reset))&&(!reset))
			// Empty implies max space
			if (io_nEnqueued == 4'h0) 
				assert (io_nSpace == 4'h8);
			// Full implies zero space
			if (io_nEnqueued == 4'h8) 
				assert (io_nSpace == 4'h0);
	end

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

