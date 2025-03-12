# Average Filter Module

This Verilog module implements a pipelined average filter. It takes a stream of 8-bit signed data and outputs the average of the current and previous sample.

## Features

* Pipelined design for high throughput.
* Supports customizable DATA_WIDTH.
* Clock enable (CE) signal for flow control, both input and output.

## Requirements

Linux or macOS with [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build/releases) installed in `home/<username>/oss-cad-suite/`

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

## Validation

This module uses [`icarus verilog`](https://github.com/steveicarus/iverilog), [`symbiyosys`](https://github.com/YosysHQ/sby), [`equivalence checking wiht yosys`](https://github.com/YosysHQ/eqy) and [`mutation cover with yosys`](https://github.com/YosysHQ/mcy) to get a `100% mutation test coverage`!

Usage:

Linux/macOS
```bash
/$ cd test_rtl && ./test_all_log.sh
```

This will generate a `test_log.txt` in `test_rtl/`, and more logs in `<test_rtl/<dir>/average_filter/average_filter.txt`

## Synthesis

There's a little yosys synth script in `average_filter/test_rtl/synth/average_filter/average_filter.ys`for Tang Nano 20k, but it's untested.

Also, there's a Tang Nano 9k Gowin IDE project in `average_filter/gowin/nano9k/average_filter.gprj`, to check STA, but also, sofar unused.