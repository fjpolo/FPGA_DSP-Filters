// =============================================================================
// File        : testbench.v for sintable.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Reset state testbench with VCD waveform support
// License     : MIT License
//
// Copyright (c) 2025 | @fjpolo
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
        
        // Test 1: Initial reset state
        $display("TEST 1: Checking initial reset state...");
        if (o_val !== 0 || o_aux !== 0) begin
            $display("ERROR: Initial reset state failed");
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        #1000;
        
        // Test 2: Release reset and check outputs
        $display("TEST 2: Releasing reset...");
        i_reset = 0;
        i_ce = 1;
        i_phase = 10'h123;  // Non-zero phase
        i_aux = 1;
        #2000;
        
        // Test 3: Assert reset during operation
        $display("TEST 3: Asserting reset during operation...");
        i_reset = 1;
        #1000;
        if (o_val !== 0 || o_aux !== 0) begin
            $display("ERROR: Reset assertion failed - outputs not zero");
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        
        // Test 4: Release reset again
        $display("TEST 4: Releasing reset again...");
        i_reset = 0;
        #1000;
        
        // Test 5: Multiple reset pulses
        $display("TEST 5: Testing multiple reset pulses...");
        repeat (3) begin
            i_reset = 1;
            #500;
            if (o_val !== 0 || o_aux !== 0) begin
                $display("ERROR: Reset pulse failed - outputs not zero");
                error_count = error_count + 1;
            end
            i_reset = 0;
            #500;
        end
        test_count = test_count + 1;
        
        // Finish tests
        test_finished = 1;
        #1000;
        
        // Print results
        if (error_count == 0) begin
            $display("PASS: All %0d reset tests passed", test_count);
            $finish;
        end else begin
            $display("FAIL: %0d errors in reset tests", error_count);
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
