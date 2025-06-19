# simpleFixedPointUnsignedLongDivision Module

This Verilog module implements an iterative unsigned long division algorithm for fixed-point numbers. It supports user-definable width and fractional bit parameters. The module provides flags for busy status, calculation completion, result validity, divide-by-zero, and overflow.

## Features

* **Configurable Width:** `WIDTH` parameter allows setting the total bit width for input numbers and the output quotient.
* **Configurable Fractional Bits:** `FBITS` parameter specifies the number of fractional bits within the `WIDTH`, enabling fixed-point arithmetic.
* **Iterative Long Division:** Implements a classic long division algorithm suitable for hardware synthesis.
* **Status and Error Flags:**
    * `o_busy`: Indicates when a calculation is in progress.
    * `o_done`: Pulses high for one clock cycle when a calculation completes.
    * `o_valid`: Indicates that the `o_val` output contains a valid result.
    * `o_dbz`: Goes high if a division by zero is attempted.
    * `o_ovf`: Goes high if an overflow occurs (the integer part of the result exceeds the allocated bits).
* **Asynchronous Reset:** Resets all internal states and outputs when `i_rst` is high.

## Usage

1.  **Instantiate the module:**

    ```verilog
    simpleFixedPointUnsignedLongDivision #(
        .WIDTH(16), // Example: 16-bit total width
        .FBITS(8)   // Example: 8 fractional bits
    ) simpleFixedPointUnsignedLongDivision (
        .i_clk(i_clk),      // Input - Clock
        .i_rst(i_rst),      // Input - Asynchronous Reset
        .i_start(i_start),  // Input - Assert to start calculation
        .o_busy(o_busy),    // Output - Calculation in progress
        .o_done(o_done),    // Output - Calculation complete (one-tick pulse)
        .o_valid(o_valid),  // Output - Result is valid
        .o_dbz(o_dbz),      // Output - Divide by zero flag
        .o_ovf(o_ovf),      // Output - Overflow flag
        .a(a),              // Input - Dividend (numerator)
        .b(b),              // Input - Divisor (denominator)
        .o_val(o_val)       // Output - Result value: quotient
    );
    ```