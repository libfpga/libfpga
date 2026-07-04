// libfpga :: lfpga_relu — ReLU-family activation with resize+saturate to the output format
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Combinational activation: takes a wide accumulator (Q.ACC_F), applies
// the nonlinearity, then requantizes to the layer's Q(OUT_W.OUT_F).
// KIND: 0 = ReLU (max 0), 1 = leaky ReLU (>>3 for negatives),
// 2 = clipped ReLU (upper bound at the output max, i.e. ReLU6-style).

module lfpga_relu #(
    parameter integer ACC_W = 32,
    parameter integer ACC_F = 8,
    parameter integer OUT_W = 8,
    parameter integer OUT_F = 4,
    parameter integer KIND  = 0
) (
    input  wire signed [ACC_W-1:0] din,
    output wire signed [OUT_W-1:0] dout
);
    reg signed [ACC_W-1:0] act;
    always @* begin
        if (din >= 0)         act = din;
        else if (KIND == 1)   act = din >>> 3;   // leaky (signed shift)
        else                  act = {ACC_W{1'b0}};
    end

    wire signed [OUT_W-1:0] rs;
    lfpga_fix_resize #(.IN_W(ACC_W), .IN_F(ACC_F),
                       .OUT_W(OUT_W), .OUT_F(OUT_F))
        u_rs (.din(act), .dout(rs));

    // clipped ReLU: cap at output max (already saturated by resize, but
    // for KIND=2 the upper cap is the point)
    assign dout = rs;
endmodule
