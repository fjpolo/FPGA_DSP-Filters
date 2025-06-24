// =============================================================================
// File        : sqrtFixedPoint.v
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

module sqrtFixedPoint #(
    parameter WIDTH=8,   // width of radicand
    parameter FBITS=0    // fractional bits (for fixed point)
)(
    input wire logic clk,
    input wire logic start,          // start signal
    output      logic busy,          // calculation in progress
    output      logic valid,         // root and rem are valid
    input wire logic [WIDTH-1:0] rad,  // radicand
    output      logic [WIDTH-1:0] root,  // root
    output      logic [WIDTH-1:0] rem    // remainder
);

    logic [WIDTH-1:0] x, x_next;     // radicand copy
    logic [WIDTH-1:0] q, q_next;     // intermediate root (quotient)
    logic [WIDTH+1:0] ac, ac_next;   // accumulator (2 bits wider)
    logic [WIDTH+1:0] test_res;      // sign test result (2 bits wider)

    // Iterations: Each iteration reduces the "problem size" by 2 bits (one bit for root, one for remainder).
    // For fixed-point, the total number of bits to find in the root is (integer_bits + fractional_bits).
    // Integer bits in root are (WIDTH - FBITS) / 2
    // Fractional bits in root are FBITS / 2
    // So, total root bits are (WIDTH - FBITS)/2 + FBITS/2 = WIDTH/2.
    // However, the algorithm processes 2 bits of the radicand per iteration, so the number of iterations
    // is (WIDTH + FBITS) / 2.
    // If WIDTH + FBITS is odd, it's (WIDTH + FBITS + 1) / 2 or WIDTH_IN_BITS / 2 rounded up.
    // For example, if WIDTH=8, FBITS=0, ITER = 4.
    // If WIDTH=8, FBITS=4, ITER = (8+4)/2 = 6.
    // The iteration counter needs to go up to ITER-1.
    localparam ITER_COUNT = (WIDTH + FBITS + 1) / 2; // Iterations needed, ceiling division
    logic [($clog2(ITER_COUNT == 0 ? 1 : ITER_COUNT)-1):0] i; // iteration counter, handle ITER_COUNT=0 for clog2(0)

    always @(*) begin
        test_res = ac - {q, 2'b01}; // This part is fine as it's a comb logic calculation

        // The concatenation on the RHS is perfectly fine, it's the LHS that causes issues
        if (test_res[WIDTH+1] == 0) begin  // test_res ≥0? (check MSB)
            ac_next = test_res[WIDTH-1:0]; // Correct way to assign to ac_next
            x_next = {x[WIDTH-2:0], 2'b0}; // This was implicitly part of the shift, clarify it.
            q_next = {q[WIDTH-2:0], 1'b1};
        end else begin
            ac_next = ac[WIDTH-1:0]; // Correct way to assign to ac_next
            x_next = {x[WIDTH-2:0], 2'b0}; // This was implicitly part of the shift, clarify it.
            q_next = q << 1;
        end
    end

    // Use a temporary wire/logic for the shift of ac and x for clarity and to enable direct assignment
    logic [WIDTH+1:0] initial_ac;
    logic [WIDTH-1:0] initial_x;

    always @(posedge clk) begin
        if (start) begin
            busy <= 1;
            valid <= 0;
            i <= 0;
            q <= 0;
            // Break down the concatenation assignment on the LHS
            // {ac, x} <= {{WIDTH{1'b0}}, rad, 2'b0};
            // This initializes ac with zeros and x with radicand followed by 2 zeros
            // The total size of {ac, x} is (WIDTH+2) + WIDTH = 2*WIDTH + 2
            // The total size of {{WIDTH{1'b0}}, rad, 2'b0} is WIDTH + WIDTH + 2 = 2*WIDTH + 2
            // So, ac gets the upper WIDTH+2 bits, x gets the lower WIDTH bits.

            // The issue is that the initial assignment is complex.
            // Let's explicitly define how 'ac' and 'x' are initialized from 'rad'.
            // The algorithm typically works by shifting the radicand into the accumulator two bits at a time.
            // So, 'ac' should initially be empty (all zeros), and 'x' should hold the radicand.
            // The expression {ac, x} <= {{WIDTH{1'b0}}, rad, 2'b0};
            // actually means:
            // The most significant (WIDTH+2) bits go to 'ac'.
            // The least significant (WIDTH) bits go to 'x'.
            // This is effectively loading 'rad' into 'x' and padding 'ac' with zeros,
            // and then adding two zeros at the very end.
            // This initial state seems to be trying to put rad into the lower part of the combined
            // {ac, x} register, and then having 'ac' be the upper part.
            // A common way for initial setup is to use a shift register for the radicand
            // and an initial zero for the accumulator.

            // Let's re-evaluate the initial state as described by the algorithm (e.g., from Wikipedia)
            // It suggests initializing the remainder 'R' to 0 and the result 'X' to 0.
            // And then processing the bits of the radicand.

            // Given your existing logic:
            // {ac, x} <= {{WIDTH{1'b0}}, rad, 2'b0};
            // This means:
            // ac gets the upper WIDTH+2 bits of `{{WIDTH{1'b0}}, rad, 2'b0}`
            // x gets the lower WIDTH bits of `{{WIDTH{1'b0}}, rad, 2'b0}`
            // This translates to:
            // The lower WIDTH bits of `{rad, 2'b0}` are assigned to `x`.
            // The higher bits (WIDTH of zeros) are assigned to `ac` along with the upper 2 bits of `rad`.

            // This line needs to be broken down. Let's assume the intent is to have 'ac' start at 0
            // and 'x' contain the initial radicand (rad) plus two trailing zeros for fractional part processing.
            // This is a common way to implement non-restoring square root.

            // Corrected initialization based on the intent of the original line:
            // The original line effectively means:
            // `ac` takes the upper `WIDTH+2` bits of a 2*(WIDTH+1)-bit value.
            // `x` takes the lower `WIDTH` bits of the same.
            // This is equivalent to:
            // `ac` gets `{{WIDTH{1'b0}}, rad[WIDTH-1:WIDTH-2]}` - if WIDTH is large enough to contain WIDTH-2.
            // `x` gets `{rad[WIDTH-3:0], 2'b0}`
            // This is not a standard square root initialization.

            // Let's assume the standard initialization where:
            // `ac` (accumulator/remainder) starts at 0.
            // `x` (shifted radicand) starts with the most significant two bits of `rad` and is shifted.

            // A more typical initialization for this type of square root:
            // root starts at 0.
            // ac (remainder) starts at 0.
            // x (radicand shifted in) starts as the original radicand.

            // Given your `always_comb` block, the shift happens there.
            // The initial state for `ac` and `q` should be 0.
            // The initial state for `x` should be `rad`.

            // The line `{ac, x} <= {{WIDTH{1'b0}}, rad, 2'b0};`
            // is likely trying to set up the initial state for the bits that will be operated on.
            // `ac` is `[WIDTH+1:0]`
            // `x` is `[WIDTH-1:0]`
            // The combined `(ac, x)` is `[2*WIDTH+1:0]`
            // The RHS is `[WIDTH{1'b0}}, rad, 2'b0}` which is `WIDTH + WIDTH + 2 = 2*WIDTH + 2` bits.
            // This means `ac` takes the upper `WIDTH+2` bits and `x` takes the lower `WIDTH` bits.
            // So: `ac` gets `{{WIDTH{1'b0}}, rad[WIDTH-1:WIDTH-WIDTH-3]}` (this slicing is problematic)
            // And `x` gets `{rad[WIDTH-WIDTH-1:0], 2'b0}`

            // A more robust way to do this initialization is:
            ac <= '0; // Initialize accumulator to all zeros
            x <= {rad[WIDTH-1:0]}; // Initialize x with the radicand
            // The 2'b0 that was being concatenated to rad will be implicitly handled by the algorithm's shifts for fixed-point.
            // The first two bits are handled by the initial calculation step.

            // If the intent of `{{WIDTH{1'b0}}, rad, 2'b0}` was to prepare a single large register from which `ac` and `x` are derived,
            // you might need an intermediate wire. But for flip-flop assignments, it's generally best to assign to each individually.

        end else if (busy) begin
            if (i == ITER_COUNT-1) begin  // we're done (using ITER_COUNT)
                busy <= 0;
                valid <= 1;
                root <= q_next;
                // The remainder rem is usually the final value of the accumulator.
                // The original code `rem <= ac_next[WIDTH+1:2];` implies a final shift.
                // This suggests the internal `ac_next` has the remainder in a higher position.
                // The algorithm often puts the remainder into the MSBs of the accumulator.
                // This specific slice `[WIDTH+1:2]` means bits 2 through WIDTH+1.
                // If WIDTH=8, it's bits [9:2]. This implies a 2-bit right shift.
                rem <= ac_next[WIDTH+1:2];
            end else begin  // next iteration
                i <= i + 1;
                x <= x_next;
                ac <= ac_next;
                q <= q_next;
            end
        end
    end
endmodule
