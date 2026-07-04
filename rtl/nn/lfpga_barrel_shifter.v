// libfpga :: lfpga_barrel_shifter — single-cycle barrel shifter: logical/arith, left/right, any amount
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Shifts din by `amt` in one cycle (synthesizes to a barrel network).
// dir: 0 left, 1 right. arith: 1 = arithmetic right (sign-extend).
// Used for scaling in fixed-point pipelines and shift-based multiply.

module lfpga_barrel_shifter #(
    parameter integer WIDTH = 16
) (
    input  wire [WIDTH-1:0]        din,
    input  wire [$clog2(WIDTH)-1:0] amt,
    input  wire                    dir,    // 0 left, 1 right
    input  wire                    arith,  // right-shift sign extension
    output wire [WIDTH-1:0]        dout
);
    // Written with the shift operators: synthesis maps these to exactly
    // the log2(WIDTH)-stage barrel network, and the tools time it well.
    // (Same philosophy as writing `*` for a multiplier.)
    wire signed [WIDTH-1:0] sdin = din;
    wire [WIDTH-1:0] right_a = sdin >>> amt;   // arithmetic (sign-extend)
    wire [WIDTH-1:0] right_l = din  >>  amt;   // logical (zero-fill)
    wire [WIDTH-1:0] right   = arith ? right_a : right_l;
    assign dout = dir ? right : (din << amt);
endmodule
