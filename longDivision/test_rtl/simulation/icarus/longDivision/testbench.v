// =============================================================================
// File        : testbench.v for longDivision.v
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

 module testbench;
    parameter CLK_HALF = 5;
    parameter CLK_FULL = 10;
    parameter WIDTH = 33;
    parameter FBITS = 0;
    parameter SCALING_FACTOR = 2**FBITS; // 16
    parameter STRING_WIDTH = 64; // Max characters for test name (Workaround for Icarus 'string' limitation)
    
    // Signals for connecting to the DUT
    reg i_clk = 0;
    reg i_rst;
    reg [WIDTH-1:0] i_a;
    reg [WIDTH-1:0] i_b;
    reg i_start;

    // DUT Outputs (from longDivision.v port list)
    wire [WIDTH-1:0] o_quot; // Quotient (replaces o_val for fixed-point result)
    wire [WIDTH-1:0] o_rem_val; // Remainder value
    wire o_busy;
    wire o_done;
    wire o_valid;
    wire o_dbz;
    wire o_ovf; // Added wire for overflow, assumed based on error task checks

     // Instantiate the Device Under Test (DUT)
    longDivision #(
        .WIDTH(WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_a(i_a),
        .i_b(i_b),
        .i_start(i_start),
        
        .o_quot(o_quot),   // Connect to DUT o_quot
        .o_rem(o_rem_val), // Connect to DUT o_rem
        
        .o_busy(o_busy),
        .o_done(o_done),
        .o_valid(o_valid),
        .o_dbz(o_dbz)
    );

    // Clock generation
    initial begin
        i_clk = 1;
        forever #CLK_HALF i_clk = ~i_clk; // 10ps clock period
    end

    // --- Reset Task ---
    task reset_dut;
        begin
            #CLK_FULL;
            i_rst = 0;
            #CLK_FULL;
            i_rst = 1;
            #CLK_FULL;
            i_rst = 0;
            #CLK_FULL;
        end
    endtask

     // --- Test Division Task (Main Test Function) ---
    task test_dut_divide;
        input real a_in;
        input real b_in;
        // FIX: Use packed array instead of unsupported 'string'
        input reg [8*STRING_WIDTH-1:0] test_name; 
        integer scaled_a, scaled_b, expected_val_int;
        reg real expected_val_real, dut_val_real;
        reg real expected_rem_int;

        begin
            // FIX: Use %0s format specifier
            $display("--- Starting Test: %0s ---", test_name);
            i_start = 0;

            // 1. Reset DUT
            reset_dut;

            // 2. Scale inputs to fixed-point integers
            scaled_a = $rtoi(a_in * SCALING_FACTOR);
            scaled_b = $rtoi(b_in * SCALING_FACTOR);

            // 3. Apply inputs
            #CLK_FULL;
            i_a = scaled_a;
            i_b = scaled_b;
            i_start = 1;

            #CLK_FULL;
            i_start = 0;

            // 4. Wait for calculation to complete
            wait (o_done == 1);
            
            // 5. Model Quotient Calculation
            expected_val_real = (a_in / b_in); 
            expected_val_int = $rtoi(expected_val_real * SCALING_FACTOR);
            expected_rem_int = $rtoi(a_in % b_in);

            // 6. Calculate DUT's value in real number for comparison
            // o_quot holds the fixed-point result.
            dut_val_real = $signed(o_quot) / SCALING_FACTOR;

            // 7. Log and Check Results
            $display("Test: %0s", test_name);
            $display("Input A: %f, Input B: %f", a_in, b_in);
            $display("Scaled A: %0d (%b), Scaled B: %0d (%b)", scaled_a, scaled_a, scaled_b, scaled_b);
            $display("DUT Val (Fixed-Point Integer): %0d (%b)", $signed(o_quot), o_quot);
            $display("Expected Val (Fixed-Point Integer): %0d", expected_val_int);
            $display("DUT Val (Real): %f, Model Val (Real): %f", dut_val_real, expected_val_real);
            
            // Check success conditions (no error flags, value matches)
            if (o_busy != 0) $fatal(1, "FAIL: %0s - busy is not 0!", test_name);
            if (o_done != 1) $fatal(1, "FAIL: %0s - done is not 1!", test_name);
            if (o_valid != 1) $fatal(1, "FAIL: %0s - valid is not 1!", test_name);
            if (o_dbz != 0) $fatal(1, "FAIL: %0s - dbz is not 0!", test_name);
            if (o_ovf != 0) $fatal(1, "FAIL: %0s - ovf is not 0!", test_name);
            
            // Compare the fixed-point integer values from DUT and Model
            if ($signed(o_quot) != expected_val_int) begin
                $fatal(1, "FAIL: %0s - DUT value (%0d) does not match model (%0d)!", 
                    test_name, $signed(o_quot), expected_val_int);
            end

            // Check 'done' is high for one tick
            if (o_done == 0) $fatal(1, "FAIL: %0s - done is not 0 on next cycle!", test_name);
            else if(($signed(o_quot) == $floor(expected_val_int))&&(o_rem_val == expected_rem_int)) 
                $display("PASS: %0s - Result %f matched model %f and remainder %f matched model %f", test_name, dut_val_real, expected_val_int, o_rem_val, expected_rem_int);
            #CLK_FULL;
            $display("");
        end
    endtask

    // --- Test Error Task (For DBZ/OVF tests) ---
    task test_dut_error;
        input real a_in;
        input real b_in;
        input reg exp_dbz;
        input reg exp_ovf;
        // FIX: Use packed array instead of unsupported 'string'
        input reg [8*STRING_WIDTH-1:0] test_name; 
        reg integer scaled_a, scaled_b;
        
        begin
            // FIX: Use %0s format specifier
            $display("--- Starting Error Test: %0s (DBZ=%b, OVF=%b) ---", test_name, exp_dbz, exp_ovf);
            i_start = 0;

            // 1. Reset DUT
            reset_dut;

            // 2. Scale inputs to fixed-point integers
            scaled_a = $rtoi(a_in * SCALING_FACTOR);
            scaled_b = $rtoi(b_in * SCALING_FACTOR);

            // 3. Apply inputs
            #CLK_FULL;
            i_a = scaled_a;
            i_b = scaled_b;
            i_start = 1;

            #CLK_FULL;
            i_start = 0;

            // 4. Wait for calculation to complete
            wait (o_done == 1);

            // 5. Check Error Flags
            if (o_busy != 0) $fatal(1, "FAIL: %0s - busy is not 0!", test_name);
            if (o_done != 1) $fatal(1, "FAIL: %0s - done is not 1!", test_name);
            if (o_valid != 0) $fatal(1, "FAIL: %0s - valid is not 0!", test_name);
            if (o_dbz != exp_dbz) $fatal(1, "FAIL: %0s - dbz mismatch (exp: %b, actual: %b)!", test_name, exp_dbz, o_dbz);
            if (o_ovf != exp_ovf) $fatal(1, "FAIL: %0s - ovf mismatch (exp: %b, actual: %b)!", test_name, exp_ovf, o_ovf);
            
            $display("PASS: %0s - Expected error flags matched.", test_name);

            // Check 'done' is high for one tick
            #CLK_FULL;
            if (o_done != 0) $fatal(1, "FAIL: %0s - done is not 0 on next cycle!", test_name);
        end
    endtask
    
    // --- Test Execution ---
    initial begin
        // Waveform dumping (for Icarus)
        $dumpfile("dump.vcd");
        $dumpvars(0, testbench); 
        
        i_clk = 0; 
        i_rst = 1; 
        i_start = 0; 
        i_a = 0;
        i_b = 0;

        // Give the clock a moment to start
        #10;
        
        // Simple division tests
        test_dut_divide(6.0, 2.0, "simple_1: 6/2");
        test_dut_divide(15.0, 3.0, "simple_2: 15/3");
        test_dut_divide(13.0, 4.0, "simple_3: 13/4");
        test_dut_divide(3.0, 12.0, "simple_4: 3/12");
        test_dut_divide(7.5, 2.0, "simple_5: 7.5/2");

        // Sign tests
        test_dut_divide(3.0, 2.0, "sign_1: 3/2");
        // test_dut_divide(-3.0, 2.0, "sign_2: -3/2");
        // test_dut_divide(3.0, -2.0, "sign_3: 3/-2");
        // test_dut_divide(-3.0, -2.0, "sign_4: -3/-2");
        
        // // Rounding tests (using the exact values from cocotb)
        // test_dut_divide(5.0625, 2.0, "round_1: 5.0625/2");
        // test_dut_divide(7.0625, 2.0, "round_2: 7.0625/2");
        // test_dut_divide(15.9375, 2.0, "round_3: 15.9375/2");
        // test_dut_divide(14.9375, 2.0, "round_4: 14.9375/2");
        // test_dut_divide(13.0, 7.0, "round_5: 13/7");
        // test_dut_divide(8.1875, 4.0, "round_6: 8.1875/4");
        // test_dut_divide(12.3125, 8.0, "round_7: 12.3125/8");
        // test_dut_divide(-7.0625, 2.0, "round_8: -7.0625/2");
        // test_dut_divide(-5.0625, 2.0, "round_9: -5.0625/2");

        // // Min/Max edge tests
        // test_dut_divide(0.125, 2.0, "min_1: 0.125/2");
        // test_dut_divide(0.0625, 2.0, "min_2: 0.0625/2");
        // test_dut_divide(0.0, 2.0, "min_3: 0/2");
        // test_dut_divide(-0.0625, 2.0, "min_4: -0.0625/2");
        // test_dut_divide(15.9375, 1.0, "max_1: 15.9375/1");
        // test_dut_divide(7.9375, 0.5, "max_2: 7.9375/0.5");
        // test_dut_divide(-15.9375, 1.0, "max_3: -15.9375/1");
        // test_dut_divide(-7.9375, 0.5, "max_4: -7.9375/0.5");

        // // Non-binary value tests
        // test_dut_divide(1.0, 0.2, "nonbin_1: 1/0.2");
        // test_dut_divide(1.9, 0.2, "nonbin_2: 1.9/0.2");
        // test_dut_divide(0.4, 0.2, "nonbin_3: 0.4/0.2");
        // // NOTE: The `expect_fail=True` tests are skipped as they require error tolerance checks.

        // Divide by Zero and Overflow tests (using the specialized task)
        test_dut_error(2.0, 0.0, 1'b1, 1'b0, "dbz_1: 2/0");
        test_dut_divide(13.0, 4.0, "dbz_2: 13/4 [after dbz]");
        // test_dut_error(8.0, 0.25, 1'b0, 1'b1, "ovf_1: 8/0.25");
        test_dut_divide(11.0, 7.0, "ovf_2: 11/7 [after ovf]");
        // test_dut_error(-16.0, 1.0, 1'b0, 1'b1, "ovf_3: -16/1");
        // test_dut_error(1.0, -16.0, 1'b0, 1'b1, "ovf_4: 1/-16");

        // Finish simulation
        $display("\n*** All tests complete! ***");
        $finish;
    end

 endmodule