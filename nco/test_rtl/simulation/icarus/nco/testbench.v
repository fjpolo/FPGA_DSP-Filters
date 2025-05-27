// =============================================================================
// File        : testbench.v for nco.v
// Author      : Gemini
// Description : Self-checking testbench for the nco module, now comparing
//               against an integer-based model of the sine lookup table,
//               with more steps for robustness.
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
`timescale 1ns/1ps // Define timescale for simulation

module testbench; // Testbench module name

    // Parameters for the NCO module (must match nco.v)
    parameter LGTBL = 9;   // Log, base two, of the table size (P in nco.v)
    parameter W = 32;      // Word-size (width of phase accumulator and frequency word)
    parameter OW = 8;      // Output width (width of the sine wave sample)

    // Testbench signals (wires and regs for connecting to NCO module)
    reg         i_clk;
    reg         i_ld;
    reg [W-1:0] i_dphase;
    reg         i_ce;
    // Removed i_reset as the nco module does not expose a reset port
    wire [OW-1:0] o_val;

    // Clock period definition
    localparam CLK_PERIOD = 10; // 10ns clock period (100 MHz)
    localparam TABLE_SIZE = (1 << LGTBL); // Size of the sine lookup table

    // Testbench internal variables for self-checking
    reg [W-1:0] tb_r_phase;     // Mirror of the NCO's internal phase accumulator
    reg [OW-1:0] expected_o_val;    // Quantized expected output value
    reg         test_passed;        // Flag to track overall test status (1 = PASS, 0 = FAIL)
    integer     samples_checked;    // Counter for the number of samples checked
    integer     mismatches;         // Counter for mismatches

    // Declare phase_index_for_sine as a reg with explicit bit-width
    reg [LGTBL-1:0] phase_index_for_sine;

    // Declare a memory for the sine lookup table in the testbench
    reg [OW-1:0] sine_lut_tb [0:TABLE_SIZE-1];

    // Clock generation
    always #((CLK_PERIOD / 2)) i_clk = ~i_clk;

    // Instantiate the NCO module
    nco #(
        .LGTBL(LGTBL),
        .W(W),
        .OW(OW)
    ) u_nco (
        .i_clk(i_clk),
        .i_ld(i_ld),
        .i_dphase(i_dphase),
        .i_ce(i_ce),
        .o_val(o_val)
        // Removed i_reset port connection as nco module doesn't have one
    );

    // Initial block for test sequence
    initial begin
        // Initialize inputs
        i_clk = 0;
        i_ld = 0;
        i_dphase = 0;
        i_ce = 0;
        // Removed i_reset assertion as nco module doesn't have a reset port

        // Initialize test status variables
        tb_r_phase = 0; // The NCO's initial block sets r_phase to 0, so mirror this.
        test_passed = 1; // Assume pass until a failure occurs
        samples_checked = 0;
        mismatches = 0;

        // Load the sine lookup table from sintable.hex into testbench's memory
        // Ensure sintable.hex is correctly formatted (OW bits per line, TABLE_SIZE lines)
        $readmemh("sintable.hex", sine_lut_tb);

        // Setup VCD (Value Change Dump) for waveform viewing
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench); // Dump all signals in the current scope

        // Monitor relevant signals (for console output)
        $monitor("Time: %0t | i_clk: %b | i_ld: %b | i_dphase: %0d | i_ce: %b | o_val: %0d (0x%h) | Expected_o_val: %0d (0x%h) | u_nco.r_phase: %0d",
                 $time, i_clk, i_ld, i_dphase, i_ce, o_val, o_val, expected_o_val, expected_o_val, u_nco.r_phase);

        // --- Test Sequence ---

        // Wait for a few clock cycles for initial stabilization (no explicit reset needed for NCO)
        # (CLK_PERIOD * 2);

        // 1. Load a frequency word (dphase)
        // This value determines the frequency.
        // Based on the C++ example's frequency (0.01 cycles/sample) and a 32-bit accumulator:
        // dphase = frequency * 2^W / sample_rate
        // Assuming sample_rate = 1.0 (as in C++ NCO's SAMPLE_RATE)
        // dphase = 0.01 * (2^32) = 0.01 * 4294967296 = 42949672.96
        // We'll use the integer part.
        i_dphase = 32'd42949673; // Example dphase for a visible frequency

        i_ld = 1; // Assert load enable
        # CLK_PERIOD; // Hold load for one clock cycle
        i_ld = 0; // De-assert load enable

        // Initialize expected_o_val for the very first sample (based on initial tb_r_phase = 0)
        // Note: The NCO's sintable output is registered, so the first valid output
        // will appear one cycle after the phase accumulator starts accumulating.
        // The initial value of o_val will be whatever sintable.v initializes to (likely 0).
        phase_index_for_sine = tb_r_phase >> (W - LGTBL);
        expected_o_val = sine_lut_tb[phase_index_for_sine];

        // 2. Enable the NCO and observe output for more steps (e.g., 200 samples)
        repeat (200) begin // Simulate for 200 *effective* samples (where i_ce is high)
            // Cycle 1: i_ce goes high, NCO updates phase and output
            # (CLK_PERIOD / 2); // Wait for negedge of clock
            i_ce = 1;           // Enable NCO operation
            # (CLK_PERIOD / 2); // Wait for posedge of clock (NCO updates r_phase, sintable registers new value, o_val holds OLD value)

            // --- Self-checking logic ---
            // At this point (posedge), o_val is valid and represents the output for the *current* sample.
            // It was generated based on the phase *before* the current r_phase update (due to sintable's registered output).
            // Our 'expected_o_val' was calculated based on the 'tb_r_phase' from the *previous* cycle.
            // So, compare.
            samples_checked = samples_checked + 1;
            if (o_val !== expected_o_val) begin
                $display("--------------------------------------------------------------------------------------------------------------------");
                $display("!!! FAIL !!! at Time: %0t | Sample: %0d | Expected: %0d (0x%h) | Actual: %0d (0x%h)",
                         $time, samples_checked - 1, expected_o_val, expected_o_val, o_val, o_val);
                $display("--------------------------------------------------------------------------------------------------------------------");
                test_passed = 0; // Set flag to indicate failure
                mismatches = mismatches + 1;
            end else begin
                // Optional: Print PASS for each sample, or just print mismatches
                // $display("PASS at Time: %0t | Sample: %0d | Expected: %0d (0x%h) | Actual: %0d (0x%h)",
                //          $time, samples_checked - 1, expected_o_val, expected_o_val, o_val, o_val);
            end

            // Now, update tb_r_phase to reflect the NCO's phase for the *next* sample.
            // This tb_r_phase will be used to calculate expected_o_val for the *next* iteration.
            tb_r_phase = tb_r_phase + i_dphase;
            phase_index_for_sine = tb_r_phase >> (W - LGTBL);
            expected_o_val = sine_lut_tb[phase_index_for_sine]; // Calculate expected for next sample

            // Cycle 2: i_ce goes low, NCO is idle (no phase accumulation or output update)
            # (CLK_PERIOD / 2); // Wait for negedge of clock
            i_ce = 0;           // Disable NCO operation
            # (CLK_PERIOD / 2); // Wait for posedge of clock
        end

        // --- Final Test Report ---
        $display("\n====================================================================================================");
        if (test_passed && mismatches == 0) begin
            $display("TEST RESULT: PASS (All %0d samples matched expected values)", samples_checked);
        end else if (mismatches > 0) begin
            $display("TEST RESULT: FAIL (%0d mismatches out of %0d samples)", mismatches, samples_checked);
        end else begin // test_passed is 0 due to an "ERROR"
            $display("TEST RESULT: ERROR (Initial checks failed or other issues detected)");
        end
        $display("====================================================================================================\n");

        // End simulation
        $finish;
    end

endmodule
