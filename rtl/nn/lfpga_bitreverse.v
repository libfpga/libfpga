// libfpga :: lfpga_bitreverse — reverse the bit order of a vector (combinational)
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// dout[i] = din[WIDTH-1-i]. The addressing primitive behind FFT
// reorder stages and some CRC/LFSR reflections.

module lfpga_bitreverse #(
    parameter integer WIDTH = 16
) (
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : rev
            assign dout[i] = din[WIDTH-1-i];
        end
    endgenerate
endmodule
