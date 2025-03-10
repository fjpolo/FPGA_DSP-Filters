// =============================================================================
// File        : average_filter.v
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

module average_filter(
    input   wire                  clk,
    input   wire                  reset_n,
    input   wire                  i_ce,
    input   wire  signed  [7:0]   data_in,
    output  reg   signed  [7:0]   data_out,
    output  reg                   o_ce
  );
  
    // 
    // Pipelined CE signals
    // 

    // Pipeline signals:
    // i_ce       -> sum_ce     -> sum = past_sample + current_sample
    // sum_ce     -> o_ce       -> output = sum >>> 1
    reg [0:0] sum_ce;
    reg [0:0] shift_ce;

    // sum_ce
    always @(posedge clk) begin
      if (!reset_n) begin
        sum_ce <= 1'b0;
      end else begin
        sum_ce <= i_ce;
      end
    end

    // shift_ce
    always @(posedge clk) begin
      if (!reset_n) begin
        shift_ce <= 1'b0;
      end else begin
        shift_ce <= sum_ce;
      end
    end

    // o_ce
    always @(posedge clk) begin
      if (!reset_n) begin
        o_ce <= 1'b0;
      end else begin
        o_ce <= shift_ce;
      end
    end
    
    //
    // Pipelined data
    // 

    // Data
    reg signed [7:0] last_sample;

    // last_sample
    always @(posedge clk) begin
      if (!reset_n) begin
        last_sample <= 8'd0;
      end else begin
        if(i_ce)
          last_sample <= data_in;
      end
    end

    // data_out <= ($signed(data_in) + $signed(last_sample)) >>> 1;
    reg [8:0] sum_ff;
    reg [7:0] shift_ff;

    // Clock #0 - sum_ff
    always @(posedge clk) begin
      if (!reset_n) begin
        sum_ff <= 8'd0;
      end else begin
        if(i_ce)
          sum_ff <= data_in + last_sample;
      end
    end

    // Clock #1 - shift_ff
    always @(posedge clk) begin
      if (!reset_n) begin
        shift_ff <= 8'd0;
      end else begin
        if(sum_ce)
        data_out <= sum_ff[8:1];
      end
    end
  
  endmodule

