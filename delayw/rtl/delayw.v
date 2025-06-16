////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	delayw.v
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	To delay an input word by a programmable number of clocks with
//		respect to a second word.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2017-2024, Gisselquist Technology, LLC
// {{{
// This file is part of the DSP filtering set of designs.
//
// The DSP filtering designs are free RTL designs: you can redistribute them
// and/or modify any of them under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation, either version 3 of
// the License, or (at your option) any later version.
//
// The DSP filtering designs are distributed in the hope that they will be
// useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
// General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with these designs.  (It's in the $(ROOT)/doc directory.  Run make
// with no target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
// }}}
// License:	LGPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/lgpl.html
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
// }}}
module delayw #(
		// {{{
		//
		// LGDLY
		// {{{
		// LGDLY is the log based two of the desired maximum delay.  It
		// is used to size the component, as this determines the memory
		// size and the number of address bits required.  As an example,
		// for a LGDLY of 4, delays between 0 and 15 samples should be
		// possible.
		parameter		LGDLY=4,
		// }}}
		// DW
		// {{{
		// DW is the data or word width of the value that needs to be
		// delayed.
		parameter		DW=12,
		// }}}
		// FIXED_DELAY
		// {{{
		// If your application requires a fixed, non-zero delay--set it
		// here.  Subsequent values in i_delay will then be ignored.
		parameter [(LGDLY-1):0]	FIXED_DELAY=0
		// }}}
		// }}}
	) (
		// {{{
		input				i_clk, i_reset,
		input	wire [(LGDLY-1):0]	i_delay,
		input	wire			i_ce,
		input	wire	[(DW-1):0]	i_word,
		output	reg	[(DW-1):0]	o_word, o_delayed
		// }}}
	);

	// Local declarations
	// {{{
	reg	[(LGDLY-1):0]	rdaddr, wraddr;
	wire	[(LGDLY-1):0]	one, two;
	reg	[(DW-1):0]	mem	[0:((1<<LGDLY)-1)];
	reg	[(DW-1):0]	memval;

	wire [(LGDLY-1):0]	w_delay;
	// }}}

	assign	w_delay = (FIXED_DELAY != 0) ? FIXED_DELAY : i_delay;

	// Some constants we'll need truncated to the right number of bits
	// later.
	assign	one   = 1;
	assign	two   = 2;
	// assign	three = 3;	// Not needed

	// wraddr
	// {{{
	// We'll write to memory, wrapping around as we go.  wraddr will contain
	// our 'write-to-memory' address.
	//
	initial	wraddr = 0;
	always @(posedge i_clk)
	if (i_ce)
		wraddr <= wraddr + 1'b1;
	// }}}

	// Write to memory
	// {{{
	// Note: this *MUST* be done simply, or the synthesizer may not
	// recognize this as a block RAM operation.  (i.e., don't put any
	// extra logic here.)
	//
	always @(posedge i_clk)
	if (i_ce)
		mem[wraddr] <= i_word;	// clock 1
	// }}}

	// rdaddr
	// {{{
	// rdaddr contains the 'read-from-memory' address.  To keep things
	// simple, we'll force rdaddr to be re-calculated on every clock based
	// upon wraddr.
	//
	initial	rdaddr = 1; // one;
	always @(posedge i_clk)
	if (i_reset)
		rdaddr <= one -w_delay;
	else if (i_ce)
		rdaddr <= wraddr + two - w_delay;
	else
		rdaddr <= wraddr + one - w_delay;
	// }}}

	//
	// Read from memory
	// {{{
	// Note: As with the always block that writes to memory, reading from
	// memory must also be done simply--or the synthesizer might choose
	// not to use block RAM.
	//
	always @(posedge i_clk)
	if (i_ce)
		memval <= mem[rdaddr];	// clock 2
	// }}}

	// o_word, o_delayed
	// {{{
	// Process the incoming data stream
	always @(posedge i_clk)
	if (i_ce)
	begin
		if (w_delay == 0)
		begin
			// If the delay is zero, forward the input to both
			// output and delayed output.
			o_word <= i_word;
			o_delayed <= i_word;
		end else if (w_delay == 1)
		begin
			// If we wish to delay by one, then the o_word value
			// works as a nice buffer to capture what once was in
			// our input.
			o_word <= i_word;
			o_delayed <= o_word;
		end else begin
			// Otherwise ... we need to go to memory to get the
			// delayed value back out.  Why 2 or more?  Count the
			// delay stages below:
			//
			//   0        1            2         3
			// i_word | o_word
			// i_word | mem[wraddr] | memval | o_delayed
			//
			o_word <= i_word;
			o_delayed <= memval;
		end
	end
	// }}}
// }}}
endmodule
