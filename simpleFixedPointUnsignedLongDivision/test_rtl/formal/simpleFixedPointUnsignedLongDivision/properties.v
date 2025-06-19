// =============================================================================
// File        : Formal Properties for simpleFixedPointUnsignedLongDivision.v
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
`ifdef	simpleFixedPointUnsignedLongDivision
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
			assert(o_busy  == 0);
            assert(o_done  == 0);
            assert(o_valid == 0);
            assert(o_dbz   == 0);
            assert(o_ovf   == 0);
            assert(o_val   == 0);
		end
	end

    ////////////////////////////////////////////////////
	//
	// BMC
	//
	////////////////////////////////////////////////////

	// i_start
	always @(posedge i_clk) begin
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(i_rst))&&(!i_rst)) begin
			if($past(i_start)) begin
				if ($past(b) == 0) begin
					assert(o_busy == 0);
                	assert(o_done == 1);
                	assert(o_dbz  == 1);
				end
				else begin
					assert(o_busy     == 1);
					assert(o_dbz      == 0);
					assert(b1         == $past(b));
					assert({acc, quo} == {{WIDTH{1'b0}}, $past(a), 1'b0});	
				end
			end
		end
	end

	// o_busy
	always @(posedge i_clk) begin
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(i_rst))&&(!i_rst)) begin
			if(
				($past(i_start,2))&&(!$past(i_start))&&(!i_start)&&
				($past(o_busy))
			  ) begin
				if ($past(i) == ITER-1) begin
					assert(o_busy  == 0);
					assert(o_done  == 1);
					assert(o_valid == 1);
					assert(o_val   == $past(quo_next));
				end	
				else if (($past(i) == (WIDTH-1))&&($past(quo_next[WIDTH-1:WIDTH-FBITSW]) != 0)) begin  // overflow?
					assert(o_busy == 0);
					assert(o_done == 1);
					assert(o_ovf  == 1);
					assert(o_val  == 0);
            	end			
				else begin 
					assert(i   == ($past(i) + 1));
					assert(acc == $past(acc_next));
					assert(quo == $past(quo_next));
            	end
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
           
`endif

