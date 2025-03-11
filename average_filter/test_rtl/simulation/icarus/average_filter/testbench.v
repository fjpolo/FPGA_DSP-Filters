// =============================================================================
// File        : testbench.v for average_filter.v
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

module average_filter_tb();

parameter DATA_WIDTH = 8;

reg clk;
reg reset_n;
reg i_ce;
reg signed [(DATA_WIDTH-1):0] data_in;
wire signed [(DATA_WIDTH-1):0] data_out;
wire o_ce;

`ifdef MCY
  average_filter uut(
    .clk(clk),
    .reset_n(reset_n),
    .i_ce(i_ce),
    .data_in(data_in),
    .data_out(data_out),
    .o_ce(o_ce)
  );
`else
  average_filter #(
    .DATA_WIDTH(DATA_WIDTH)
  ) uut(
    .clk(clk),
    .reset_n(reset_n),
    .i_ce(i_ce),
    .data_in(data_in),
    .data_out(data_out),
    .o_ce(o_ce)
  );
`endif

parameter CLK_PERIOD = 10;
parameter TEST_VECTOR_SIZE = 10;

reg [(DATA_WIDTH-1):0] test_vectors [0:TEST_VECTOR_SIZE-1];
reg signed [(DATA_WIDTH-1):0] expected_outputs [0:TEST_VECTOR_SIZE-1];
integer test_index;
integer error_count;
integer i;

initial begin
  $dumpfile("dump.vcd");
  $dumpvars(0, average_filter_tb); // Dump all signals in the testbench
end

initial begin
  clk = 0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
  // Test Vectors (Including Negative Numbers)
  test_vectors[0] =  10;
  test_vectors[1] = -20;
  test_vectors[2] =  30;
  test_vectors[3] = -40;
  test_vectors[4] =  50;
  test_vectors[5] =  0;
  test_vectors[6] =  100;
  test_vectors[7] = -127;
  test_vectors[8] =  127;
  test_vectors[9] = -60;

  // Expected Outputs (Including Negative Numbers)
  expected_outputs[0] =  10;
  expected_outputs[1] = -5;   // (10-20)/2 = -10/2 = -5
  expected_outputs[2] =  5;   // (-20+30)/2 = 10/2 = 5
  expected_outputs[3] = -5;   // (30-40)/2 = -10/2 = -5
  expected_outputs[4] =  5;   // (-40+50)/2 = 10/2 = 5
  expected_outputs[5] =  25;  // (50+0)/2 = 25
  expected_outputs[6] =  50;  // (0+100)/2 = 50
  expected_outputs[7] = -14;  // (100-128)/2 = -28/2 = -14
  expected_outputs[8] =  0;  //  (-127+127)/2 = 0
  expected_outputs[9] =  33;  // (127-60)/2 = 67/2 = 33.5 (truncates to 33)

  reset_n = 1;
  #10;
  clk = 1;
  test_index = 0;
  error_count = 0;

  // Apply the first test vector and wait 3 clock cycles.
  data_in = test_vectors[0];
  #(3*CLK_PERIOD);

  // Now start the main test loop.
  data_in = test_vectors[0];
  i_ce = 1;
  #CLK_PERIOD;
  #CLK_PERIOD;
  for (i = 1; i < TEST_VECTOR_SIZE-1; i = i + 1) begin
    data_in = test_vectors[i];
    i_ce = 1;
    #CLK_PERIOD;
    #CLK_PERIOD;
    if ((data_out !== expected_outputs[i])||(!o_ce)) begin
      $display("FAIL: Test Vector %d, Expected %d, Actual %d", i, expected_outputs[i], data_out);
      error_count = error_count + 1;
    end
  end

  if (error_count == 0) begin
    $display("PASS: All tests passed.");
  end else begin
    $display("FAIL: %d tests failed.", error_count);
  end
  $finish;
end

endmodule
