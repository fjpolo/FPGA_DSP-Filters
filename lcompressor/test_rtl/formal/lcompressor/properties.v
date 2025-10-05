// =============================================================================
// File        : Formal Properties for lcompressor.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Basic linear compressor - Formal Properties
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
`ifdef	lcompressor
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

	always @(posedge i_clk)
		if(!f_past_valid)
			assume(!i_reset_n);

    ////////////////////////////////////////////////////
	//
	// Reset
	//
	////////////////////////////////////////////////////

	// o_data: Output must be zero immediately after reset
    always @(posedge i_clk) begin
        if (($past(!i_reset_n)&&(f_past_valid))) begin
            assert(o_data == 'h0);
        end
    end

	// r_lin_env_2: Envelope state must be zero after reset
    always @(posedge i_clk) begin
        if (($past(!i_reset_n)&&(f_past_valid))) begin
            // r_lin_env_2 is the key internal state for the envelope
            assert(r_lin_env_2 == 'h0);
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

	// o_ce: must be high 4 clocks after i_ce is high
	always @(posedge i_clk) begin
		if(
			($past(f_past_valid,4))&&($past(i_reset_n,4))&&
			($past(f_past_valid,3))&&($past(i_reset_n,3))&&
			($past(f_past_valid,2))&&($past(i_reset_n,2))&&
			($past(f_past_valid))&&($past(i_reset_n))&&
			(f_past_valid)&&(i_reset_n)
		) begin
			if($past(i_ce, 4))
				assert(o_ce);
		end
	end

	// i_data must not exceed full scale
    // The design handles saturation, but this assumes valid input
    always @(*)
		assert($signed(i_data) >= -(1 << (W_TOTAL - 1)));
    always @(*)
    	assert($signed(i_data) <= (1 << (W_TOTAL - 1)) - 1);	

    ////////////////////////////////////////////////////
	//
	// Induction
	//
	////////////////////////////////////////////////////

	// Output must never exceed the maximum positive value (No Clipping/Overflow)
    always @(posedge i_clk) begin
        if ((f_past_valid) && (i_reset_n) && (o_ce)) begin
            assert($signed(o_data) <= (1 << (W_TOTAL - 1)) - 1);
        end
    end

	// Output must never exceed the maximum negative value (No Clipping/Overflow)
    always @(posedge i_clk) begin
        if ((f_past_valid) && (i_reset_n) && (o_ce)) begin
            assert($signed(o_data) >= -(1 << (W_TOTAL - 1)));
        end
    end
    
	////////////////////////////////////////////////////
	//
	// Cover
	//
	////////////////////////////////////////////////////     
	
	// o_ce
	always @(posedge i_clk) begin
		if((f_past_valid)&&(i_reset_n)&&(i_ce))
			cover(o_ce);
	end
           
`endif

