// libfpga :: lfpga_edge_detect — rising/falling/any edge pulses for a synchronous signal
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// One-cycle pulses on each kind of transition. The input must already
// be synchronous (use lfpga_sync_bit first for async sources).

module lfpga_edge_detect (
    input  wire clk,
    input  wire rst,
    input  wire din,
    output wire rise,
    output wire fall,
    output wire toggle
);
    reg prev;
    always @(posedge clk)
        if (rst) prev <= 1'b0;
        else     prev <= din;

    assign rise   = din & ~prev;
    assign fall   = ~din & prev;
    assign toggle = din ^ prev;
endmodule
