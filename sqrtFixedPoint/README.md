# sqrtFixedPoint Module

This Verilog module implements a **fixed-point square root calculator** using an iterative, sequential algorithm (likely a non-restoring type due to the `ac` and `q` logic). It processes an input radicand (`rad`) over several clock cycles to produce its square root (`root`) and a remainder (`rem`), signaling completion with `valid` and busy status with `busy`.

## Features

* **Configurable Width:** Supports different bit-widths for the radicand via the `WIDTH` parameter.
* **Fixed-Point Support:** Includes `FBITS` parameter to specify the number of fractional bits, enabling fixed-point number square root calculations.
* **Iterative Design:** Computes the square root over multiple clock cycles, making it suitable for resource-constrained FPGAs.
* **Start/Busy/Valid Interface:** Provides a standard handshake interface for controlling the calculation and indicating result availability.
* **Remainder Output:** Outputs both the square root and the remainder, which can be useful for precision analysis or specific numerical applications.

## Usage

1.  **Instantiate the module:**

    ```verilog
    sqrtFixedPoint #(
        .WIDTH(16), // Example: 16-bit radicand
        .FBITS(8)   // Example: 8 fractional bits (Q8.8 format)
    ) my_sqrt_instance (
        .clk(clk_i),     // Input clock
        .start(start_i), // Input: Assert to begin calculation
        .busy(busy_o),   // Output: High when calculation is in progress
        .valid(valid_o), // Output: High when root and rem are valid
        .rad(rad_i),     // Input: The radicand (fixed-point number)
        .root(root_o),   // Output: The calculated fixed-point square root
        .rem(rem_o)      // Output: The remainder of the square root
    );
    ```

## References

-   [Square Root in Verilog](https://projectf.io/posts/square-root-in-verilog/)