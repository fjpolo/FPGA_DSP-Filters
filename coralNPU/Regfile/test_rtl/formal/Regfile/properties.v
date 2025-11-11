// =============================================================================
// File        : Formal Properties for Regfile.v
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
`ifdef	Regfile
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
	always @(posedge clock)
        if (f_past_valid)
            assume(!reset);

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

	// State Tracking
	// Register file state model for R[1] (Arbitrary non-zero register)
    reg [31:0] model_r1;
    initial model_r1 = 32'h0; // Arbitrary initialization

    // Tracking registers for the 6 write ports (used for priority checking)
    reg [4:0] prev_waddr [0:5];
    reg [31:0] prev_wdata [0:5];
    reg prev_wvalid [0:5];
    
    // Update the state model for R[1] synchronously (T -> T+1)
    always @(posedge clock) begin
        if (reset) begin
            model_r1 <= 32'h0; // Reset state model
        end else begin
            // 1. Capture Write Inputs (with mask applied to ports 1, 2, 3)
            prev_waddr[0] <= io_writeData_0_bits_addr;
            prev_wdata[0] <= io_writeData_0_bits_data;
            prev_wvalid[0] <= io_writeData_0_valid;

            prev_waddr[1] <= io_writeData_1_bits_addr;
            prev_wdata[1] <= io_writeData_1_bits_data;
            prev_wvalid[1] <= io_writeData_1_valid && !io_writeMask_1_valid; // Check mask
            
            prev_waddr[2] <= io_writeData_2_bits_addr;
            prev_wdata[2] <= io_writeData_2_bits_data;
            prev_wvalid[2] <= io_writeData_2_valid && !io_writeMask_2_valid; // Check mask

            prev_waddr[3] <= io_writeData_3_bits_addr;
            prev_wdata[3] <= io_writeData_3_bits_data;
            prev_wvalid[3] <= io_writeData_3_valid && !io_writeMask_3_valid; // Check mask

            prev_waddr[4] <= io_writeData_4_bits_addr;
            prev_wdata[4] <= io_writeData_4_bits_data;
            prev_wvalid[4] <= io_writeData_4_valid;

            prev_waddr[5] <= io_writeData_5_bits_addr;
            prev_wdata[5] <= io_writeData_5_bits_data;
            prev_wvalid[5] <= io_writeData_5_valid;

            // 2. Apply Write Priority to update model_r1 (Port 0 has highest priority)
            if (prev_wvalid[0] && prev_waddr[0] == 5'h1)
                model_r1 <= prev_wdata[0];
            else if (prev_wvalid[1] && prev_waddr[1] == 5'h1)
                model_r1 <= prev_wdata[1];
            else if (prev_wvalid[2] && prev_waddr[2] == 5'h1)
                model_r1 <= prev_wdata[2];
            else if (prev_wvalid[3] && prev_waddr[3] == 5'h1)
                model_r1 <= prev_wdata[3];
            else if (prev_wvalid[4] && prev_waddr[4] == 5'h1)
                model_r1 <= prev_wdata[4];
            else if (prev_wvalid[5] && prev_waddr[5] == 5'h1)
                model_r1 <= prev_wdata[5];
        end
    end

    ////////////////////////////////////////////////////
	//
	// Contract
	//
	////////////////////////////////////////////////////   

	// P1: Register Zero ($x0$) Integrity (Must always read 0)
    genvar i;
    generate 
        for (i = 0; i <= 7; i = i + 1) begin : reg_zero_check
            always @(posedge clock) begin
                if (!reset) begin
                    if (i == 0 && io_readAddr_0_addr == 5'h0) 
                        assert(io_readData_0_data == 32'h0);
                    // if (i == 1 && io_readAddr_1_addr == 5'h0) 
                    //     assert(io_readData_1_data == 32'h0);
                    // if (i == 2 && io_readAddr_2_addr == 5'h0) 
                    //     assert(io_readData_2_data == 32'h0);
                    // if (i == 3 && io_readAddr_3_addr == 5'h0) 
                    //     assert(io_readData_3_data == 32'h0);
                    // if (i == 4 && io_readAddr_4_addr == 5'h0) 
                    //     assert(io_readData_4_data == 32'h0);
                    // if (i == 5 && io_readAddr_5_addr == 5'h0) 
                    //     assert(io_readData_5_data == 32'h0);
                    // if (i == 6 && io_readAddr_6_addr == 5'h0) 
                    //     assert(io_readData_6_data == 32'h0);
                    // if (i == 7 && io_readAddr_7_addr == 5'h0) 
                    //     assert(io_readData_7_data == 32'h0);
                end
            end
        end
    endgenerate

    // // P2: Read-After-Write Consistency (1-cycle pipeline delay)
    // // Checks that a read of R[1] in cycle T+1 (when valid) yields the data
    // // determined by the model_r1 from the previous cycle.
    // always @(posedge clock) begin
    //     if (!reset && f_past_valid) begin
    //         // Check Read Port 0
    //         if (io_readAddr_0_valid && io_readAddr_0_addr == 5'h1) begin
    //             // The data output io_readData_0_data in cycle T+1 should match 
    //             // the content of R[1] (model_r1) as of the end of cycle T.
    //             assert(io_readData_0_data == model_r1);
    //         end
    //     end
    // end

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

