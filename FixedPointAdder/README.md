# FixedPointAdder Module

This Verilog module implements a **parameterizable signed fixed-point adder** with **saturation logic** and an **overflow detection flag**. It is designed for applications requiring precise arithmetic with defined bit-widths, typical in Digital Signal Processing (DSP) hardware.

## Features

* **Configurable Width:** The `WIDTH` parameter allows easy adjustment of the total bit-width for operands and the result.

* **Signed Fixed-Point Arithmetic:** Performs addition on 2's complement signed fixed-point numbers.

* **Saturation Logic:** Prevents arithmetic overflow by clipping results to the maximum or minimum representable value within the defined `WIDTH`, instead of wrapping around.

* **Overflow Detection:** An `o_overflow` flag indicates when saturation has occurred, providing critical feedback for system monitoring and error handling.

* **Handshake Interface:** Includes standard `i_start`, `o_busy`, `o_done`, and `o_valid` signals for clear control and data readiness indication, designed for a single-cycle computation with 1-cycle latency.

## Validation

This module uses [`icarus verilog`](https://github.com/steveicarus/iverilog), [`symbiyosys`](https://github.com/YosysHQ/sby), [`equivalence checking wiht yosys`](https://github.com/YosysHQ/eqy) and [`mutation cover with yosys`](https://github.com/YosysHQ/mcy) to get a `100% mutation test coverage`!

With a mixture of simulation and formal verification, it's ensured that every and each mutation possible (894) are detected either by the testbench, equivalence checking or formal properties. A whitebox testing approach has been used both for testbench simulation and formal verification in order to catch internal module's mutations.

`mcy` spits out a report:

```
Database contains 2523 cached results.
Database contains 894 cached "FAIL" results for "test_eq".
Database contains 735 cached "FAIL" results for "test_fm".
Database contains 159 cached "FAIL" results for "test_sim".
Database contains 735 cached "PASS" results for "test_sim".
Tagged 894 mutations as "COVERED".
Tagged 735 mutations as "FMONLY".
  -> Print report
Coverage: 100.00%
```

## Usage

1.  **Instantiate the module:**

    ```
    FixedPointAdder #(
        .WIDTH(8),  // Example: 8-bit signed fixed-point numbers
        .FBITS(4)   // Example: 4 fractional bits (Q(8-4-1).4 = Q3.4 format)
    ) my_fixed_point_adder (
        .i_clk      (clk),        // Input clock
        .i_rst      (reset),      // Input reset (active high)
        .i_start    (start_pulse),// Input: Pulse high for one cycle to initiate addition
        .i_operandA (operand_a),  // Input: Signed fixed-point operand A
        .i_operandB (operand_b),  // Input: Signed fixed-point operand B
    
        .o_busy     (busy_flag),  // Output: High when operation is in progress (registered)
        .o_done     (done_flag),  // Output: High for one cycle when calculation is complete (registered)
        .o_valid    (valid_result),// Output: High for one cycle when o_val is valid (registered)
        .o_overflow (overflow_flag),// Output: High for one cycle if saturation occurred (registered)
        .o_val      (result_val)  // Output: Signed fixed-point result (saturated if overflowed)
    );
    
    ```

## Synthesis

There's a little yosys synth script in `FixedPointAdder/test_rtl/synth/FixedPointAdder/FixedPointAdder.ys` for Tang Nano 20k, but it's untested in Hardware.

```
=== FixedPointAdder ===

   Number of wires:                 48
   Number of wire bits:            107
   Number of public wires:          48
   Number of public wire bits:     107
   Number of ports:                 10
   Number of port bits:             31
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:                 64
     ALU                             9
     DFFR                            1
     DFFRE                           9
     GND                             1
     IBUF                           19
     LUT1                            1
     LUT2                            3
     LUT3                            8
     OBUF                           12
     VCC                             1
```

## References

* [Why DSP-Based Algorithms Need Special Attention in RTL Design](https://www.linkedin.com/pulse/why-dsp-based-algorithms-need-special-attention-rtl-design-eladawy-v3mmf/?trackingId=AEPhXm7Ye41DVtcrosiLFg%3D%3D)