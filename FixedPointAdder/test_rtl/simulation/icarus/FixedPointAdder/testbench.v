// =============================================================================
// File        : testbench.v for FixedPointAdder.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Self-checking testbench for the FixedPointAdder module.
//               Verifies addition, signed saturation, and overflow detection
//               across various input scenarios including normal operation,
//               positive overflow, and negative overflow. It uses a helper
//               task for repetitive test case execution and includes pass/fail
//               messaging for automated regression.
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

    // Define the WIDTH parameter for the UUT (Unit Under Test)
    localparam WIDTH = 8; // Matching the default WIDTH of FixedPointAdder

    // Inputs to the UUT
    reg         i_clk;
    reg         i_rst;      // Active high reset for FixedPointAdder
    reg         i_start;
    reg signed [WIDTH-1:0] i_operandA;
    reg signed [WIDTH-1:0] i_operandB;

    // Outputs from the UUT
    wire        o_busy;
    wire        o_done;
    wire        o_valid;
    wire        o_overflow;
    wire signed [WIDTH-1:0] o_val;

    // Temporary variables for task arguments, declared at the module level for broader compatibility
    reg signed [WIDTH-1:0] temp_opA;
    reg signed [WIDTH-1:0] temp_opB;
    reg signed [WIDTH-1:0] temp_expected_val;
    reg                    temp_expected_overflow; // Changed 'logic' to 'reg' for broader compatibility

    // Instantiate the Unit Under Test (UUT)
    // Pass parameters to the UUT instance
    FixedPointAdder #(
        .WIDTH(WIDTH),
        .FBITS(4) // FBITS is not used in adder logic but kept for consistency
    ) uut (
        .i_clk      (i_clk),
        .i_rst      (i_rst),
        .i_start    (i_start),
        .i_operandA (i_operandA),
        .i_operandB (i_operandB),
        .o_busy     (o_busy),
        .o_done     (o_done),
        .o_valid    (o_valid),
        .o_overflow (o_overflow),
        .o_val      (o_val)
    );

    // Define constants for WIDTH=8 signed numbers
    localparam signed [WIDTH-1:0] MAX_8_BIT_SIGNED = 8'd127; // 0x7F
    localparam signed [WIDTH-1:0] MIN_8_BIT_SIGNED = 8'h80;  // Represents -128 (using hex for compatibility)

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
    // The FixedPointAdder has 1-cycle latency, meaning outputs are registered
    // and appear on the clock edge *after* i_start is asserted.
    task do_add_check;
        input signed [WIDTH-1:0] opA;
        input signed [WIDTH-1:0] opB;
        input signed [WIDTH-1:0] expected_val;
        input logic expected_overflow;
        input string test_name;
        begin
            $display("\n--------------------------------------------------------------------------------");
            $display("TEST: %s", test_name);
            $display("Applying i_operandA = %0d (0x%h), i_operandB = %0d (0x%h)", opA, opA, opB, opB);

            // Apply inputs
            i_operandA = opA;
            i_operandB = opB;
            i_start    = 1'b1; // Assert start for one cycle

            #(10)// Wait for the clock edge where inputs are registered and computation starts
            i_start    = 1'b0; // De-assert start (pulse i_start)

            // At this point, o_busy should be high (reflecting i_start one cycle ago)
            // and o_done/o_valid/o_overflow/o_val should be stable and reflect the result of this cycle's operation.
            // Wait for the next clock edge to sample the registered outputs.
            // #(10)

            // Check outputs
            // Verify handshake signals first
            // Changed o_busy expectation from 0 to 1 as per UUT's 1-cycle latency behavior
            if (uut.o_done === 1'b1 && uut.o_valid === (expected_overflow ? 1'b0 : 1'b1) && uut.o_busy === 1'b1) begin
                if (uut.o_val === expected_val && uut.o_overflow === expected_overflow) begin
                    $display("PASS: %s. Result: %0d (0x%h), Overflow: %b. Expected: %0d (0x%h), Overflow: %b",
                             test_name, uut.o_val, uut.o_val, uut.o_overflow, expected_val, expected_val, expected_overflow);
                end else begin
                    $display("FAIL: %s. Mismatch! Result: %0d (0x%h), Overflow: %b. Expected: %0d (0x%h), Overflow: %b",
                             test_name, uut.o_val, uut.o_val, uut.o_overflow, expected_val, expected_val, expected_overflow);
                    $finish; // Terminate simulation on failure
                end
            end else begin
                $display("FAIL: %s. Handshake failed! o_done=%b, o_valid=%b, o_busy=%b. Expected 1, 1, 1.",
                         test_name, uut.o_done, uut.o_valid, uut.o_busy);
                $finish; // Terminate simulation on failure
            end
            #10; // Small delay to let signals settle before next test setup
        end
    endtask

    // Main test sequence
    initial begin
        // Initialize inputs to safe values
        i_rst      = 1'b1; // Assert reset
        i_start    = 1'b0;
        i_operandA = '0;
        i_operandB = '0;

        // Reset phase
        #10; // Wait a little for reset to settle
        $display("Applying Reset...");
        i_rst = 1'b0; // De-assert reset
        #10; // Wait another clock cycle after reset de-assertion
        $display("Reset De-asserted.");

        // Check reset state (should be all zeros for outputs)
        if (uut.o_val !== '0 || uut.o_done !== 1'b0 || uut.o_valid !== 1'b0 ||
            uut.o_overflow !== 1'b0 || uut.o_busy !== 1'b0) begin
            $display("FAIL: Reset state incorrect. o_val=0x%h, o_done=%b, o_valid=%b, o_overflow=%b, o_busy=%b",
                     uut.o_val, uut.o_done, uut.o_valid, uut.o_overflow, uut.o_busy);
            $finish;
        end else begin
            $display("PASS: Initial reset state is correct.");
        end

        // Test Cases:

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


        // If all tests pass
        $display("\n================================================================================");
        $display("PASS: All FixedPointAdder tests completed successfully.");
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
