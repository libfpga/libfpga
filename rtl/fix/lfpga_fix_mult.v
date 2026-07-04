// libfpga :: lfpga_fix_mult — signed fixed-point multiply with resize + saturate
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Q(W.AF) x Q(W.BF) -> full-precision product, then requantize to
// Q(W.OF) via lfpga_fix_resize. Multiply narrow, keep the wide product,
// resize once: https://libfpga.com/blog/how-many-bits

module lfpga_fix_mult #(
    parameter integer W  = 8,
    parameter integer AF = 4,     // a's fraction bits
    parameter integer BF = 4,     // b's fraction bits
    parameter integer OF = 4      // output fraction bits
) (
    input  wire signed [W-1:0] a,
    input  wire signed [W-1:0] b,
    output wire signed [W-1:0] p
);
    wire signed [2*W-1:0] prod = a * b;   // Q(.(AF+BF))

    lfpga_fix_resize #(.IN_W(2*W), .IN_F(AF+BF), .OUT_W(W), .OUT_F(OF))
        u_rs (.din(prod), .dout(p));
endmodule
