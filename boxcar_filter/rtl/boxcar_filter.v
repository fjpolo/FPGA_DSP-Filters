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

module boxcar_filter #(
    parameter DATA_WIDTH = 8,
    parameter NUM_SAMPLES = 8
) (
    input   wire    [0:0]               i_clk,
    input   wire    [0:0]               i_reset_n,
    input   wire    [0:0]               i_ce,
    input   signed  [DATA_WIDTH-1:0]    i_data,
    output  signed  [DATA_WIDTH-1:0]    o_data,
    output  wire    [0:0]               o_ce
);

    localparam INDEX_WIDTH = $clog2(NUM_SAMPLES);
    localparam MAX_INDEX = NUM_SAMPLES - 1;

    reg [INDEX_WIDTH-1:0] sample_index;
    reg signed [(DATA_WIDTH + (INDEX_WIDTH-1)):0] accumulator;
    integer i;

    // Helper wires
    wire sample_index_is_max;
    /* verilator lint_off WIDTHEXPAND */
    assign sample_index_is_max = (sample_index == MAX_INDEX);
    /* verilator lint_on WIDTHEXPAND */

    // valid_reg
    reg valid_reg;
    initial valid_reg = 1'b0;
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            valid_reg <= 1'b0;
        end else begin
            if(i_ce) begin
                if (sample_index_is_max)
                    valid_reg <= 1'b1;
                else
                    valid_reg <= 1'b0;
            end
        end
    end

    // sample_index
    initial sample_index = 'h00;
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            sample_index <= 0;
        end else begin
            if(i_ce) begin
                if (sample_index_is_max)
                    sample_index <= 0;
                else
                    sample_index <= sample_index + 1;
            end
        end
    end

    // sample_buffer memory
    reg signed [DATA_WIDTH-1:0] sample_buffer [NUM_SAMPLES-1:0];
    initial begin
        for (i = 0; i < NUM_SAMPLES; i = i + 1) begin
            sample_buffer[i] = 0;
        end
    end
    always @(posedge i_clk) begin
        if(i_ce)
            sample_buffer[sample_index] <= i_data;
    end

    // accummulator
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            accumulator <= 0;
        end else if (i_ce) begin
            for (i = 0; i < NUM_SAMPLES; i = i + 1) begin
                accumulator <= accumulator + { {INDEX_WIDTH{sample_buffer[i][DATA_WIDTH-1]}}, sample_buffer[i] };
            end
        end
    end

    assign o_data = accumulator[DATA_WIDTH + INDEX_WIDTH - 1:INDEX_WIDTH];
    assign o_ce = valid_reg;

endmodule
