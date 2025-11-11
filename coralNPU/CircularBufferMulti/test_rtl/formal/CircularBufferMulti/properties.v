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

	// FIFO Count Update Correctness
	// 	Next Count = Previous Count + Enqueues - Dequeues
	always @(posedge clock) begin
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(reset))&&(!reset)) begin
			if ($past(io_flush)) begin
				assert(io_nEnqueued == 4'h0);
			end else begin
				// Count must follow the FIFO update logic:	io_nEnqueued (State N+1) must equal next_nEnqueued_expected
				assert(io_nEnqueued == $past(io_nEnqueued + {1'b0, io_enqValid} - {1'b0, io_deqReady}));
			end
		end
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

	// // The buffer becomes completely full (nEnqueued == 8)
	// always @(posedge clock) begin
	// 	if (!reset) begin
	// 		cover (io_nEnqueued == 'h8);
	// 	end
	// end

	// // The buffer is completely empty (nEnqueued == 0)
	// // Note: This is usually covered by reset, but good to cover during run-time.
	// always @(posedge clock) begin
	// 	if (!reset) begin
	// 		cover (io_nEnqueued == 4'h0);
	// 	end
	// end

	// // The buffer is half-full (nEnqueued == 4)
	// always @(posedge clock) begin
	// 	if (!reset) begin
	// 		cover (io_nEnqueued == 4'h4);
	// 	end
	// end

	// DATA0 instruction integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_0_inst != 0)
				cover(io_dataOut_0_inst);

	// DATA1 instruction integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_1_inst != 0)
				cover(io_dataOut_1_inst);

	// DATA2 instruction integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_2_inst != 0)
				cover(io_dataOut_2_inst);

	// DATA3 instruction integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_3_inst != 0)
				cover(io_dataOut_3_inst);

	// DATA0 address integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_0_addr != 0)
				cover(io_dataOut_0_addr);

	// DATA1 address integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_1_addr != 0)
				cover(io_dataOut_1_addr);

	// DATA2 address integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_2_addr != 0)
				cover(io_dataOut_2_addr);

	// DATA3 address integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_3_addr != 0)
				cover(io_dataOut_3_addr);

	// DATA0 branch integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_0_brchFwd != 0)
				cover(io_dataOut_0_brchFwd);

	// DATA1 branch integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_1_brchFwd != 0)
				cover(io_dataOut_1_brchFwd);

	// DATA2 branch integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_2_brchFwd != 0)
				cover(io_dataOut_2_brchFwd);

	// DATA3 branch integrity
	always @(posedge clock)
		if (!reset)
			if(io_enqData_3_brchFwd != 0)
				cover(io_dataOut_3_brchFwd);
           
`endif

