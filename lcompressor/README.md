# Linear Compressor (Hard Clipper) Module

This Verilog module implements a pipelined single-stage **Hard Clipper** (referred to as a "Linear Compressor" in the file). It takes a stream of `<W_TOTAL>`-bit signed fixed-point data and clamps the magnitude if it exceeds the dynamically provided positive or negative thresholds.

## Features

* **1-Cycle Pipelined:** The output is registered, resulting in a 1 clock cycle latency for high throughput.

* **Dynamic Thresholds:** Positive (`i_threshold_pos`) and negative (`i_threshold_neg`) clipping levels are configurable via input ports, allowing for real-time control.

* Supports customizable `W_TOTAL` bit width (e.g., Q1.15 format for audio).

* Clock enable (`i_ce`) and output clock enable (`o_ce`) for flow control.

## Requirements

Linux or macOS with [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build/releases) installed in `home/<username>/oss-cad-suite/`

## Usage

1. **Instantiate the module:**

```
   parameter USER_W_TOTAL = 16; // e.g., Q1.15
   wire signed [USER_W_TOTAL-1:0] i_data;
   wire signed [USER_W_TOTAL-1:0] i_pos_thresh;
   wire signed [USER_W_TOTAL-1:0] i_neg_thresh;
   wire signed [USER_W_TOTAL-1:0] o_data;
   
   lcompressor #(
       .W_TOTAL(USER_W_TOTAL)
   ) my_clipper (
       .i_clk(clk),                     // Input
       .i_reset_n(reset_n),             // Input - active low
       .i_ce(i_ce),                     // Input CE
       .i_data(i_data),                 // Input Data (to be clipped)
       .i_threshold_pos(i_pos_thresh),  // Input Positive Threshold (e.g., 16'h4000 for 0.5)
       .i_threshold_neg(i_neg_thresh),  // Input Negative Threshold (e.g., 16'hC000 for -0.5)
       .o_data(o_data),                 // Output Data (clipped or passed through)
       .o_ce(o_ce)                      // Output CE (1 cycle delay from i_ce)
   );
```

## Validation

This module uses [`icarus verilog`](https://github.com/steveicarus/iverilog), [`symbiyosys`](https://github.com/YosysHQ/sby), [`equivalence checking wiht yosys`](https://github.com/YosysHQ/eqy) and [`mutation cover with yosys`](https://github.com/YosysHQ/mcy) to validate its behavior.

A self-checking testbench (`lcompressor_tb.v`) is provided to verify the 1-cycle latency, reset behavior, pass-through, and clipping against the dynamic thresholds.

`mcy` spits out a report:

```
Database contains 4236 cached results.
Database contains 1412 cached "FAIL" results for "test_eq".
Database contains 1412 cached "FAIL" results for "test_fm".
Database contains 1412 cached "PASS" results for "test_sim".
Tagged 1412 mutations as "COVERED".
Tagged 1412 mutations as "FMONLY".
Coverage: 100.00%
```

Results:

The mutations the testbench can't catch (test_sim PASS), are either catched by equivalence checking or formal verification! And a `100%` coverage is achieved!

### Usage

Linux/macOS

```
# To run the Icarus Verilog testbench (Requires lcompressor.v and lcompressor_tb.v)
iverilog -o lcompressor.vvp lcompressor.v lcompressor_tb.v
vvp lcompressor.vvp
# For full mutation coverage testing, set up a proper test directory structure
# /$ cd test_rtl && ./test_all_log.sh
```

## Synthesis

A Yosys synthesis script can be used to generate the gate-level netlist.

```
=== lcompressor ===

        +----------Local Count, excluding submodules.
        | 
      202 wires
      417 wire bits
      202 public wires
      417 public wire bits
        8 ports
       68 port bits
      238 cells
       32   ALU
        1   DFFR
       16   DFFRE
        1   GND
       51   IBUF
       23   LUT1
        4   LUT2
       54   LUT4
       35   MUX2_LUT5
        2   MUX2_LUT6
        1   MUX2_LUT7
       17   OBUF
        1   VCC
```

Also, there's a Tang Nano 9k Gowin IDE project in `lcompressor/gowin/nano9k/lcompressor.gprj`, to check STA, but also, sofar unused.