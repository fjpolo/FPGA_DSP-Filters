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

	//
	// Data Integrity
	//
	// If deque slot X is active, then DataOut_x = DataIn_N
	// We need:
	//   1. A formal memory to store all enqueued data
	//   2. Logic to track the write and read pointers (head_ptr, tail_ptr) within the formal property file, mirroring the DUT's logic
	//   3. Assertions that compare the output data against the data at the head_ptr in the formal memory
	reg [31:0] f_data_mem_addr [7:0];
    reg [31:0] f_data_mem_inst [7:0];
    reg        f_data_mem_brchFwd [7:0];
    reg [2:0]  f_enqPtr;
    reg [2:0]  f_deqPtr;
	always @(posedge clock) begin
    if (reset) begin
        f_enqPtr <= 3'h0;
        f_deqPtr <= 3'h0;
        for (integer i = 0; i < 8; i = i + 1) begin
            f_data_mem_addr[i] <= 32'h0;
            f_data_mem_inst[i] <= 32'h0;
            f_data_mem_brchFwd[i] <= 1'b0;
        end
    end else if (io_flush) begin
        f_enqPtr <= 3'h0;
        f_deqPtr <= 3'h0;
    end else begin
        // Pointers update with implicit modulo 8, since they are 3-bit wide
        f_enqPtr <= f_enqPtr + io_enqValid;
        f_deqPtr <= f_deqPtr + io_deqReady;
        
        // Write parallel data to the formal memory starting at f_enqPtr.
        // Array indexing uses the 3-bit pointer, ensuring modulo 8 wrap-around.
        if (io_enqValid >= 3'h1) begin 
            // Data 0 written to index f_enqPtr + 0
            f_data_mem_addr[f_enqPtr + 3'h0] <= io_enqData_0_addr;
            f_data_mem_inst[f_enqPtr + 3'h0] <= io_enqData_0_inst;
            f_data_mem_brchFwd[f_enqPtr + 3'h0] <= io_enqData_0_brchFwd;
        end
        if (io_enqValid >= 3'h2) begin
            // Data 1 written to index f_enqPtr + 1
            f_data_mem_addr[f_enqPtr + 3'h1] <= io_enqData_1_addr;
            f_data_mem_inst[f_enqPtr + 3'h1] <= io_enqData_1_inst;
            f_data_mem_brchFwd[f_enqPtr + 3'h1] <= io_enqData_1_brchFwd;
        end
        if (io_enqValid >= 3'h3) begin
            // Data 2 written to index f_enqPtr + 2
            f_data_mem_addr[f_enqPtr + 3'h2] <= io_enqData_2_addr;
            f_data_mem_inst[f_enqPtr + 3'h2] <= io_enqData_2_inst;
            f_data_mem_brchFwd[f_enqPtr + 3'h2] <= io_enqData_2_brchFwd;
        end
    end
end

	//
	// Temporal/Ordering Integrity
	// 
	// If DataIn_A is written befor DataIn_B, then DataOut_A must be read before DataOut

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

	// The buffer becomes completely full (nEnqueued == 8)
	always @(posedge clock) begin
		if (!reset) begin
			cover (io_nEnqueued == 'h8);
		end
	end

	// The buffer is completely empty (nEnqueued == 0)
	// Note: This is usually covered by reset, but good to cover during run-time.
	always @(posedge clock) begin
		if (!reset) begin
			cover (io_nEnqueued == 4'h0);
		end
	end

	// The buffer is half-full (nEnqueued == 4)
	always @(posedge clock) begin
		if (!reset) begin
			cover (io_nEnqueued == 4'h4);
		end
	end

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

