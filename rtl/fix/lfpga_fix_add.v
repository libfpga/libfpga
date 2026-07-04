// libfpga :: lfpga_fix_add — signed fixed-point add/sub with saturation
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Same-format signed add or subtract, saturating instead of wrapping on
// overflow. sub=1 computes a - b.

module lfpga_fix_add #(
    parameter integer W = 8
) (
    input  wire signed [W-1:0] a,
    input  wire signed [W-1:0] b,
    input  wire                sub,
    output reg  signed [W-1:0] s
);
    wire signed [W:0] r = sub ? ($signed(a) - $signed(b))
                              : ($signed(a) + $signed(b));
    localparam signed [W:0] MAXV = {2'b00, {(W-1){1'b1}}};
    localparam signed [W:0] MINV = {2'b11, {(W-1){1'b0}}};

    always @* begin
        if (r > MAXV)      s = MAXV[W-1:0];
        else if (r < MINV) s = MINV[W-1:0];
        else               s = r[W-1:0];
    end
endmodule
