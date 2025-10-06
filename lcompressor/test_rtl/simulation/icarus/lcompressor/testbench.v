// =============================================================================
// File        : testbench.v for lcompressor.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Basic linear compressor - Self-Checking testbench
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

module testbench;

    localparam CLK_HALF = 5;
    localparam CLK_FULL = 10;

    reg test1_done = 0;
    reg test2a_done = 0;
    reg test2b_done = 0;
    reg test2c_done = 0;

    // --- UUT Parameters ---
    localparam W_TOTAL = 16;
    localparam W_FRAC = 15;
    localparam THRESHOLD_LIN = 16'h4000; // 0.5 in Q1.15
    localparam NEG_THRESHOLD_LIN = -(THRESHOLD_LIN); // -0.5

    // --- Testbench Signals (Inputs to UUT) ---
    reg  i_clk;
    reg  i_reset_n;
    reg  i_ce;
    reg  signed [W_TOTAL-1:0] i_data;

    // --- Testbench Signals (Outputs from UUT) ---
    wire signed [W_TOTAL-1:0] o_data;
    wire o_ce;

    // --- Test Variables ---
    integer test_count = 0;
    integer errors = 0;

    // Instantiate the Unit Under Test (UUT)
    lcompressor #(
        .W_TOTAL(W_TOTAL),
        .THRESHOLD_LIN(THRESHOLD_LIN)
    ) uut (
        .i_clk      (i_clk),
        .i_reset_n  (i_reset_n),
        .i_ce       (i_ce),
        .i_data     (i_data),
        .o_data     (o_data),
        .o_ce       (o_ce)
    );

    // Clock generation
    initial begin
        i_clk = 1;
        forever #CLK_HALF i_clk = ~i_clk; // 10ps clock period
    end

    // Waveform dumping
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, testbench);
    end

    // --- Test sequence ---
    initial begin
        $display("-------------------------------------------------------");
        $display("Starting Self-Checking Testbench for hclipper (1-Stage)");
        $display("Threshold = %h (Q1.15)", THRESHOLD_LIN);
        $display("-------------------------------------------------------");

        // --- 1. Reset Test (Test 1) ---
        i_reset_n = 1'b0;
        i_ce = 1'b0;
        i_data = {W_TOTAL{1'b1}}; // Max negative value during reset

        #CLK_FULL;
        
        test_count = 1; // Manually track the initial reset test
        if (o_data !== {W_TOTAL{1'b0}} || o_ce !== 1'b0) begin
            $display("FAIL: Test %d (Initial Reset) failed. o_data=%h, o_ce=%b", test_count, o_data, o_ce);
            errors = errors + 1;
        end else begin
            $display("PASS: Test %d (Initial Reset) successful.", test_count);
        end
        test_count = 0; // Reset counter, task will increment from 1

        // De-assert reset
        i_reset_n = 1'b1;
        #CLK_FULL;
        test1_done <= 1;

        // Check some values
        i_ce = 1;
        i_data = 'h5000;
        #CLK_FULL;
        test_count = test_count + 1;
        i_ce = 0;
        #CLK_FULL;
        if ((o_ce)&&(o_data !== THRESHOLD_LIN)) begin
            $display("FAIL: Test %d failed. o_data=%h should be %h, o_ce=%b", test_count, o_data, THRESHOLD_LIN, o_ce);
            errors = errors + 1;
        end else begin
            $display("PASS: Test %d (upper bounds) successful.", test_count);
        end

        test_count = test_count + 1;
        i_ce = 1;
        i_data = (0-1);
        #CLK_FULL;
        i_ce = 0;
        #CLK_FULL;
        if ((o_ce)&&(o_data !== NEG_THRESHOLD_LIN)) begin
            $display("FAIL: Test %d failed. o_data=%h should be %h, o_ce=%b", test_count, o_data, NEG_THRESHOLD_LIN, o_ce);
            errors = errors + 1;
        end else begin
            $display("PASS: Test %d (lower bounds) successful.", test_count);
        end
        
        test_count = test_count + 1;
        i_ce = 1;
        i_data = 'h2000;
        #CLK_FULL;
        i_ce = 0;
        #CLK_FULL;
        if ((o_ce)&&(o_data !== 'h2000)) begin
            $display("FAIL: Test %d failed. o_data=%h, o_ce=%b", test_count, o_data, o_ce);
            errors = errors + 1;
        end else begin
            $display("PASS: Test %d (within bounds) successful.", test_count);
        end
        
        // --- Final Summary ---
        $display("-------------------------------------------------------");
        if (errors == 0) begin
            $display("PASS: All %0d tests passed.", test_count);
        end else begin
            $display("FAIL: %0d / %0d tests failed.", errors, test_count);
            $display("ERROR: The simulation encountered %0d errors.", errors);
        end
        $display("-------------------------------------------------------");
        
        $finish;
    end

    // Monitor for errors (Timeout)
    initial begin
      #500; // Timeout after 500ps
        $display("ERROR: Simulation timed out.");
        $finish;
    end

endmodule
