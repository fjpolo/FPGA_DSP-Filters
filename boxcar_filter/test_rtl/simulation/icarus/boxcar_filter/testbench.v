// =============================================================================
// File        : testbench.v for boxcar_filter.v
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
`timescale 1ns/1ps

module boxcar_filter_tb;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter NUM_SAMPLES = 2;
    parameter NUM_TESTS = 8;

    // Inputs
    reg i_clk;
    reg i_reset_n;
    reg i_ce;
    reg signed [DATA_WIDTH-1:0] i_data;

    // Outputs
    wire signed [DATA_WIDTH-1:0] o_data;
    wire o_ce;

    // Instantiate the module
    boxcar_filter #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_SAMPLES(NUM_SAMPLES)
    ) dut (
        .i_clk(i_clk),
        .i_reset_n(i_reset_n),
        .i_ce(i_ce),
        .i_data(i_data),
        .o_data(o_data),
        .o_ce(o_ce)
    );

    // Clock generation
    always #5 i_clk = ~i_clk;

    // Test vectors
    reg signed [DATA_WIDTH-1:0] test_data [15:0];
    reg [3:0] test_index;

    initial begin
        // Initialize
        i_clk = 0;
        i_reset_n = 0;
        test_index = 0;

        // Test data
        test_data[0] = 1;
        test_data[1] = 2;
        test_data[2] = 3;
        test_data[3] = 4;
        test_data[4] = 5;
        test_data[5] = 6;
        test_data[6] = 7;
        test_data[7] = 8;
        test_data[8] = 9;
        test_data[9] = 10;
        test_data[10] = 11;
        test_data[11] = 12;
        test_data[12] = -1;
        test_data[13] = -2;
        test_data[14] = -3;
        test_data[15] = -4;

        // Reset
        #10;
        i_reset_n = 1;
        #10;

        // Apply test vectors and display variables
        for (test_index = 0; test_index < NUM_TESTS; test_index = test_index + 1) begin
            i_data = test_data[test_index];
            i_ce = 1;
            #10;
            i_ce = 0;
            $display("Time=%0t, index=%d, i_data=%d, i_ce=%b, o_data=%d, o_ce=%b", $time, test_index, i_data, i_ce, o_data, o_ce);
        end

        // Finish simulation
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, boxcar_filter_tb);
    end

endmodule
