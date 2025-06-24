// =============================================================================
// File        : testbench.v for sqrtFixedPoint.v
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

module testbench();

    parameter CLK_PERIOD = 10;
    parameter WIDTH = 16;
    parameter FBITS = 8;
    // Removed SF and all floating-point math inside Verilog for maximum compatibility.

    logic clk;
    logic start;
    logic [WIDTH-1:0] rad;

    wire busy;
    wire valid;
    wire [WIDTH-1:0] root;
    wire [WIDTH-1:0] rem;

    // Instantiate the Device Under Test (DUT)
    sqrtFixedPoint #(.WIDTH(WIDTH), .FBITS(FBITS)) sqrt_inst (
        .clk(clk),
        .start(start),
        .busy(busy),
        .valid(valid),
        .rad(rad),
        .root(root),
        .rem(rem)
    );

    // Clock generation
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Monitor displayed values - now only displays raw bit vectors
    initial begin
        // You'll need to manually interpret the fixed-point values,
        // or write a script to post-process the simulation output.
        $monitor("\t%d:\trad=%b (root=%b, rem=%b, valid=%b)",
                         $time, rad, root, rem, valid);
    end

    // Test stimulus
    initial begin
        clk = 1;

        // Test Case 1: sqrt(232.5625) -> Radicand = 16'b1110_1000_1001_0000 (decimal 59536)
        // Manual check: sqrt(232.5625) approx 15.25, in Q8.8 is 15.25 * 256 = 3904 (16'b0000_1111_0100_0000)
        #100    rad = 16'b1110_1000_1001_0000;
        start = 1;
        #10     start = 0;

        wait(valid);
        #10;

        // Test Case 2: sqrt(0.25) -> Radicand = 16'b0000_0000_0100_0000 (decimal 64)
        // Manual check: sqrt(0.25) = 0.5, in Q8.8 is 0.5 * 256 = 128 (16'b0000_0000_1000_0000)
        #120    rad = 16'b0000_0000_0100_0000;
        start = 1;
        #10     start = 0;

        wait(valid);
        #10;

        // Test Case 3: sqrt(2.0) -> Radicand = 16'b0000_0010_0000_0000 (decimal 512)
        // Manual check: sqrt(2.0) approx 1.414, in Q8.8 is 1.414 * 256 = 362 (16'b0000_0001_0110_1010)
        #120    rad = 16'b0000_0010_0000_0000;
        start = 1;
        #10     start = 0;
        wait(valid);
        #10;

        #120    $finish; // End simulation
    end
endmodule
