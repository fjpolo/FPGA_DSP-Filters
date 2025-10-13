// =============================================================================
// File        : testbench.v for FixedPointAddSub.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Self-checking testbench for the FixedPointAddSub module.
//               Verifies addition, signed saturation, and overflow detection
//               across various input scenarios including normal operation,
//               positive overflow, and negative overflow. It uses a helper
//               task for repetitive test case execution and includes pass/fail
//               messaging for automated regression.
// License     : MIT License
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
`define MCY

module testbench;

    // Define the WIDTH parameter for the UUT (Unit Under Test)
    localparam WIDTH = 8; // Matching the default WIDTH of FixedPointAddSub
    // Define the maximum width for the test name string in bits (64 chars * 8 bits)
    localparam TEST_NAME_WIDTH = 8*64;

    // Inputs to the UUT
    reg         i_clk;
    reg         i_rst;      // Active high reset for FixedPointAddSub
    reg         i_start;
    reg         i_sub;
    reg signed [WIDTH-1:0] i_operandA;
    reg signed [WIDTH-1:0] i_operandB;

    // Outputs from the UUT
    wire        o_busy;
    wire        o_done;
    wire        o_valid;
    wire        o_overflow;
    wire signed [WIDTH-1:0] o_val; // NOTE: Standardized output name to o_val

    // Temporary variables for task arguments, declared at the module level for broader compatibility
    reg signed [WIDTH-1:0] temp_opA;
    reg signed [WIDTH-1:0] temp_opB;
    reg signed [WIDTH-1:0] temp_expected_val;
    reg                    temp_expected_overflow; 

    // Instantiate the Unit Under Test (UUT)
    // Pass parameters to the UUT instance
`ifdef MCY
    FixedPointAddSub uut (
            .i_clk      (i_clk),
            .i_rst      (i_rst),
            .i_start    (i_start),
            .i_sub      (i_sub),
            .i_operandA (i_operandA),
            .i_operandB (i_operandB),
            .o_busy     (o_busy),
            .o_done     (o_done),
            .o_valid    (o_valid),
            .o_overflow (o_overflow),
            .o_data      (o_val) // Changed .o_val to .o_data to match module port list, connected to o_val wire
        );
`else
    FixedPointAddSub #(
        .WIDTH(WIDTH),
        .FBITS(4) // FBITS is not used in adder logic but kept for consistency
        ) uut (
            .i_clk      (i_clk),
            .i_rst      (i_rst),
            .i_start    (i_start),
            .i_operandA (i_operandA),
            .i_operandB (i_operandB),
            .i_sub      (i_sub),
            .o_busy     (o_busy),
            .o_done     (o_done),
            .o_valid    (o_valid),
            .o_overflow (o_overflow),
            .o_data      (o_val) // Changed .o_val to .o_data to match module port list, connected to o_val wire
        );
`endif
            
    // Define constants for WIDTH=8 signed numbers
    localparam signed [WIDTH-1:0] MAX_8_BIT_SIGNED = 8'd127; // 0x7F
    localparam signed [WIDTH-1:0] MIN_8_BIT_SIGNED = 8'h80;  // Represents -128 (using hex for compatibility)

    // Clock generation: 10ps period (5ps high, 5ps low)
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    // Waveform dumping for debugging with tools like GTKWave
    initial begin
        $dumpfile("dump.vcd"); // Specify the waveform file name
        $dumpvars(0, testbench); // Dump all signals in the testbench module
    end

    // Helper task to apply inputs and check outputs after one clock cycle
    // The FixedPointAddSub has 1-cycle latency, meaning outputs are registered
    // and appear on the clock edge *after* i_start is asserted.
    task do_add_check;
        input signed [WIDTH-1:0] opA;
        input signed [WIDTH-1:0] opB;
        input signed [WIDTH-1:0] expected_val;
        input reg expected_overflow; // FIXED: Changed 'logic' to 'reg'
        input [TEST_NAME_WIDTH-1:0] test_name; // FIXED: Changed 'string' to wide 'reg'
        begin
            $display("\n--------------------------------------------------------------------------------");
            $display("TEST: %s", test_name);
            $display("Applying i_operandA = %0d (0x%h), i_operandB = %0d (0x%h)", opA, opA, opB, opB);

            // Apply inputs
            i_sub = 1'b0; // Set mode to Add
            i_operandA = opA;
            i_operandB = opB;
            i_start    = 1'b1; // Assert start for one cycle

            #(10)// Wait for the clock edge where inputs are registered and computation starts
            i_start    = 1'b0; // De-assert start (pulse i_start)

            // Check outputs (using module output wires: o_done, o_valid, o_busy, o_val, o_overflow)
            if (o_done === 1'b1 && o_valid === (expected_overflow ? 1'b0 : 1'b1) && o_busy === 1'b1) begin
                if (o_val === expected_val && o_overflow === expected_overflow) begin
                    $display("PASS: %s. Result: %0d (0x%h), Overflow: %b. Expected: %0d (0x%h), Overflow: %b",
                             test_name, o_val, o_val, o_overflow, expected_val, expected_val, expected_overflow);
                end else begin
                    $display("FAIL: %s. Mismatch! Result: %0d (0x%h), Overflow: %b. Expected: %0d (0x%h), Overflow: %b",
                             test_name, o_val, o_val, o_overflow, expected_val, expected_val, expected_overflow);
                    $finish; // Terminate simulation on failure
                end
            end else begin
                $display("FAIL: %s. Handshake failed! o_done=%b, o_valid=%b, o_busy=%b. Expected 1, %b, 1.",
                         test_name, o_done, o_valid, o_busy, (expected_overflow ? 1'b0 : 1'b1));
                $finish; // Terminate simulation on failure
            end
            #10; // Small delay to let signals settle before next test setup
        end
    endtask

    task do_sub_check;
        input signed [WIDTH-1:0] opA;
        input signed [WIDTH-1:0] opB;
        input signed [WIDTH-1:0] expected_val;
        input reg expected_overflow; // FIXED: Changed 'logic' to 'reg'
        input [TEST_NAME_WIDTH-1:0] test_name; // FIXED: Changed 'string' to wide 'reg'
        begin
            $display("\n--------------------------------------------------------------------------------");
            $display("TEST: %s", test_name);
            $display("Applying i_operandA = %0d (0x%h), i_operandB = %0d (0x%h)", opA, opA, opB, opB);

            // Apply inputs
            i_sub = 1'b1; // Set mode to Sub
            i_operandA = opA;
            i_operandB = opB;
            i_start    = 1'b1; // Assert start for one cycle

            #(10)// Wait for the clock edge where inputs are registered and computation starts
            i_start    = 1'b0; // De-assert start (pulse i_start)

            // Check outputs (using module output wires: o_done, o_valid, o_busy, o_val, o_overflow)
            // NOTE: Removed references to uut.result_extended and fixed output signal name to o_val
            if (o_done === 1'b1 && o_valid === (expected_overflow ? 1'b0 : 1'b1) && o_busy === 1'b1) begin
                if (o_val === expected_val && o_overflow === expected_overflow) begin
                    $display("PASS: %s. Result: %0d (0x%h), Overflow: %b. Expected: %0d (0x%h), Overflow: %b",
                             test_name, o_val, o_val, o_overflow, expected_val, expected_val, expected_overflow);
                end else begin
                    $display("FAIL: %s. Mismatch! Result: %0d (0x%h), Overflow: %b. Expected: %0d (0x%h), Overflow: %b",
                             test_name, o_val, o_val, o_overflow, expected_val, expected_val, expected_overflow);
                    $finish; // Terminate simulation on failure
                end
            end else begin
                $display("FAIL: %s. Handshake failed! o_done=%b, o_valid=%b, o_busy=%b. Expected 1, %b, 1.",
                         test_name, o_done, o_valid, o_busy, (expected_overflow ? 1'b0 : 1'b1));
                $finish; // Terminate simulation on failure
            end
            #10; // Small delay to let signals settle before next test setup
        end
    endtask

    // Main test sequence
    initial begin
        // Initialize inputs to safe values
        i_rst      = 1'b1; // Assert reset
        i_start    = 1'b0;
        i_operandA = '0;
        i_operandB = '0;
        i_sub = 'b0;    

        // Reset phase
        #10; // Wait a little for reset to settle
        $display("Applying Reset...");
        i_rst = 1'b0; // De-assert reset
        #10; // Wait another clock cycle after reset de-assertion
        $display("Reset De-asserted.");

        // Check reset state (should be all zeros for outputs)
        if (o_val !== '0 || o_done !== 1'b0 || o_valid !== 1'b0 ||
            o_overflow !== 1'b0 || o_busy !== 1'b0) begin
            $display("FAIL: Reset state incorrect. o_val=0x%h, o_done=%b, o_valid=%b, o_overflow=%b, o_busy=%b",
                     o_val, o_done, o_valid, o_overflow, o_busy);
            $finish;
        end else begin
            $display("PASS: Initial reset state is correct.");
        end

        // Test Cases:

        /* ADD */

            // Test 1: Normal addition (positive)
            temp_opA = 8'd5;
            temp_opB = 8'd3;
            temp_expected_val = 8'd8;
            temp_expected_overflow = 1'b0;
            do_add_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Normal Positive Addition (5 + 3)");

            // Test 2: Normal addition (negative)
            temp_opA = 8'hFB; // -5
            temp_opB = 8'hFD; // -3
            temp_expected_val = 8'hF8; // -8
            temp_expected_overflow = 1'b0;
            do_add_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Normal Negative Addition (-5 + -3)");

            // Test 3: Normal addition (mixed signs)
            temp_opA = 8'd10;
            temp_opB = 8'hF1; // -15
            temp_expected_val = 8'hFB; // -5
            temp_expected_overflow = 1'b0;
            do_add_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Normal Mixed Sign Addition (10 + -15)");

            // Test 4: Positive Saturation (MAX_VAL - 1 + 2)
            temp_opA = MAX_8_BIT_SIGNED - 8'd1;
            temp_opB = 8'd2;
            temp_expected_val = MAX_8_BIT_SIGNED;
            temp_expected_overflow = 1'b1;
            do_add_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Positive Saturation (126 + 2)");

            // Test 5: Positive Saturation (MAX_VAL + MAX_VAL)
            temp_opA = MAX_8_BIT_SIGNED;
            temp_opB = MAX_8_BIT_SIGNED;
            temp_expected_val = MAX_8_BIT_SIGNED;
            temp_expected_overflow = 1'b1;
            do_add_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Positive Saturation (127 + 127)");

            // Test 6: Negative Saturation (MIN_VAL + MIN_VAL)
            temp_opA = MIN_8_BIT_SIGNED;
            temp_opB = MIN_8_BIT_SIGNED;
            temp_expected_val = MIN_8_BIT_SIGNED;
            temp_expected_overflow = 1'b1;
            do_add_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Negative Saturation (-128 + -128)");

            // Test 7: Negative Saturation (MIN_VAL + 1 - 2)
            temp_opA = MIN_8_BIT_SIGNED + 8'd1;
            temp_opB = 8'hFE; // -2
            temp_expected_val = MIN_8_BIT_SIGNED;
            temp_expected_overflow = 1'b1;
            do_add_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Negative Saturation (-127 + -2)");

            // Test 8: Specific user case: 0x80 + 0x81 (which is -128 + -127 = -255, saturates to -128 / 0x80)
            temp_opA = 8'h80;
            temp_opB = 8'h81;
            temp_expected_val = 8'h80;
            temp_expected_overflow = 1'b1;
            do_add_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Specific Saturation Test (0x80 + 0x81)");

            // Test 9: Zero inputs
            temp_opA = 8'd0;
            temp_opB = 8'd0;
            temp_expected_val = 8'd0;
            temp_expected_overflow = 1'b0;
            do_add_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Zero Inputs (0 + 0)");

            // Test 10: One positive, one negative, result zero
            temp_opA = 8'd50;
            temp_opB = 8'hCE; // -50
            temp_expected_val = 8'd0;
            temp_expected_overflow = 1'b0;
            do_add_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Zero Result (50 + -50)");

        /* SUB */

            // Test S1: Normal subtraction (positive result)
            temp_opA = 8'd10; 
            temp_opB = 8'd3; 
            temp_expected_val = 8'd7; 
            temp_expected_overflow = 1'b0;
            // i_sub = 'b1; <-- Handled inside do_sub_check
            do_sub_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Sub: Normal Positive (10 - 3)");

            // Test S2: Normal subtraction (negative result)
            temp_opA = 8'd3; 
            temp_opB = 8'd10; 
            temp_expected_val = 8'hF9; 
            temp_expected_overflow = 1'b0;
            do_sub_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Sub: Normal Negative (3 - 10)");

            // Test S3: Subtracting negative numbers (becomes addition)
            temp_opA = 8'd5; 
            temp_opB = 8'hFB; // -5
            temp_expected_val = 8'd10; 
            temp_expected_overflow = 1'b0; // 5 - (-5) = 10
            do_sub_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Sub: Subtract Negative (5 - (-5))");

            // Test S4: Positive saturation (A - B where B is large negative)
            temp_opA = MAX_8_BIT_SIGNED - 8'd1; // 126
            temp_opB = MIN_8_BIT_SIGNED;        // -128
            // 126 - (-128) = 126 + 128 = 254. Should saturate to 127.
            temp_expected_val = MAX_8_BIT_SIGNED;
            temp_expected_overflow = 1'b1;
            do_sub_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Sub: Positive Saturation (126 - (-128))");

            // Test S5: Negative saturation (A - B where B is large positive)
            temp_opA = MIN_8_BIT_SIGNED + 8'd1; // -127
            temp_opB = MAX_8_BIT_SIGNED;        // 127
            // -127 - 127 = -254. Should saturate to -128.
            temp_expected_val = MIN_8_BIT_SIGNED;
            temp_expected_overflow = 1'b1;
            do_sub_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Sub: Negative Saturation (-127 - 127)");

            // Test S6: Subtracting zero
            temp_opA = 8'd42; temp_opB = 8'd0; temp_expected_val = 8'd42; temp_expected_overflow = 1'b0;
            do_sub_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Sub: Subtract Zero (42 - 0)");

            // Test S7: Zero minus a positive number
            temp_opA = 8'd0; 
            temp_opB = 8'd25; 
            temp_expected_val = 8'hE7; 
            temp_expected_overflow = 1'b0;
            do_sub_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Sub: Zero Minus Positive (0 - 25)");

            // Test S8: Zero minus a negative number
            temp_opA = 8'd0; 
            temp_opB = 8'hEB; // -21
            temp_expected_val = 8'd21; 
            temp_expected_overflow = 1'b0; // 0 - (-21) = 21
            do_sub_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Sub: Zero Minus Negative (0 - (-21))");

            // Test S9: Subtracting largest positive from smallest negative (Max negative saturation)
            temp_opA = MIN_8_BIT_SIGNED; // -128
            temp_opB = MAX_8_BIT_SIGNED; // 127
            // -128 - 127 = -255. Should saturate to -128 (MIN_8_BIT_SIGNED)
            temp_expected_val = MIN_8_BIT_SIGNED;
            temp_expected_overflow = 1'b1;
            do_sub_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Sub: Extreme Negative Saturation (-128 - 127)");

            // Test S10: Subtracting smallest negative from largest positive (Max positive saturation)
            temp_opA = MAX_8_BIT_SIGNED; // 127
            temp_opB = MIN_8_BIT_SIGNED; // -128
            // 127 - (-128) = 127 + 128 = 255. Should saturate to 127 (MAX_8_BIT_SIGNED)
            temp_expected_val = MAX_8_BIT_SIGNED;
            temp_expected_overflow = 1'b1;
            do_sub_check(temp_opA, temp_opB, temp_expected_val, temp_expected_overflow, "Sub: Extreme Positive Saturation (127 - (-128))");



        // If all tests pass
        $display("\n================================================================================");
        $display("PASS: All FixedPointAddSub tests completed successfully.");
        $display("================================================================================");
        $finish; // End simulation
    end

    // Monitor for simulation timeout (fallback if tests don't complete)
    initial begin
        #1000; // Adjust timeout as needed for more complex test sequences
        $display("\nERROR: Simulation timed out. Not all tests completed.");
        $finish;
    end

endmodule
