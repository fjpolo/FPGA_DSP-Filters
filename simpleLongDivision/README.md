# `simpleLongDivision` Module

This Verilog module implements a synchronous, iterative long division algorithm. It calculates both the quotient and the remainder for two unsigned integers. The module is parameterized by `WIDTH`, allowing it to perform division on numbers of various bit-widths.

## Features

* **Parameterized Width:** The `WIDTH` parameter allows for flexible division of operands with different bit lengths (e.g., 8-bit, 16-bit, 32-bit).
* **Synchronous Operation:** All state changes are controlled by a single clock edge (`i_clk`).
* **Handshake Interface:** Uses `i_start`, `o_busy`, `o_done`, and `o_valid` signals for clear control flow and result availability.
* **Divide-by-Zero Detection:** Includes logic to detect and flag division by zero using the `o_dbz` output.
* **Quotient and Remainder Outputs:** Provides both the `o_result_quotient` and `o_result_remainder` upon completion of the calculation.

## Usage

1.  **Instantiate the module:**

    ```verilog
    simpleLongDivision #(
        .WIDTH (8) // Example: 8-bit division. Adjust as needed.
    ) simpleLongDivision_inst (
        .i_clk              (clk),              // Input: Clock
        .i_rst              (rst),              // Input: Reset (active high)
        .i_start            (start_calc),       // Input: Assert high for one cycle to start
        .i_operandA         (dividend_in),      // Input: Dividend (Numerator)
        .i_operandB         (divisor_in),       // Input: Divisor (Denominator)
        .o_busy             (calculation_busy), // Output: High when calculation is in progress
        .o_dbz              (divide_by_zero),   // Output: High if divisor was zero
        .o_done             (calculation_done), // Output: High for one clock cycle when calculation finishes
        .o_valid            (result_valid),     // Output: High when o_result_quotient/remainder are valid
        .o_result_quotient  (quotient_out),     // Output: Calculated quotient
        .o_result_remainder (remainder_out)     // Output: Calculated remainder
    );
    ```

2.  **Control Flow:**
    * Assert `i_start` high for one clock cycle to initiate a division.
    * Monitor `o_busy`; it will go high when the calculation starts and low when it finishes.
    * `o_done` will pulse high for one clock cycle when the calculation is complete.
    * `o_valid` will go high (and stay high until a new `i_start`) when the results at `o_result_quotient` and `o_result_remainder` are ready.
    * Check `o_dbz` after `o_done` pulses to see if a divide-by-zero occurred. If `o_dbz` is high, the results are undefined.
    * `i_rst` is an asynchronous active-high reset, which will immediately clear all outputs and internal state.

## Inputs and Outputs

* `i_clk`: Clock input.
* `i_rst`: Asynchronous reset input (active high).
* `i_start`: Synchronous pulse input to initiate a new division.
* `i_operandA`: Dividend (numerator), `WIDTH` bits wide.
* `i_operandB`: Divisor (denominator), `WIDTH` bits wide.
* `o_busy`: Output, indicates when a calculation is in progress.
* `o_dbz`: Output, high if `i_operandB` was zero at the start of the calculation.
* `o_done`: Output, pulses high for one clock cycle when a calculation completes.
* `o_valid`: Output, high when `o_result_quotient` and `o_result_remainder` hold valid results.
* `o_result_quotient`: Output, the calculated quotient.
* `o_result_remainder`: Output, the calculated remainder.

## References

-   [Division in Verilog](https://projectf.io/posts/division-in-verilog/)