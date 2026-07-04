// libfpga :: lfpga_sync_bit — N-flop synchronizer for a single-bit LEVEL signal
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Use for one asynchronous LEVEL bit entering clk's domain. NOT for buses:
// bits synchronized independently can arrive in different cycles — use a
// gray-coded counter, a handshake, or an async FIFO for multi-bit values.
//
// Latency: STAGES to STAGES+1 clk cycles.

module lfpga_sync_bit #(
    parameter integer STAGES = 2   // 2 standard; 3 for very high clock rates
) (
    input  wire clk,      // destination clock
    input  wire d_async,  // asynchronous input (glitch-free source)
    output wire q         // synchronized output
);
    (* ASYNC_REG = "TRUE" *) reg [STAGES-1:0] ff = {STAGES{1'b0}};

    always @(posedge clk)
        ff <= {ff[STAGES-2:0], d_async};

    assign q = ff[STAGES-1];

endmodule
