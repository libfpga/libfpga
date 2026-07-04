// libfpga :: lfpga_popcount — count the set bits of a vector (combinational tree)
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Population count via a balanced adder tree the synthesizer builds from
// a simple loop. Useful for arbitration fairness, sparse encodings,
// hamming distance and neural-net binarized layers.

module lfpga_popcount #(
    parameter integer WIDTH = 8
) (
    input  wire [WIDTH-1:0]        din,
    output wire [$clog2(WIDTH):0]  count
);
    integer i;
    reg [$clog2(WIDTH):0] acc;
    always @* begin
        acc = 0;
        for (i = 0; i < WIDTH; i = i + 1)
            acc = acc + {{$clog2(WIDTH){1'b0}}, din[i]};
    end
    assign count = acc;
endmodule
