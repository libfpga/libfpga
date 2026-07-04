// libfpga :: lfpga_mac — signed multiply-accumulate: the atom of every neural network
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Registered MAC. Each enabled cycle: acc += a * b. clr resets the
// accumulator before a new dot product. Multiply narrow (W-bit inputs),
// accumulate wide (ACC_W-bit) so no rounding happens until you read it
// out and resize: https://libfpga.com/blog/how-many-bits
// This is the compute cell the neural micro-kit tiles into arrays.

module lfpga_mac #(
    parameter integer W     = 8,
    parameter integer ACC_W = 32
) (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    clr,   // clear acc this cycle
    input  wire                    en,    // accumulate a*b this cycle
    input  wire signed [W-1:0]     a,
    input  wire signed [W-1:0]     b,
    output reg  signed [ACC_W-1:0] acc
);
    wire signed [2*W-1:0] prod = a * b;

    always @(posedge clk) begin
        if (rst || clr)
            acc <= {ACC_W{1'b0}};
        else if (en)
            acc <= acc + {{(ACC_W-2*W){prod[2*W-1]}}, prod};
    end
endmodule
