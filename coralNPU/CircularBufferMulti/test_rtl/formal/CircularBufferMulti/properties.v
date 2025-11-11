// =============================================================================
// File        : Formal Properties for CircularBufferMulti.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Formal verification of FIFO order integrity and pointer movement.
// License     : MIT License
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
`ifdef  FORMAL
// Change direction of assumes
`define ASSERT  assert
`ifdef  CircularBufferMulti
`define ASSUME  assume
`else
`define ASSUME  assert
`endif

    ////////////////////////////////////////////////////
    //
    // f_past_valid register
    //
    ////////////////////////////////////////////////////
    reg f_past_valid;
    initial f_past_valid = 0;
    always @(posedge clock)
        f_past_valid <= 1'b1;
    always @(posedge clock)
        if(!f_past_valid)
            assume(reset);


    ////////////////////////////////////////////////////
    //
    // ASSUMPTIONS
    //
    //////////////////////////////////////////////////// 
    
    // 1. Reset must be active at t=0
    initial assume(reset);

    // 2. The queue does not underflow (cannot dequeue more than available)
    always @(*) begin
        if (!reset) begin
            // Dequeue ready signal must be less than or equal to the number of items available
            `ASSUME(io_deqReady <= io_nEnqueued); 
        end
    end

    // 3. The queue does not overflow (cannot enqueue more than space available)
    always @(*) begin
        if (!reset) begin
            // Enqueue valid signal must be less than or equal to the space available
            `ASSUME(io_enqValid <= io_nSpace);
        end
    end

    // 4. Dequeue and Enqueue widths are constrained by implementation
    always @(*) begin
        // Max dequeue is 3-wide (io_deqReady is 3 bits, but max 3 items are output/consumed)
        `ASSUME(io_deqReady <= 3'h3); 
        // Max enqueue is 4-wide (4 data ports are available, so max 4 items)
        `ASSUME(io_enqValid <= 3'h4); 
    end


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

    // The sum of io_nEnqueued and io_nSpace must always equal the depth (8).
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
    // Next Count = Previous Count + Enqueues - Dequeues
    always @(posedge clock) begin
        if(($past(f_past_valid))&&(f_past_valid)&&(!$past(reset))&&(!reset)) begin
            if ($past(io_flush)) begin
                assert(io_nEnqueued == 4'h0);
            end else begin
                // Count must follow the FIFO update logic
                assert(io_nEnqueued == $past(io_nEnqueued + {1'b0, io_enqValid} - {1'b0, io_deqReady}));
            end
        end
    end

    ////////////////////////////////////////////////////
    //
    // Contract (Data Integrity and FIFO Order)
    //
    ////////////////////////////////////////////////////   

    // Formal Memory and Pointers (High-Level Model)
    reg [31:0] f_data_mem_addr [7:0];
    reg [31:0] f_data_mem_inst [7:0];
    reg        f_data_mem_brchFwd [7:0];
    reg [2:0]  f_enqPtr;
    reg [2:0]  f_deqPtr;

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
            
            // Data 0 written to index f_enqPtr + 0
            if (io_enqValid >= 3'h1) begin 
                f_data_mem_addr[f_enqPtr + 3'h0] <= io_enqData_0_addr;
                f_data_mem_inst[f_enqPtr + 3'h0] <= io_enqData_0_inst;
                f_data_mem_brchFwd[f_enqPtr + 3'h0] <= io_enqData_0_brchFwd;
            end
            // Data 1 written to index f_enqPtr + 1
            if (io_enqValid >= 3'h2) begin
                f_data_mem_addr[f_enqPtr + 3'h1] <= io_enqData_1_addr;
                f_data_mem_inst[f_enqPtr + 3'h1] <= io_enqData_1_inst;
                f_data_mem_brchFwd[f_enqPtr + 3'h1] <= io_enqData_1_brchFwd;
            end
            // Data 2 written to index f_enqPtr + 2
            if (io_enqValid >= 3'h3) begin
                f_data_mem_addr[f_enqPtr + 3'h2] <= io_enqData_2_addr;
                f_data_mem_inst[f_enqPtr + 3'h2] <= io_enqData_2_inst;
                f_data_mem_brchFwd[f_enqPtr + 3'h2] <= io_enqData_2_brchFwd;
            end
            // Data 3 written to index f_enqPtr + 3 (Assuming max 4 wide enqueue)
            if (io_enqValid >= 3'h4) begin
                f_data_mem_addr[f_enqPtr + 3'h3] <= io_enqData_3_addr;
                f_data_mem_inst[f_enqPtr + 3'h3] <= io_enqData_3_inst;
                f_data_mem_brchFwd[f_enqPtr + 3'h3] <= io_enqData_3_brchFwd;
            end
        end
    end

    // Pointer Consistency Check
    // The formal pointers (f_enqPtr, f_deqPtr) must match the DUT's internal pointers (enqPtr, deqPtr)
    always @(*) begin
        assert (f_enqPtr == enqPtr);
        assert (f_deqPtr == deqPtr);
    end

	////////////////////////////////////////////////////
    //
    // Contract
    //
    ////////////////////////////////////////////////////

    // Data Integrity and FIFO Ordering Check
    // The output data must match the data in the formal memory at the corresponding read pointer.
    always @(*) begin
        // Slot 0 (Head of the queue)
        if (io_nEnqueued >= 4'h1) begin
            assert (io_dataOut_0_addr    == f_data_mem_addr[f_deqPtr + 3'h0]);
            assert (io_dataOut_0_inst    == f_data_mem_inst[f_deqPtr + 3'h0]);
            assert (io_dataOut_0_brchFwd == f_data_mem_brchFwd[f_deqPtr + 3'h0]);
        end

        // Slot 1 (2nd item in the queue)
        if (io_nEnqueued >= 4'h2) begin
            assert (io_dataOut_1_addr    == f_data_mem_addr[f_deqPtr + 3'h1]);
            assert (io_dataOut_1_inst    == f_data_mem_inst[f_deqPtr + 3'h1]);
            assert (io_dataOut_1_brchFwd == f_data_mem_brchFwd[f_deqPtr + 3'h1]);
        end

        // Slot 2 (3rd item in the queue)
        if (io_nEnqueued >= 4'h3) begin
            assert (io_dataOut_2_addr    == f_data_mem_addr[f_deqPtr + 3'h2]);
            assert (io_dataOut_2_inst    == f_data_mem_inst[f_deqPtr + 3'h2]);
            assert (io_dataOut_2_brchFwd == f_data_mem_brchFwd[f_deqPtr + 3'h2]);
        end

        // Slot 3 (4th item in the queue)
        if (io_nEnqueued >= 4'h4) begin
            assert (io_dataOut_3_addr    == f_data_mem_addr[f_deqPtr + 3'h3]);
            assert (io_dataOut_3_inst    == f_data_mem_inst[f_deqPtr + 3'h3]);
            assert (io_dataOut_3_brchFwd == f_data_mem_brchFwd[f_deqPtr + 3'h3]);
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

    // The buffer becomes completely full (nEnqueued == 8)
    always @(posedge clock) begin
        if (!reset) begin
            cover (io_nEnqueued == 4'h8);
        end
    end

    // The buffer is completely empty (nEnqueued == 0)
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
    
    // Cover various combinations of enqueue/dequeue
    always @(posedge clock) begin
        if (!reset) begin
            cover (io_enqValid == 3'h4 && io_deqReady == 3'h0); // 4-wide enqueue, 0 dequeue
            cover (io_enqValid == 3'h0 && io_deqReady == 3'h3 && io_nEnqueued >= 4'h3); // 0 enqueue, 3-wide dequeue
            cover (io_enqValid == 3'h2 && io_deqReady == 3'h2); // Balanced 2-wide flow
            cover (io_flush); // Cover flush activation
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
           
	// Cover write operation on low address bank (Registers 0-15)
	always @(posedge clk)
		if (!i_rst)
			if (i_ce && i_we && (i_addr <= 15))
				cover(1);

	// Cover write operation on high address bank (Registers 16-31)
	always @(posedge clk)
		if (!i_rst)
			if (i_ce && i_we && (i_addr > 15))
				cover(1);

	// Cover simultaneous active Read Enable and Chip Enable
	always @(posedge clk)
		if (!i_rst)
			if (i_ce && i_re)
				cover(1);

	// Cover that the output Chip Enable (o_ce) has been asserted high at least once
	always @(posedge clk)
		if (!i_rst)
			if (o_ce)
				cover(1);
`endif
