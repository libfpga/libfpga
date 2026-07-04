// libfpga :: lfpga_onehot_mux — AND-OR mux with a one-hot select (fast, no priority logic)
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// When the select is guaranteed one-hot (arbiter grants!), an AND-OR
// mux beats a binary mux tree: flat, fast, and X-safe by construction
// (zero select -> zero output). Pairs with lfpga_arbiter_rr.

module lfpga_onehot_mux #(
    parameter integer WIDTH = 8,   // data width
    parameter integer N     = 4    // number of inputs
) (
    input  wire [N*WIDTH-1:0] din,  // input j at din[j*WIDTH +: WIDTH]
    input  wire [N-1:0]       sel,  // one-hot
    output wire [WIDTH-1:0]   dout
);
    integer j;
    reg [WIDTH-1:0] acc;
    always @* begin
        acc = {WIDTH{1'b0}};
        for (j = 0; j < N; j = j + 1)
            acc = acc | (din[j*WIDTH +: WIDTH] & {WIDTH{sel[j]}});
    end
    assign dout = acc;
endmodule
