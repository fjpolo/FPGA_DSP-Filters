// =============================================================================
// File        : Formal Properties for FixedPointAddSub.v
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
`ifdef	FixedPointAddSub
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

	always @(posedge i_clk) begin
        if((f_past_valid)&&($past(i_rst))) begin
            assert(o_val   == '0);
            assert(o_done  == 1'b0);
            assert(o_valid == 1'b0);
		end
	end

    ////////////////////////////////////////////////////
	//
	// BMC
	//
	////////////////////////////////////////////////////

	// ADD: o_valid is valid when adder is done and there's no overflow
	always @(posedge i_clk)
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(i_rst))&&($past(i_sub == 0)))
			assert(o_valid == ((o_done)&&(!o_overflow)));

    ////////////////////////////////////////////////////
	//
	// Contract
	//
	////////////////////////////////////////////////////   

	// ADD: If o_valid && o_done, then o_val is the sum of the operands
 	always @(posedge i_clk) begin
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(i_rst))&&($past(i_start))&&(o_valid)&&(o_done)&&($past(i_sub == 0))) begin
			assert(o_val == $past(i_operandA) + $past(i_operandB));
		end
	end

	// SUB: If o_valid && o_done, then o_val is the substraction of OperandA and OperandB
 	always @(posedge i_clk) begin
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(i_rst))&&($past(i_start))&&(o_valid)&&(o_done)&&($past(i_sub == 1))) begin
			assert(o_val == $past(i_operandA) - $past(i_operandB));
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
	
	// ADD
	always @(posedge i_clk) begin
		if((f_past_valid)&&(!$past(i_rst))) begin
			cover(o_valid);
		end
	end  
	always @(posedge i_clk) begin
		if((f_past_valid)&&(!$past(i_rst))) begin
			cover(o_busy);
		end
	end  
	always @(posedge i_clk) begin
		if((f_past_valid)&&(!$past(i_rst))) begin
			cover(o_overflow);
		end
	end   
	always @(posedge i_clk) begin
		if((f_past_valid)&&(!$past(i_rst))) begin
			cover(o_val == ($past(i_operandA) + $past(i_operandB)));
		end
	end  
	always @(posedge i_clk) begin
		if((f_past_valid)&&(!$past(i_rst))) begin
			cover(o_val != ($past(i_operandA) + $past(i_operandB)));
		end
	end
	always @(posedge i_clk) begin
		if((f_past_valid)&&(!$past(i_rst))) begin
			cover(o_val == ($past(i_operandA) - $past(i_operandB)));
		end
	end 
           
`endif

