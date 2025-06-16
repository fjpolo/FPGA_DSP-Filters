// =============================================================================
// File        : Formal Properties for delayw.v
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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal properties
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

`ifdef	DELAY
	always @(*)
		if (!f_past_valid)
			assume(i_reset);

	always @(posedge i_clk)
	if ((f_past_valid)&&(!$past(i_ce)))
		assume(i_ce);
`endif

	always @(*)
		if (0 != FIXED_DELAY)
			assert(w_delay == FIXED_DELAY);

	always @(posedge i_clk)
	if (f_past_valid)
	begin
		if ($past(i_ce))
			assert(o_word == $past(i_word));
		else
			assert(o_word == $past(o_word));
	end

	reg	[LGDLY:0]	f_counts_til_valid;
	initial	f_counts_til_valid = -1;
	always @(posedge i_clk)
		if ((i_reset)||(w_delay != $past(w_delay)))
			f_counts_til_valid <= { 1'b0,  w_delay } +1'b1;
		else if (i_ce)
			f_counts_til_valid <= f_counts_til_valid - 1'b1;

	wire	f_valid_output;
	assign	f_valid_output = (f_counts_til_valid == 0);

	// Let's do an alternate form of a delay line, this time in the form
	// of a shift register.  On every clock, we'll move the shift register
	// right by one.  
	reg	[((1<<LGDLY)*DW-1):0]	shiftreg;
	initial	shiftreg = 0;
	always @(posedge i_clk)
	if (i_ce)
	begin
		shiftreg <= { {(DW){1'b0}}, shiftreg[(1<<LGDLY)*DW-1:DW] };
		shiftreg[(w_delay*DW) +: DW] <= i_word;

		if((f_valid_output)&&(f_past_valid)&&(w_delay ==$past(w_delay)))
			assert(shiftreg[DW-1:0] == o_delayed);
	end

	always @(posedge i_clk)
		if ((f_past_valid)&&(!$past(i_ce)))
		begin
			assert(o_delayed == $past(o_delayed));
			assert(o_word    == $past(o_word));
		end

	always @(posedge i_clk)
	if ((f_past_valid)&&($past(f_past_valid))
			&&($past(f_past_valid,2))
			&&($past(f_past_valid,3)))
	begin
		if ((f_valid_output)&&(w_delay == 2)
				&&(w_delay == $past(w_delay))
				&&($past(i_ce))
				&&($past(i_ce,2))
				&&($past(i_ce,3)))
			assert(o_delayed == $past(o_word,2));
	end
`endif
