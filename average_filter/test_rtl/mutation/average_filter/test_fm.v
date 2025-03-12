// =============================================================================
// File        : Formal properties for average_filter.v mutations
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

`default_nettype none
`timescale 1ps/1ps

module testbench (
    input   wire    [0:0]   i_clk,
    input   wire    [0:0]   i_reset_n,
    input   wire    [0:0]   i_ce,
    input   wire    [7:0]   i_data,
    output  reg     [7:0]   o_data,
    output  reg     [0:0]   o_ce
);
    parameter DATA_WIDTH = 8;

    wire [0:0]               o_sum_ce;
    wire [(DATA_WIDTH-1):0]  o_last_sample;
    wire [(DATA_WIDTH):0]    o_sum_ff;

    // Instantiate the dut
    average_filter ref(
        .clk(i_clk),
        .reset_n(i_reset_n),
        .i_ce(i_ce),
        .data_in(i_data),
        .data_out(o_data),
        .o_ce(o_ce),
        // Whitebox testing FV
        .o_sum_ce(o_sum_ce),
        .o_last_sample(o_last_sample),
        .o_sum_ff(o_sum_ff)
        );
        
    ////////////////////////////////////////////////////
    //
    // f_past_valid register
    //
    ////////////////////////////////////////////////////
    reg	f_past_valid;
    initial	f_past_valid = 0;
        always @(posedge i_clk)
            f_past_valid <= 1'b1;
    
    // initial assume(!i_reset_n);

    ////////////////////////////////////////////////////
    //
    // Reset
    //
    ////////////////////////////////////////////////////
    always @(posedge i_clk) begin
        if(($past(f_past_valid))&&(f_past_valid)&&(!$past(i_reset_n))&&(i_reset_n)) begin
            assert(!o_ce);
            assert(o_data == 'h00);
        end
    end

    always @(posedge i_clk) begin
		if(($past(f_past_valid))&&(f_past_valid)&&(!$past(i_reset_n))&&(i_reset_n)) begin
			assert(!o_sum_ce);
			assert(o_last_sample == 'h00);
			assert(o_sum_ff == 'h00);
		end
	end

    ////////////////////////////////////////////////////
    //
    // BMC
    //
    ////////////////////////////////////////////////////
	always @(posedge i_clk) begin
		if ((f_past_valid)&&($past(i_reset_n))&&(i_reset_n)) 
		  if($past(i_ce))
			assert(o_sum_ce == 1);
	end

	always @(posedge i_clk) begin
		if ((f_past_valid)&&($past(i_reset_n))&&(i_reset_n)) 
		  if($past(o_sum_ce))
			assert(o_ce == 1);
	end

	always @(posedge i_clk) begin
		if ((f_past_valid)&&($past(i_reset_n))&&(i_reset_n)) 
		  if($past(i_ce))
			assert(o_last_sample == $past(i_data));
	end

	always @(posedge i_clk) begin
		if ((f_past_valid)&&($past(i_reset_n))&&(i_reset_n)) 
		  if($past(i_ce))
			assert(o_sum_ff == $past(i_data) + $past(o_last_sample));
	end

	always @(posedge i_clk) begin
		if ((f_past_valid)&&($past(i_reset_n))&&(i_reset_n)) 
		  if($past(o_sum_ce))
			assert(o_data == $past(o_sum_ff[8:1]));
	end

    ////////////////////////////////////////////////////
    //
    // Contract
    //
    //////////////////////////////////////////////////// 
    
    // Once a i_ce is issued, with valid data, after two clocks, o_ce must be high and o_data must be valid
    always @(posedge i_clk) begin
        if (($past(f_past_valid,2))&&($past(f_past_valid))&&(f_past_valid)&&(!$past(i_reset_n))&&(i_reset_n)) 
          if(($past(i_ce,2))&&(!$past(i_ce))) begin
            assert(o_ce);
            assert(o_data == ($past(i_data, 2) + $past(i_data, 5)));
          end
    end
                           
endmodule