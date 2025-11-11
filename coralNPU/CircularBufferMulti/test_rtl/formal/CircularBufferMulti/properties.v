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

    ////////////////////////////////////////////////////
	//
	// BMC
	//
	////////////////////////////////////////////////////

	// Flush resets the count to zero
	always @(posedge clock) begin
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(reset))&&(!reset))
			if ($past(io_flush)) begin
				assert (io_nEnqueued == 4'h0);
			end
	end

	// The output wire must exactly match the internal register.
	always @(*) 
		assert (io_nEnqueued == nEnqueued); // Passed implicitly by assign statement

	// Space must always be the complement of count.
	always @(*) 
		assert (io_nSpace == (4'h8 - nEnqueued)); // Passed implicitly by assign statement

	// The sum of io_nEnqueued and io_nSpace must always equal the depth.
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

	// // nEnqueued
	// // nEnqueued <= io_flush ? 4'h0 : nEnqueued + {1'h0, io_enqValid} - {1'h0, io_deqReady};
	// always @(posedge clock) begin
	// 	if(($past(f_past_valid, 2))&&($past(f_past_valid))&&(f_past_valid)&&(!$past(reset))&&(!reset))
	// 		if($past(rotatedInput_rotated[527]))
	// 			if($past(io_flush))
	// 				assert(nEnqueued == 4'h0);
	// 			if(!$past(io_flush))
	// 				assert($past(nEnqueued) + {1'h0, io_enqValid} - {1'h0, io_deqReady});
	// end

	// // // FIFO Count Update Correctness
	// // // 	Next Count = Previous Count + Enqueues - Dequeues
	// // //  assign io_nEnqueued = nEnqueued;
	// // // 	nEnqueued <= nEnqueued + {1'h0, io_enqValid} - {1'h0, io_deqReady};
	// // //	input  [2:0]  io_enqValid
	// // //	input  [2:0]  io_deqReady
	// // // 	reg  [3:0]   nEnqueued
	// // wire [3:0] aux00 = {1'h0, io_enqValid} - {1'h0, io_deqReady};
	// // wire [3:0] aux01 = nEnqueued + aux00;
	// // reg  [3:0] f_io_nEnqueued;
	// // reg  [2:0] f_io_enqValid;
	// // reg  [2:0] f_io_io_deqReady;
	// // reg  [3:0] f_nEnqueued;
	// // always @(posedge clk) begin
	// // 	f_io_nEnqueued <= io_nEnqueued;
	// // 	f_io_enqValid <= io_enqValid;
	// // 	f_io_io_deqReady <= io_io_deqReady;
	// // 	f_nEnqueued <= nEnqueued;
	// // end
	// // always @(posedge clock) begin
	// // 	if((f_past_valid)&&($past(f_past_valid))) begin
	// // 		// assert(io_nEnqueued == nEnqueued);
	// // 		// assert(aux00 == {1'h0, io_enqValid} - {1'h0, io_deqReady});
	// // 		// assert(aux01 == nEnqueued + aux00);
	// // 		// assert(io_nEnqueued == aux01);
	// // 		assert(f_io_nEnqueued == (f_nEnqueued + {1'h0, f_io_enqValid} - {1'h0, f_io_io_deqReady}));
	// // 	end
	// // end

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

