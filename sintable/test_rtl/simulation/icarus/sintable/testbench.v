// =============================================================================
// File        : testbench.v for sintable.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Enhanced testbench with VCD and FST waveform support
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

module testbench();
    // Parameters
    parameter PW = 17;
    parameter OW = 13;
    
    // Clock and reset
    reg i_clk = 0;
    reg i_reset = 1;
    
    // Module inputs
    reg i_ce = 0;
    reg [PW-1:0] i_phase = 0;
    reg i_aux = 0;
    
    // Module outputs
    wire [OW-1:0] o_val;
    wire o_aux;
    
    // Test variables
    reg [31:0] error_count = 0;
    reg [31:0] test_count = 0;
    reg test_finished = 0;
    
    // Instantiate the DUT
    sintable #(
        .PW(PW),
        .OW(OW)
    ) dut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_ce(i_ce),
        .i_phase(i_phase),
        .o_val(o_val),
        .i_aux(i_aux),
        .o_aux(o_aux)
    );
    
    // Generate clock
    always #500 i_clk = ~i_clk;
    
    // Waveform initialization
    initial begin
        $dumpfile("reset_test.vcd");
        $dumpvars(0, testbench);
    end
    
    // Test sequence
    initial begin
        // Wait for waveform initialization
        #100;
        
        // =============================================
        // Level 1: Basic Reset Functionality
        // =============================================
        $display("\n=== LEVEL 1: Basic Reset Tests ===");
        
        // Test 1.1: Initial reset state
        $display("TEST 1.1: Checking initial reset state...");
        if (o_val !== 0 || o_aux !== 0) begin
            $display("ERROR: Initial reset state failed");
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        #1000;
        
        // Test 1.2: Release reset
        $display("TEST 1.2: Releasing reset...");
        i_reset = 0;
        i_ce = 1;
        i_phase = 10'h123;
        i_aux = 1;
        #2000;
        
        // Test 1.3: Assert reset during operation
        $display("TEST 1.3: Asserting reset during operation...");
        i_reset = 1;
        #1000;
        if (o_val !== 0 || o_aux !== 0) begin
            $display("ERROR: Reset assertion failed - outputs not zero");
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        
        // =============================================
        // Level 2: Advanced Reset Scenarios
        // =============================================
        $display("\n=== LEVEL 2: Advanced Reset Tests ===");
        
        // Test 2.1: Reset with clock enable off
        $display("TEST 2.1: Reset with i_ce=0...");
        i_reset = 0;
        i_ce = 0;
        #1000;
        i_reset = 1;
        #1000;
        if (o_val !== 0 || o_aux !== 0) begin
            $display("ERROR: Reset with i_ce=0 failed");
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        i_reset = 0;
        #1000
        
        // Test 2.2: Reset during phase transition
        $display("TEST 2.2: Reset during phase transition...");
        i_reset = 0;
        i_ce = 1;
        i_phase = 10'hABC;
        #1000;
        i_reset = 1;
        #1000;
        if (o_val !== 0 || o_aux !== 0) begin
            $display("ERROR: Reset during transition failed");
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        i_reset = 0;
        #1000
        
        // =============================================
        // Level 3: Corner Case Testing
        // =============================================
        $display("\n=== LEVEL 3: Corner Case Tests ===");
        
        // Test 3.1: Reset exactly at clock edge
        $display("TEST 3.1: Reset at clock edge...");
        i_reset = 0;
        i_phase = 10'hFFF;
        #900;
        @(posedge i_clk);
        i_reset = 1;
        #100;
        if (o_val !== 0 || o_aux !== 0) begin
            $display("ERROR: Clock-edge reset failed");
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        
        // Test 3.2: Very short reset pulse
        $display("TEST 3.2: Short reset pulse (1 cycle)...");
        i_reset = 0;
        #1000;
        i_reset = 1;
        #1000;
        @(posedge i_clk);
        if (o_val !== 0) begin
            $display("ERROR: Short reset pulse failed");
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        i_reset = 0;
        #1000
        
        // =============================================
        // Final Checks
        // =============================================
        test_finished = 1;
        #1000;
        
        // Print results
        $display("\n=== TEST SUMMARY ===");
        if (error_count == 0) begin
            $display("PASS: All %0d reset tests passed", test_count);
            $finish;
        end else begin
            $display("FAIL: %0d errors in %0d reset tests", error_count, test_count);
            $finish;
        end
    end
    
    // Timeout check
    initial begin
        #1000000; // 1ms timeout
        if (!test_finished) begin
            $display("ERROR: Testbench timed out");
            $finish;
        end
    end
endmodule
