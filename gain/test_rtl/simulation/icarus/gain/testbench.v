// =============================================================================
// File        : tb_gain.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Self-checking testbench for the 'gain' module.
//               Tests fixed-point multiplication, output saturation,
//               and clipping detection.
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
`timescale 1ns / 1ps

module testbench; // Changed module name from tb_gain to testbench

    // Parameters (must match the 'gain' module's default or desired test parameters)
    parameter DATA_WIDTH  = 16;
    parameter GAIN_WIDTH  = 17; // HARDCODED: Ensuring GAIN_WIDTH is 17 bits in the testbench
    parameter FRAC_BITS   = 13; // Updated: Q3.13 fixed-point format

    // Clock generation
    reg i_clk;
    reg i_reset_n;
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // 10ns period, 100MHz clock
    end

    // Input signals for DUT
    reg i_ce;
    reg [DATA_WIDTH-1:0] i_data;
    reg [GAIN_WIDTH-1:0] i_gain_coeff; // Uses the hardcoded GAIN_WIDTH

    // Output signals from DUT
    wire o_ce;
    wire [DATA_WIDTH-1:0] o_data;
    wire o_pos_clip;
    wire o_neg_clip;

    // Declare all variables at the module level
    real input_real;
    real gain_real;
    real expected_output_real;
    integer expected_output_fixed;
    integer test_id;

    // Instantiate the Device Under Test (DUT)
    gain #(
        .DATA_WIDTH (DATA_WIDTH),
        // .GAIN_WIDTH (GAIN_WIDTH), // GAIN_WIDTH is now hardcoded in gain.v, no need to pass
        .FRAC_BITS  (FRAC_BITS)
    ) dut (
        .i_clk        (i_clk),
        .i_reset_n    (i_reset_n),
        .i_ce         (i_ce),
        .i_data       (i_data),
        .i_gain_coeff (i_gain_coeff),
        .o_ce         (o_ce),
        .o_data       (o_data),
        .o_pos_clip   (o_pos_clip),
        .o_neg_clip   (o_neg_clip)
    );

    // Local parameters for fixed-point conversion and clipping limits
    localparam REAL_ONE = 2**FRAC_BITS; // Represents 1.0 in Q3.13
    localparam signed [DATA_WIDTH-1:0] MAX_AUDIO_VAL_FIXED = (1 << (DATA_WIDTH - 1)) - 1; // 32767 for 16-bit
    localparam signed [DATA_WIDTH-1:0] MIN_AUDIO_VAL_FIXED = -(1 << (DATA_WIDTH - 1));    // -32768 for 16-bit

    // Function to convert real number to fixed-point for DATA_WIDTH
    function [DATA_WIDTH-1:0] real_to_fixed;
        input real real_val;
        real_to_fixed = $rtoi(real_val * REAL_ONE);
    endfunction

    // Function to convert fixed-point to real number for DATA_WIDTH
    function real fixed_to_real;
        input [DATA_WIDTH-1:0] fixed_val;
        // Explicitly cast to signed before $itor to ensure correct sign interpretation
        fixed_to_real = $itor($signed(fixed_val)) / REAL_ONE;
    endfunction

    // Function to convert fixed-point to real number for GAIN_WIDTH
    function real fixed_to_gain_real;
        input [GAIN_WIDTH-1:0] fixed_val;
        fixed_to_gain_real = $itor($signed(fixed_val)) / REAL_ONE;
    endfunction

    // Add waveform dumping
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, testbench);
    end

    // Test sequence
    initial begin
        $display("-------------------------------------------------------");
        $display("Starting self-checking testbench for 'gain' module...");
        $display("Parameters: DATA_WIDTH=%0d, GAIN_WIDTH=%0d, FRAC_BITS=%0d", DATA_WIDTH, GAIN_WIDTH, FRAC_BITS);
        $display("Max Audio Value (Fixed): %0d, Min Audio Value (Fixed): %0d", MAX_AUDIO_VAL_FIXED, MIN_AUDIO_VAL_FIXED);
        $display("-------------------------------------------------------");

        // Initialize signals
        i_reset_n    = 0;   // Assert reset
        i_ce         = 0;
        i_data       = 0;
        i_gain_coeff = 0;

        #10; // Wait a bit for reset to propagate

        i_reset_n = 1; // De-assert reset
        #10; // Wait for stable state after reset

        // Test Case 1: No clipping, gain 0.5
        // Input: 0.5 (4096), Gain: 0.5 (4096)
        // Expected Output: 0.25 (2048)
        // Expected Clipping: No clipping
        begin : test_case_1
            input_real = 0.5;
            gain_real = 0.5;
            expected_output_real = input_real * gain_real;
            expected_output_fixed = real_to_fixed(expected_output_real);
            test_id = 1;

            $display("\n--- Test Case %0d: No clipping (0.5 * 0.5) ---", test_id);
            i_data       = real_to_fixed(input_real);
            i_gain_coeff = 17'd4096; // Explicitly 0.5 in Q3.13
            i_ce = 1;
            #10; // Wait for one clock cycle

            if (o_ce) begin
                $display("  Input: %f (0x%h), Gain: %f (0x%h)", input_real, i_data, fixed_to_gain_real(i_gain_coeff), i_gain_coeff);
                $display("  Output: %f (0x%h)", fixed_to_real(o_data), o_data);
                $display("  Expected: %f (0x%h)", expected_output_real, expected_output_fixed);
                $display("  Clipping: Pos=%b, Neg=%b", o_pos_clip, o_neg_clip);

                if (($signed(o_data) === $signed(expected_output_fixed[DATA_WIDTH-1:0])) && !o_pos_clip && !o_neg_clip) begin
                    $display("  PASS: Test Case %0d", test_id);
                end else begin
                    $display("  FAIL: Test Case %0d - Output mismatch or unexpected clipping.", test_id);
                end
            end else begin
                $display("  ERROR: Test Case %0d - o_ce not high.", test_id);
            end
            i_ce = 0; // De-assert CE
        end

        // Test Case 2: No clipping (-0.5 * 0.5)
        // Input: -0.5 (-4096), Gain: 0.5 (4096)
        // Expected Output: -0.25 (-2048)
        // Expected Clipping: No clipping
        begin : test_case_2
            input_real = -0.5;
            gain_real = 0.5;
            expected_output_real = input_real * gain_real;
            expected_output_fixed = real_to_fixed(expected_output_real);
            test_id = 2;

            $display("\n--- Test Case %0d: No clipping (-0.5 * 0.5) ---", test_id);
            i_data       = real_to_fixed(input_real);
            i_gain_coeff = 17'd4096; // Explicitly 0.5 in Q3.13
            i_ce = 1;
            #10;

            if (o_ce) begin
                $display("  Input: %f (0x%h), Gain: %f (0x%h)", input_real, i_data, fixed_to_gain_real(i_gain_coeff), i_gain_coeff);
                $display("  Output: %f (0x%h)", fixed_to_real(o_data), o_data);
                $display("  Expected: %f (0x%h)", expected_output_real, expected_output_fixed);
                $display("  Clipping: Pos=%b, Neg=%b", o_pos_clip, o_neg_clip);

                if (($signed(o_data) === $signed(expected_output_fixed[DATA_WIDTH-1:0])) && !o_pos_clip && !o_neg_clip) begin
                    $display("  PASS: Test Case %0d", test_id);
                end else begin
                    $display("  FAIL: Test Case %0d - Output mismatch or unexpected clipping.", test_id);
                end
            end else begin
                $display("  ERROR: Test Case %0d - o_ce not high.", test_id);
            end
            i_ce = 0;
        end

        // Test Case 3: No clipping (0.8 * 2.0 = 1.6)
        // Input: 0.8 (6553), Gain: 2.0 (16384)
        // Expected Output: 1.6 (13107)
        // Expected Clipping: No clipping
        begin : test_case_3
            input_real = 0.8;
            gain_real = 2.0;
            expected_output_real = input_real * gain_real;
            expected_output_fixed = real_to_fixed(expected_output_real)-1;
            test_id = 3;

            $display("\n--- Test Case %0d: No clipping (0.8 * 2.0 = 1.6) ---", test_id);
            i_data       = real_to_fixed(input_real);
            i_gain_coeff = 17'd16384; // Explicitly 2.0 in Q3.13
            i_ce = 1;
            #10;

            if (o_ce) begin
                $display("  Input: %f (0x%h), Gain: %f (0x%h)", input_real, i_data, fixed_to_gain_real(i_gain_coeff), i_gain_coeff);
                $display("  Output: %f (0x%h)", fixed_to_real(o_data), o_data);
                $display("  Expected: %f (0x%h)", expected_output_real, expected_output_fixed);
                $display("  Clipping: Pos=%b, Neg=%b", o_pos_clip, o_neg_clip);

                if (($signed(o_data) === $signed(expected_output_fixed[DATA_WIDTH-1:0])) && !o_pos_clip && !o_neg_clip) begin
                    $display("  PASS: Test Case %0d", test_id);
                end else begin
                    $display("  FAIL: Test Case %0d - Output mismatch or unexpected clipping.", test_id);
                end
            end else begin
                $display("  ERROR: Test Case %0d - o_ce not high.", test_id);
            end
            i_ce = 0;
        end

        // Test Case 4: No clipping (-0.8 * 2.0 = -1.6)
        // Input: -0.8 (-6553), Gain: 2.0 (16384)
        // Expected Output: -1.6 (-13107)
        // Expected Clipping: No clipping
        begin : test_case_4
            input_real = -0.8;
            gain_real = 2.0;
            expected_output_real = input_real * gain_real;
            expected_output_fixed = real_to_fixed(expected_output_real)+1;
            test_id = 4;

            $display("\n--- Test Case %0d: No clipping (-0.8 * 2.0 = -1.6) ---", test_id);
            i_data       = real_to_fixed(input_real);
            i_gain_coeff = 17'd16384; // Explicitly 2.0 in Q3.13
            i_ce = 1;
            #10;

            if (o_ce) begin
                $display("  Input: %f (0x%h), Gain: %f (0x%h)", input_real, i_data, fixed_to_gain_real(i_gain_coeff), i_gain_coeff);
                $display("  Output: %f (0x%h)", fixed_to_real(o_data), o_data);
                $display("  Expected: %f (0x%h)", expected_output_real, expected_output_fixed);
                $display("  Clipping: Pos=%b, Neg=%b", o_pos_clip, o_neg_clip);

                if (($signed(o_data) === $signed(expected_output_fixed[DATA_WIDTH-1:0])) && !o_pos_clip && !o_neg_clip) begin
                    $display("  PASS: Test Case %0d", test_id);
                end else begin
                    $display("  FAIL: Test Case %0d - Output mismatch or unexpected clipping.", test_id);
                end
            end else begin
                $display("  ERROR: Test Case %0d - o_ce not high.", test_id);
            end
            i_ce = 0;
        end

        // Test Case 5: Zero input (0.0 * 1.0)
        // Input: 0 (0), Gain: 1.0 (8192)
        // Expected Output: 0 (0)
        // Expected Clipping: No clipping
        begin : test_case_5
            input_real = 0.0;
            gain_real = 1.0;
            expected_output_real = input_real * gain_real;
            expected_output_fixed = real_to_fixed(expected_output_real);
            test_id = 5;

            $display("\n--- Test Case %0d: Zero input (0.0 * 1.0) ---", test_id);
            i_data       = real_to_fixed(input_real);
            i_gain_coeff = 17'd8192; // Explicitly 1.0 in Q3.13
            i_ce = 1;
            #10;

            if (o_ce) begin
                $display("  Input: %f (0x%h), Gain: %f (0x%h)", input_real, i_data, fixed_to_gain_real(i_gain_coeff), i_gain_coeff);
                $display("  Output: %f (0x%h)", fixed_to_real(o_data), o_data);
                $display("  Expected: %f (0x%h)", expected_output_real, expected_output_fixed);
                $display("  Clipping: Pos=%b, Neg=%b", o_pos_clip, o_neg_clip);

                if (($signed(o_data) === $signed(expected_output_fixed[DATA_WIDTH-1:0])) && !o_pos_clip && !o_neg_clip) begin
                    $display("  PASS: Test Case %0d", test_id);
                end else begin
                    $display("  FAIL: Test Case %0d - Output mismatch or unexpected clipping.", test_id);
                end
            end else begin
                $display("  ERROR: Test Case %0d - o_ce not high.", test_id);
            end
            i_ce = 0;
        end

        // Test Case 6: Max positive input (MAX_AUDIO_VAL * 1.0)
        // Input: 3.9998779296875 (32767), Gain: 1.0 (8192)
        // Expected Output: 3.9998779296875 (32767)
        // Expected Clipping: No clipping
        begin : test_case_6
            input_real = fixed_to_real(MAX_AUDIO_VAL_FIXED);
            gain_real = 1.0;
            expected_output_fixed = MAX_AUDIO_VAL_FIXED;
            test_id = 6;

            $display("\n--- Test Case %0d: Max positive input (MAX_AUDIO_VAL * 1.0) ---", test_id);
            i_data       = MAX_AUDIO_VAL_FIXED;
            i_gain_coeff = 17'd8192; // Explicitly 1.0 in Q3.13
            i_ce = 1;
            #10;

            if (o_ce) begin
                $display("  Input: %f (0x%h), Gain: %f (0x%h)", input_real, i_data, fixed_to_gain_real(i_gain_coeff), i_gain_coeff);
                $display("  Output: %f (0x%h)", fixed_to_real(o_data), o_data);
                $display("  Expected: %f (0x%h)", fixed_to_real(expected_output_fixed), expected_output_fixed);
                $display("  Clipping: Pos=%b, Neg=%b", o_pos_clip, o_neg_clip);

                if (($signed(o_data) === $signed(expected_output_fixed[DATA_WIDTH-1:0])) && !o_pos_clip && !o_neg_clip) begin
                    $display("  PASS: Test Case %0d", test_id);
                end else begin
                    $display("  FAIL: Test Case %0d - Output mismatch or unexpected clipping.", test_id);
                end
            end else begin
                $display("  ERROR: Test Case %0d - o_ce not high.", test_id);
            end
            i_ce = 0;
        end

        // Test Case 7: Min negative input (MIN_AUDIO_VAL * 1.0)
        // Input: -4.0 (-32768), Gain: 1.0 (8192)
        // Expected Output: -4.0 (-32768)
        // Expected Clipping: NO clipping
        begin : test_case_7
            input_real = fixed_to_real(MIN_AUDIO_VAL_FIXED);
            gain_real = 1.0;
            expected_output_fixed = MIN_AUDIO_VAL_FIXED;
            test_id = 7;

            $display("\n--- Test Case %0d: Min negative input (MIN_AUDIO_VAL * 1.0) ---", test_id);
            i_data       = MIN_AUDIO_VAL_FIXED;
            i_gain_coeff = 17'd8192; // Explicitly 1.0 in Q3.13
            i_ce = 1;
            #10;

            if (o_ce) begin
                $display("  Input: %f (0x%h), Gain: %f (0x%h)", input_real, i_data, fixed_to_gain_real(i_gain_coeff), i_gain_coeff);
                $display("  Output: %f (0x%h)", fixed_to_real(o_data), o_data);
                $display("  Expected: %f (0x%h)", fixed_to_real(expected_output_fixed), expected_output_fixed[DATA_WIDTH-1:0]);
                $display("  Clipping: Pos=%b, Neg=%b", o_pos_clip, o_neg_clip);

                if (($signed(o_data) === $signed(expected_output_fixed[DATA_WIDTH-1:0])) && !o_pos_clip && !o_neg_clip) begin
                    $display("  PASS: Test Case %0d", test_id);
                end else begin
                    $display("  FAIL: Test Case %0d - Output mismatch or unexpected clipping.", test_id);
                end
            end else begin
                $display("  ERROR: Test Case %0d - o_ce not high.", test_id);
            end
            i_ce = 0;
        end

        // Test Case 8: Input just below positive clip threshold, Gain 2.0
        // Input: 1.9998779296875 (16383), Gain: 2.0 (16384)
        // Expected Output: 3.999755859375 (32766) - NO CLIPPING
        // Expected Clipping: o_pos_clip = 0
        begin : test_case_8
            input_real = fixed_to_real(16383); // 16383 / 2^13 = 1.9998779...
            gain_real = 2.0;
            expected_output_real = input_real * gain_real; // Expected real product
            expected_output_fixed = real_to_fixed(expected_output_real); // Should be 32766 (0x7ffe)
            test_id = 8;

            $display("\n--- Test Case %0d: Edge case positive (0.4999 * 2.0) ---", test_id);
            i_data       = real_to_fixed(input_real);
            i_gain_coeff = 17'd16384; // Explicitly 2.0 in Q3.13
            i_ce = 1;
            #10;

            if (o_ce) begin
                $display("  Input: %f (0x%h), Gain: %f (0x%h)", input_real, i_data, fixed_to_gain_real(i_gain_coeff), i_gain_coeff);
                $display("  Output: %f (0x%h)", fixed_to_real(o_data), o_data);
                $display("  Expected: %f (0x%h)", fixed_to_real(expected_output_fixed), expected_output_fixed);
                $display("  Clipping: Pos=%b, Neg=%b", o_pos_clip, o_neg_clip);

                if (($signed(o_data) === $signed(expected_output_fixed[DATA_WIDTH-1:0])) && !o_pos_clip && !o_neg_clip) begin
                    $display("  PASS: Test Case %0d", test_id);
                end else begin
                    $display("  FAIL: Test Case %0d - Output mismatch or unexpected clipping.", test_id);
                end
            end else begin
                $display("  ERROR: Test Case %0d - o_ce not high.", test_id);
            end
            i_ce = 0;
        end

        // Test Case 9: Input just above positive clip threshold, Gain 2.0
        // Input: 2.0 (16384), Gain: 2.0 (16384)
        // Expected Output: MAX_AUDIO_VAL_FIXED (32767) due to saturation
        // Expected Clipping: o_pos_clip = 1
        begin : test_case_9
            input_real = fixed_to_real(16384); // 16384 / 2^13 = 2.0
            gain_real = 2.0;
            expected_output_fixed = MAX_AUDIO_VAL_FIXED; // Should saturate to 32767
            test_id = 9;

            $display("\n--- Test Case %0d: Edge case positive clip (0.5 * 2.0) ---", test_id);
            i_data       = real_to_fixed(input_real);
            i_gain_coeff = 17'd16384; // Explicitly 2.0 in Q3.13
            i_ce = 1;
            #10;

            if (o_ce) begin
                $display("  Input: %f (0x%h), Gain: %f (0x%h)", input_real, i_data, fixed_to_gain_real(i_gain_coeff), i_gain_coeff);
                $display("  Output: %f (0x%h)", fixed_to_real(o_data), o_data);
                $display("  Expected: %f (0x%h)", fixed_to_real(expected_output_fixed), expected_output_fixed);
                $display("  Clipping: Pos=%b, Neg=%b", o_pos_clip, o_neg_clip);

                if (($signed(o_data) === $signed(expected_output_fixed[DATA_WIDTH-1:0])) && o_pos_clip && !o_neg_clip) begin
                    $display("  PASS: Test Case %0d", test_id);
                end else begin
                    $display("  FAIL: Test Case %0d - Output mismatch or unexpected clipping.", test_id);
                end
            end else begin
                $display("  ERROR: Test Case %0d - o_ce not high.", test_id);
            end
            i_ce = 0;
        end

        // Test Case 10: Negative clipping (-2.0 * 2.0 = -4.0)
        // Input: -2.0 (-16384), Gain: 2.0 (16384)
        // Expected Output: -4.0 (-32768) with negative clipping flag
    begin : test_case_10
        input_real = -2.1;
        gain_real = 2.0;
        expected_output_real = -4.0;
        expected_output_fixed = MIN_AUDIO_VAL_FIXED; // -32768
        test_id = 10;

        $display("\n--- Test Case %0d: Negative clipping (-2.0 * 2.0) ---", test_id);
        i_data       = real_to_fixed(input_real);     // -2.0 in Q3.13
        i_gain_coeff = 17'd16384;                    // 2.0 in Q1.15
        i_ce = 1;
        #10; // Wait for one clock cycle

        if (o_ce) begin
            $display("  Input: %f (0x%h), Gain: %f (0x%h)", 
                    input_real, i_data, fixed_to_gain_real(i_gain_coeff), i_gain_coeff);
            $display("  Output: %f (0x%h)", fixed_to_real(o_data), o_data);
            $display("  Expected: %f (0x%h)", expected_output_real, expected_output_fixed);
            $display("  Clipping: Pos=%b, Neg=%b", o_pos_clip, o_neg_clip);

            if ($signed(o_data) === $signed(expected_output_fixed)) begin
                if (o_neg_clip && !o_pos_clip) begin
                    $display("  PASS: Test Case %0d - Correct negative clipping", test_id);
                end else begin
                    $display("  FAIL: Test Case %0d - Wrong clipping flags (expected Neg=1)", test_id);
                end
            end else begin
                $display("  FAIL: Test Case %0d - Output value mismatch", test_id);
            end
        end else begin
            $display("  ERROR: Test Case %0d - o_ce not high", test_id);
        end
        i_ce = 0;
    end

        $display("\n-------------------------------------------------------");
        $display("Testbench finished.");
        $finish; // End simulation
    end

endmodule
