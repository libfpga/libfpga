// libfpga :: lfpga_fix_resize — requantize a signed fixed-point word (shift + round + saturate)
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Convert Q(IW.IF) -> Q(OW.OF): align the binary point (arithmetic
// shift, with round-to-nearest when discarding fraction bits), then
// saturate into the output width instead of wrapping. The single most
// reused operation in a fixed-point datapath.

module lfpga_fix_resize #(
    parameter integer IN_W  = 16,
    parameter integer IN_F  = 8,
    parameter integer OUT_W = 8,
    parameter integer OUT_F = 4
) (
    input  wire signed [IN_W-1:0]  din,
    output reg  signed [OUT_W-1:0] dout
);
    localparam integer SH = IN_F - OUT_F;   // >0: drop frac bits (round)
    // wide enough to hold the shifted value before saturation
    localparam integer WW = IN_W + (OUT_F > IN_F ? OUT_F - IN_F : 0) + 2;

    reg signed [WW-1:0] shifted;
    localparam signed [WW-1:0] MAXV = {{(WW-OUT_W+1){1'b0}}, {(OUT_W-1){1'b1}}};
    localparam signed [WW-1:0] MINV = ~MAXV;   // -2^(OUT_W-1)

    always @* begin
        if (SH > 0) begin
            // round half up (toward +inf): add half an LSB, then shift
            shifted = ($signed({{(WW-IN_W){din[IN_W-1]}}, din})
                       + (SH > 0 ? (1 <<< (SH-1)) : 0)) >>> SH;
        end else begin
            shifted = $signed({{(WW-IN_W){din[IN_W-1]}}, din}) <<< (-SH);
        end
        if (shifted > MAXV)      dout = MAXV[OUT_W-1:0];
        else if (shifted < MINV) dout = MINV[OUT_W-1:0];
        else                     dout = shifted[OUT_W-1:0];
    end
endmodule
