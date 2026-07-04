// libfpga :: lfpga_clkdiv_frac — fractional-rate clock ENABLE via phase accumulator
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Emits enable pulses at f_clk * INC / 2^WIDTH on average - fractional
// rates with no PLL and no derived clock (see why enables beat divided
// clocks: libfpga.com/tools/clock-divider). Jitter is +/-1 clk period.

module lfpga_clkdiv_frac #(
    parameter integer WIDTH = 16,
    parameter [63:0]  INC   = 6554   // ~0.1 * 2^16
) (
    input  wire clk,
    input  wire rst,
    input  wire en,
    output reg  tick
);
    reg [WIDTH-1:0] acc;
    wire [WIDTH:0] sum = {1'b0, acc} + {1'b0, INC[WIDTH-1:0]};

    always @(posedge clk) begin
        if (rst) begin
            acc  <= {WIDTH{1'b0}};
            tick <= 1'b0;
        end else if (en) begin
            acc  <= sum[WIDTH-1:0];
            tick <= sum[WIDTH];        // carry out = one tick
        end else begin
            tick <= 1'b0;
        end
    end
endmodule
