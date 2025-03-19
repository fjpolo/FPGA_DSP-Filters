// =============================================================================
// File        : boxcar_filter.v
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

`default_nettype none
`timescale 1ps/1ps

module boxcar_filter #(
    parameter DATA_WIDTH = 8,
    parameter NUM_SAMPLES = 2,
    parameter INDEX_WIDTH = $clog2(NUM_SAMPLES)
) (
    input   wire    [0:0]               i_clk,
    input   wire    [0:0]               i_reset_n,
    input   wire    [0:0]               i_ce,
    input   signed  [DATA_WIDTH-1:0]    i_data,
    output  signed  [(DATA_WIDTH + $clog2(NUM_SAMPLES) - 1):0]    o_data,
    output  wire    [0:0]               o_ce,
    // Whitebox testing
    output wire o_valid_reg,
    output wire [(DATA_WIDTH + INDEX_WIDTH - 1):0] o_accumulator,
    output wire [(INDEX_WIDTH+1):0] o_sample_index
);

    localparam MAX_INDEX = NUM_SAMPLES;

    reg [(INDEX_WIDTH+1):0] oldest_sample_index;
    reg [(INDEX_WIDTH+1):0] sample_index;
    reg signed [(DATA_WIDTH + INDEX_WIDTH):0] accumulator;
    reg signed [DATA_WIDTH-1:0] sample_buffer [NUM_SAMPLES:0];
    reg valid_reg;
    reg i_ce_ff;
    reg output_is_valid;

    // Helper wires
    wire oldest_sample_index_is_max;
    wire sample_index_is_max;
    assign sample_index_is_max = (sample_index == MAX_INDEX);
    assign oldest_sample_index_is_max = (oldest_sample_index == MAX_INDEX);

    initial begin
        oldest_sample_index = -NUM_SAMPLES;
        sample_index = 0;
        output_is_valid = 0;
        accumulator = 0;
        valid_reg = 1'b0;
        i_ce_ff = 1'b0;
    end

    // i_ce_ff
    always @(posedge i_clk)
        if(!i_reset_n)
            i_ce_ff <= 1'b0;
        else
            i_ce_ff <= i_ce;

    // oldest_sample_index
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            oldest_sample_index <= -NUM_SAMPLES;
        end else if(i_ce) begin
            if (oldest_sample_index_is_max) begin
                oldest_sample_index <= 0;
            end else begin
                oldest_sample_index <= oldest_sample_index + 1;
            end
        end
    end  

    // sample_index
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            sample_index <= 0;
        end else if(i_ce) begin
            if (sample_index_is_max) begin
                sample_index <= 0;
            end else begin
                sample_index <= sample_index + 1;
            end
        end
    end

    // output_is_valid
    always @(posedge i_clk)
        if(!i_reset_n)
            output_is_valid = 0;
        else if(sample_index_is_max)
            output_is_valid <= 1'b1;

    // valid_reg
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            valid_reg <= 1'b0;
        end else begin
            valid_reg <= (sample_index_is_max)&&(i_ce);
        end
    end

    // accumulator
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            accumulator <= 0;
        end else if(i_ce) begin
            if (output_is_valid) begin
                accumulator <= accumulator - sample_buffer[oldest_sample_index] + i_data;
            end else begin
                accumulator <= accumulator + i_data;
            end
        end
    end

    // sample_buffer
    always @(posedge i_clk) begin
        if(i_ce) begin
            sample_buffer[sample_index] <= i_data;
        end
    end

    assign o_data = accumulator >>> INDEX_WIDTH;
    assign o_ce = (output_is_valid)&&(i_ce_ff);
    assign o_valid_reg = valid_reg;
    assign o_sample_index = sample_index;
    assign o_accumulator = accumulator;

endmodule