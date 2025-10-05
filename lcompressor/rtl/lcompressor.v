// =============================================================================
// File        : lcompressor.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Basic linear compressor
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

module lcompressor #(
    // --- Format Parameters ---
    parameter W_TOTAL = 16,     // Total bit width (Q1.15)
    parameter W_FRAC = 15,      // Fractional bit width
    
    // --- Control Parameters (Linear Fixed-Point) ---
    // Threshold is a linear magnitude (e.g., 0.5 for -6dB)
    parameter THRESHOLD_LIN = 16'h4000, // Q1.15(0.5)
    parameter RATIO_NUM = 4,
    parameter ATTACK_COEFF_FP = 16'h1000, // (1-alpha) in Q0.15 format
    parameter RELEASE_COEFF_FP = 16'h0050 // (1-alpha) in Q0.15 format
) (
    input   wire            [0:0]           i_clk,
    input   wire            [0:0]           i_reset_n,
    input   wire            [0:0]           i_ce,           
    input   wire    signed  [W_TOTAL-1:0]   i_data, // Q1.15 signed audio input
    output  reg     signed  [W_TOTAL-1:0]   o_data, // Q1.15 signed audio output
    output  wire            [0:0]           o_ce                     
);

// --- Local Parameters and Constants ---

// Pre-calculated: (1/Ratio) in Q0.15 format
localparam R_RECIP = (1 << W_FRAC) / RATIO_NUM; // Q0.15 format (e.g., 0.25 -> 16'h2000)

// Pre-calculated: (1 - 1/Ratio) in Q0.15 format
localparam R_DIFF = (1 << W_FRAC) - R_RECIP; 

// assigning o_ce: this will only be high when pipeline stage 5 is done, depends on i_ce
reg r_ce_1, r_ce_2, r_ce_3, r_ce_45;
initial r_ce_1 = 1'b0;
initial r_ce_2 = 1'b0;
initial r_ce_3 = 1'b0;
initial r_ce_45 = 1'b0;
assign  o_ce = r_ce_45;

//
// --- Stage 1: Input Conditioning ---
//
wire signed [W_TOTAL-1:0] lin_mag_piped_1;

// 1a. Absolute Value (Magnitude)
// Convert signed Q1.15 input to unsigned Q1.15 magnitude
assign lin_mag_piped_1 = (i_data[W_TOTAL-1]) ? (-(i_data)) : i_data; 

// --- Pipeline Registers after Stage 1 ---
reg signed [W_TOTAL-1:0] r_lin_mag_piped_1; // Linear magnitude
reg signed [W_TOTAL-1:0] r_data_1;       // Raw data

always @(posedge i_clk) begin
    if (!i_reset_n) begin
        r_lin_mag_piped_1 <= {W_TOTAL{1'b0}};
        r_data_1 <= {W_TOTAL{1'b0}};
    end else if (i_ce) begin
        r_lin_mag_piped_1 <= lin_mag_piped_1;
        r_data_1 <= i_data;
    end
end

// r_ce_1
always @(posedge i_clk) begin
    r_ce_1 <= i_ce;
    if(!i_reset_n)
        r_ce_1 <= 1'b0;
end

//
// --- Stage 2: Envelope Detection (One-Pole IIR on Linear Magnitude) ---
//
reg signed [W_TOTAL-1:0] r_lin_env_2; // Current envelope state (y[n-1])
wire signed [W_TOTAL-1:0] env_diff;      // (x[n] - y[n-1])
// verilator lint_off UNUSEDSIGNAL
wire signed [W_TOTAL + W_FRAC - 1:0] product_term;
// verilator lint_on UNUSEDSIGNAL

// 2a. Determine Coefficient (Attack/Release comparison in Linear domain)
wire [W_FRAC:0] alpha_term; // (1-alpha)
assign alpha_term = (r_lin_mag_piped_1 > r_lin_env_2) ? ATTACK_COEFF_FP : RELEASE_COEFF_FP;

// 2b. IIR Calculation (y[n] = y[n-1] + (x[n] - y[n-1]) * (1-alpha))
assign env_diff = r_lin_mag_piped_1 - r_lin_env_2;

// Multiplication: Q1.15 * Q0.15 = Q1.30 -> shift right by W_FRAC (15) to get Q1.15 update term
assign product_term = $signed(env_diff) * $signed(alpha_term);

wire signed [W_TOTAL-1:0] update_term = product_term[W_TOTAL + W_FRAC - 1 : W_FRAC]; 
wire signed [W_TOTAL-1:0] lin_env_next = r_lin_env_2 + update_term;

reg signed [W_TOTAL-1:0] r_data_2;

always @(posedge i_clk) begin
    if (!i_reset_n) begin
        r_lin_env_2 <= {W_TOTAL{1'b0}}; 
        r_data_2 <= {W_TOTAL{1'b0}};
    end else if (r_ce_1) begin
        r_lin_env_2 <= lin_env_next;
        r_data_2 <= r_data_1;
    end
end

// r_ce_2
always @(posedge i_clk) begin
    r_ce_2 <= r_ce_1;
    if(!i_reset_n)
        r_ce_2 <= 1'b0;
end

//
// --- Stage 3: Static Gain Calculation ---
//
reg signed [W_TOTAL-1:0] linear_gain_reg3; // Q1.15 gain multiplier
reg signed [W_TOTAL-1:0] data_reg3;

// The linear gain is calculated as: Gain = (Threshold / Envelope)^(1 - 1/Ratio) * 1/Ratio
// This is still complex. A common simplification for linear compressors is:
// Target Gain = 1.0 - (Envelope - Threshold) * (1 - 1/Ratio) / Envelope
// Since division is costly, we use the standard linear VCA equation:
// VCA Gain = (1/R) + (1 - 1/R) * (Threshold / Envelope)
// Since division is costly, we approximate or use a simple LUT for (Threshold / Envelope).

// Simple Approximation: Only compress by the difference (used in some legacy designs)
// Target Gain = 1.0 - (Envelope - Threshold) * (1 - 1/Ratio)  - This works poorly tho

// Stick to the simplest *ratio*-based gain where $\text{Gain = {Input}^{1/R-1} \cdot \text{Threshold}^{1-1/R}$
// A pure linear calculation requires a **Reciprocal-LUT** for (1/Envelope).

// Assuming we have a RECIPROCAL_LUT for simplicity:
// verilator lint_off UNUSEDSIGNAL
wire signed [W_TOTAL-1:0] recip_env; // 1/Envelope
// verilator lint_on UNUSEDSIGNAL
// RECIPROCAL_LUT i_recip (.i_input(r_lin_env_2), .o_recip(recip_env));

// Final Linear Gain:
// Since division/exponentiation is removed, we must pick a gain formula that works with basic math:
// Let's choose a simplified form: Linear\_Gain = 1.0 - $\text{Compression\_Depth}$

wire signed [W_TOTAL-1:0] overshoot = r_lin_env_2 - THRESHOLD_LIN;

// Compression_Depth = Overshoot * (1 - 1/Ratio)
// Q1.15 * Q0.15 = Q1.30 -> shift to Q1.15
// verilator lint_off UNUSEDSIGNAL
wire signed [W_TOTAL + W_TOTAL - 1:0] depth_product_full = $signed(overshoot) * $signed(R_DIFF); 
// verilator lint_on UNUSEDSIGNAL
wire signed [W_TOTAL-1:0] compression_depth = depth_product_full[W_TOTAL + W_FRAC - 1 : W_FRAC]; 

wire signed [W_TOTAL-1:0] target_gain = (1 << W_FRAC) - compression_depth; // 1.0 - Compression_Depth

always @(posedge i_clk) begin
    if (r_ce_2) begin
        // Only apply gain reduction if the signal is above threshold and overshoot > 0
        linear_gain_reg3 <= (r_lin_env_2 > THRESHOLD_LIN) ? target_gain : (1 << W_FRAC); // 1.0
        data_reg3 <= r_data_2;
    end
end

// r_ce_2
always @(posedge i_clk) begin
    r_ce_3 <= r_ce_2;
    if(!i_reset_n)
        r_ce_3 <= 1'b0;
end

//
// --- Stage 4 & 5: Pass-Through and Application ---
//
reg signed [W_TOTAL-1:0] data_reg4;

always @(posedge i_clk) begin
    if (r_ce_3) begin
        data_reg4 <= data_reg3;
    end
end

// Final Multiplier: Output = Data * Linear_Gain
// Q1.15 * Q1.15 = Q2.30 -> shift to Q1.15
// verilator lint_off UNUSEDSIGNAL
wire signed [W_TOTAL + W_TOTAL - 1:0] final_product = $signed(data_reg4) * $signed(linear_gain_reg3);
// verilator lint_on UNUSEDSIGNAL
wire signed [W_TOTAL-1:0] output_data = final_product[W_TOTAL + W_FRAC - 1 : W_FRAC];

always @(posedge i_clk) begin
    if (!i_reset_n) begin
        o_data <= {W_TOTAL{1'b0}};
    end else if (r_ce_3) begin
        o_data <= output_data;
    end
end

// r_ce_45
always @(posedge i_clk) begin
    r_ce45 <= r_ce_3;
    if(!i_reset_n)
        r_ce_45 <= 1'b0;
end

endmodule
