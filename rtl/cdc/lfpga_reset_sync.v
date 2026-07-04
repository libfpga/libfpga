// libfpga :: lfpga_reset_sync — reset synchronizer: async assert, sync deassert
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// The standard FPGA reset recipe. Assertion is asynchronous (works with no
// clock running); deassertion is synchronized so every flop in the domain
// leaves reset in the same cycle. Instantiate one per clock domain, all
// fed from the same asynchronous source (board reset AND pll_locked).
//
// Timing: constrain the async input as a false path; the synchronizer
// satisfies recovery/removal on the release edge by construction.

module lfpga_reset_sync #(
    parameter integer STAGES = 2
) (
    input  wire clk,
    input  wire rst_async_n,  // asynchronous reset source, active low
    output wire rst_sync_n    // domain reset, async assert / sync deassert
);
    (* ASYNC_REG = "TRUE" *) reg [STAGES-1:0] ff = {STAGES{1'b0}};

    always @(posedge clk or negedge rst_async_n)
        if (!rst_async_n) ff <= {STAGES{1'b0}};
        else              ff <= {ff[STAGES-2:0], 1'b1};

    assign rst_sync_n = ff[STAGES-1];

endmodule
