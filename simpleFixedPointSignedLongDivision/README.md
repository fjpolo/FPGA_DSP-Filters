# simpleFixedPointSignedLongDivision Module

This Verilog module implements a **signed fixed-point long division algorithm** suitable for hardware synthesis. It provides a robust solution for dividing signed numbers with a configurable number of integer and fractional bits, handling cases like division by zero and overflow, and incorporating Gaussian rounding for accuracy.

---

## Features

* **Configurable Width:** Supports user-defined `WIDTH` (total bits) and `FBITS` (fractional bits) for flexible fixed-point precision.
* **Signed Division:** Handles division of signed numbers.
* **Asynchronous Reset:** Includes an active-high asynchronous reset (`i_rst`).
* **Handshake Interface:** Uses `i_start`, `o_busy`, `o_done`, and `o_valid` signals for clear control flow.
* **Error Detection:** Provides `o_dbz` (divide by zero) and `o_ovf` (overflow) flags.
* **Gaussian Rounding:** Implements "round half to even" for improved numerical accuracy.

---

## Usage

1.  **Instantiate the module:**

    ```verilog
    simpleFixedPointSignedLongDivision #(
        .WIDTH(16), // Example: 16-bit total width
        .FBITS(8)   // Example: 8 fractional bits
    ) simpleFixedPointSignedLongDivision (
        .i_clk(i_clk),       // Input clock
        .i_rst(i_rst),       // Input - asynchronous reset (active high)
        .i_start(i_start),   // Input - assert to start calculation
        .o_busy(o_busy),     // Output - high when calculation is in progress
        .o_done(o_done),     // Output - high for one cycle when calculation completes
        .o_valid(o_valid),   // Output - high when o_val contains a valid result
        .o_dbz(o_dbz),       // Output - high if division by zero occurred
        .o_ovf(o_ovf),       // Output - high if overflow occurred
        .a(a),               // Input - dividend (numerator)
        .b(b),               // Input - divisor (denominator)
        .o_val(o_val)        // Output - result (quotient)
    );
    ```

---

## References

-   [Division in Verilog](https://projectf.io/posts/division-in-verilog/)