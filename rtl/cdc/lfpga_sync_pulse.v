// libfpga :: lfpga_sync_pulse — toggle-based pulse synchronizer between clock domains
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Carries a single-cycle pulse from clk_src to clk_dst in either direction
// (fast-to-slow or slow-to-fast): the pulse is converted to a level toggle,
// which crosses safely, and back to a pulse.
//
// Constraint: source pulses must be spaced at least STAGES+1 clk_dst
// cycles apart, or pulses will merge. Need faster? Use an async FIFO.

module lfpga_sync_pulse #(
    parameter integer STAGES = 2
) (
    input  wire clk_src,
    input  wire pulse_src,   // 1-cycle pulse in the source domain
    input  wire clk_dst,
    output wire pulse_dst    // 1-cycle pulse in the destination domain
);
    reg toggle = 1'b0;
    always @(posedge clk_src)
        if (pulse_src) toggle <= ~toggle;

    (* ASYNC_REG = "TRUE" *) reg [STAGES:0] ff = {(STAGES+1){1'b0}};
    always @(posedge clk_dst)
        ff <= {ff[STAGES-1:0], toggle};

    assign pulse_dst = ff[STAGES] ^ ff[STAGES-1];

endmodule
