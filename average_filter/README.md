# Average Filter Module

This Verilog module implements a pipelined average filter. It takes a stream of 8-bit signed data and outputs the average of the current and previous sample.

## Features

* Pipelined design for high throughput.
* Supports 8-bit signed data.
* Clock enable (CE) signal for flow control.

## Usage

1. **Instantiate the module:**

   ```verilog
   average_filter #(
       // Optional parameters here 
   ) my_filter (
       .clk(clk),
       .reset_n(reset_n),
       .i_ce(i_ce),
       .data_in(data_in),
       .data_out(data_out),
       .o_ce(o_ce)
   );