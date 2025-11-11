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

	always @(posedge clock) begin
		if(($past(f_past_valid))&&(f_past_valid)&&($past(reset))&&(!reset)) begin
			assert(regfile_1 == 32'h0);
			assert(regfile_2 == 32'h0);
			assert(regfile_3 == 32'h0);
			assert(regfile_4 == 32'h0);
			assert(regfile_5 == 32'h0);
			assert(regfile_6 == 32'h0);
			assert(regfile_7 == 32'h0);
			assert(regfile_8 == 32'h0);
			assert(regfile_9 == 32'h0);
			assert(regfile_10 == 32'h0);
			assert(regfile_11 == 32'h0);
			assert(regfile_12 == 32'h0);
			assert(regfile_13 == 32'h0);
			assert(regfile_14 == 32'h0);
			assert(regfile_15 == 32'h0);
			assert(regfile_16 == 32'h0);
			assert(regfile_17 == 32'h0);
			assert(regfile_18 == 32'h0);
			assert(regfile_19 == 32'h0);
			assert(regfile_20 == 32'h0);
			assert(regfile_21 == 32'h0);
			assert(regfile_22 == 32'h0);
			assert(regfile_23 == 32'h0);
			assert(regfile_24 == 32'h0);
			assert(regfile_25 == 32'h0);
			assert(regfile_26 == 32'h0);
			assert(regfile_27 == 32'h0);
			assert(regfile_28 == 32'h0);
			assert(regfile_29 == 32'h0);
			assert(regfile_30 == 32'h0);
			assert(regfile_31 == 32'h0);
			assert(scoreboard == 32'h0);
			assert(readDataReady_0 == 1'h0);
			assert(readDataReady_1 == 1'h0);
			assert(readDataReady_2 == 1'h0);
			assert(readDataReady_3 == 1'h0);
			assert(readDataReady_4 == 1'h0);
			assert(readDataReady_5 == 1'h0);
			assert(readDataReady_6 == 1'h0);
			assert(readDataReady_7 == 1'h0);
			assert(readDataBits_0 == 32'h0);
			assert(readDataBits_1 == 32'h0);
			assert(readDataBits_2 == 32'h0);
			assert(readDataBits_3 == 32'h0);
			assert(readDataBits_4 == 32'h0);
			assert(readDataBits_5 == 32'h0);
			assert(readDataBits_6 == 32'h0);
			assert(readDataBits_7 == 32'h0);
			assert(write_fail == 1'h0);
			assert(write_fail_1 == 1'h0);
			assert(write_fail_2 == 1'h0);
			assert(write_fail_3 == 1'h0);
			assert(write_fail_4 == 1'h0);
			assert(write_fail_5 == 1'h0);
			assert(write_fail_6 == 1'h0);
			assert(write_fail_7 == 1'h0);
			assert(write_fail_8 == 1'h0);
			assert(write_fail_9 == 1'h0);
			assert(write_fail_10 == 1'h0);
			assert(write_fail_11 == 1'h0);
			assert(write_fail_12 == 1'h0);
			assert(write_fail_13 == 1'h0);
			assert(write_fail_14 == 1'h0);
			assert(scoreboard_error == 1'h0);
		end
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

