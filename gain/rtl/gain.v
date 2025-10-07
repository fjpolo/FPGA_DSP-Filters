// =============================================================================
// File        : gain.v
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Digital Gain Module with configurable data width,
//               fixed-point arithmetic, and clipping detection.
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

module gain #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 13
) (
    input wire i_clk,
    input wire i_reset_n,
    input wire i_ce,
    input wire [DATA_WIDTH-1:0] i_data,
    input wire [16:0] i_gain_coeff,
    output wire o_ce,
    output wire [DATA_WIDTH-1:0] o_data,
    output wire o_pos_clip,
    output wire o_neg_clip
);

    // Internal registers
    reg signed [(2*DATA_WIDTH):0] product_reg;
    reg o_ce_reg;
    reg pos_clip_reg;
    reg neg_clip_reg;

    // Constants
    localparam signed [DATA_WIDTH-1:0] MAX_AUDIO_VAL = (1 << (DATA_WIDTH - 1)) - 1;
    localparam signed [DATA_WIDTH-1:0] MIN_AUDIO_VAL = -(1 << (DATA_WIDTH - 1));
    localparam PRODUCT_WIDTH = (2*DATA_WIDTH);

    localparam signed [PRODUCT_WIDTH-1:0] SCALED_MAX = MAX_AUDIO_VAL * (1 << FRAC_BITS);
    localparam signed [PRODUCT_WIDTH-1:0] SCALED_MIN = MIN_AUDIO_VAL * (1 << FRAC_BITS);

    // Immediate product calculation
    wire signed [PRODUCT_WIDTH-1:0] immediate_product = $signed(i_data) * $signed(i_gain_coeff);
    
    // Immediate clipping detection
    wire immediate_pos_clip = (immediate_product > SCALED_MAX) & i_ce;
    wire immediate_neg_clip = (immediate_product < SCALED_MIN) & i_ce;

    // Output assignments
    assign o_ce = o_ce_reg;
    assign o_pos_clip = pos_clip_reg;
    assign o_neg_clip = neg_clip_reg;
    
    // Output data with saturation
    assign o_data = pos_clip_reg ? MAX_AUDIO_VAL :
                   neg_clip_reg ? MIN_AUDIO_VAL :
                   (product_reg >>> FRAC_BITS);

    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            product_reg <= 0;
            o_ce_reg <= 0;
            pos_clip_reg <= 0;
            neg_clip_reg <= 0;
        end else begin
            o_ce_reg <= i_ce;
            if (i_ce) begin
                // Register the product
                product_reg <= immediate_product;
                // Register clipping flags
                pos_clip_reg <= immediate_pos_clip;
                neg_clip_reg <= immediate_neg_clip;
            end else begin
                pos_clip_reg <= 0;
                neg_clip_reg <= 0;
            end
        end
    end
endmodule
