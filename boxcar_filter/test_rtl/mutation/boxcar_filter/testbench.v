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

module boxcar_filter_tb();

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter NUM_SAMPLES = 32;
    parameter NUM_TESTS = 64; // Increased to 64
    parameter INDEX_WIDTH = $clog2(NUM_SAMPLES);
    parameter MAX_INDEX = NUM_SAMPLES - 1;
    parameter CLOCK_PERIOD = 10;


    // Inputs
    reg i_clk;
    reg i_reset_n;
    reg i_ce;
    reg signed [DATA_WIDTH-1:0] i_data;

    // Outputs
    wire signed [(DATA_WIDTH + $clog2(NUM_SAMPLES) - 1):0] o_data;
    wire o_ce;

    // Whitebox testing
    wire o_valid_reg;
    wire [(DATA_WIDTH + INDEX_WIDTH - 1):0] o_accumulator;
    wire [INDEX_WIDTH-1:0] o_sample_index;

    // Instantiate the module
`ifdef MCY
    boxcar_filter dut (
        .i_clk(i_clk),
        .i_reset_n(i_reset_n),
        .i_ce(i_ce),
        .i_data(i_data),
        .o_data(o_data),
        .o_ce(o_ce),
        // Whitebox testing
        .o_valid_reg(o_valid_reg),
        .o_accumulator(o_accumulator),
        .o_sample_index(o_sample_index)
    );
`else
    boxcar_filter #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_SAMPLES(NUM_SAMPLES),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_reset_n(i_reset_n),
        .i_ce(i_ce),
        .i_data(i_data),
        .o_data(o_data),
        .o_ce(o_ce),
        // Whitebox testing
        .o_valid_reg(o_valid_reg),
        .o_accumulator(o_accumulator),
        .o_sample_index(o_sample_index)
    );
`endif
    // Clock generation
    always #5 i_clk = ~i_clk;

    // Test vectors
    reg signed [DATA_WIDTH-1:0] test_data [63:0]; // Increased to 63:0
    reg [6:0] test_index; // Increased to 6:0
    reg [31:0] pass_count;
    reg [31:0] fail_count;
    reg [31:0] error_count;
    integer valid_index;

    reg signed [(2*DATA_WIDTH):0] expected_result [63:0];
    integer i, j;


    initial begin
        // Initialize
        i_clk = 0;
        i_reset_n = 0;
        test_index = 0;
        pass_count = 0;
        fail_count = 0;
        error_count = 0;
        valid_index = NUM_SAMPLES + 1;

        // Test data (example vectors, you can customize these)
        for (test_index = 0; test_index < NUM_TESTS; test_index = test_index + 1) begin
            test_data[test_index] = 2 * test_index; // Example: 1, 2, 3, ...
        end

        // expected_result
        for (i = 0; i < (63 - NUM_SAMPLES + 2); i = i + 1) begin
            expected_result[i] = 0;
            for (j = i; j < (i+NUM_SAMPLES); j = j + 1) begin
                expected_result[i] = expected_result[i] + test_data[j];
                // $display("    test_data[%d]=%d", j, test_data[j]);
            end
            expected_result[i] = expected_result[i] >>> INDEX_WIDTH;
            // $display("expected_result[%d]=%d", i, expected_result[i]);
        end


        // Reset
        #CLOCK_PERIOD;
        i_reset_n = 1;
        #CLOCK_PERIOD;

        // Apply test vectors and check results
        for (test_index = 0; test_index < NUM_TESTS; test_index = test_index + 1) begin
            i_data = test_data[test_index];
            i_ce = 1;
            #CLOCK_PERIOD;

            $display("Time=%0t, index=%d, i_reset_n=%d, i_data=%d, i_ce=%b, o_valid_reg=%d, o_sample_index=%d, o_accumulator=%d, o_data=%d, expected=%d, o_ce=%b", $time, test_index, i_reset_n, i_data, i_ce, o_valid_reg, o_sample_index, o_accumulator,o_data, expected_result[test_index-NUM_SAMPLES+1], o_ce);
            if (test_index >= valid_index) begin : test
                if (o_data == expected_result[test_index-NUM_SAMPLES+1]) begin
                    $display("PASS: index=%d, i_data=%d, o_data=%d, expected=%d", test_index, i_data, o_data, expected_result[test_index-NUM_SAMPLES+1]);
                    pass_count = pass_count + 1;
                end else begin
                    // $display("FAIL: index=%d, i_data=%d, o_data=%d, expected=%d", test_index, i_data, o_data, expected_result);
                    fail_count = fail_count + 1;
                    if (fail_count > 100) begin
                        $display("ERROR: Too many failures");
                        error_count = error_count + 1;
                        $finish;
                    end
                end
            end
        end

        // Report results
        $display("--------------------");
        $display("Test Results:");
        $display("PASS: %d", pass_count);
        $display("FAIL: %d", fail_count);
        $display("ERROR: %d", error_count);
        $display("--------------------");

        if (fail_count == 0 && error_count == 0) begin
            $display("TEST PASSED");
            $finish;
        end else begin
            $display("TEST FAILED");
            $finish;
        end
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, boxcar_filter_tb);
    end

endmodule