// libfpga :: lfpga_priority_encoder — lowest-set-bit priority encoder: one-hot grant + binary index
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Picks the least-significant set request bit. The one-hot output uses
// the classic two's-complement trick (x & -x); the index is a simple
// scan the tools turn into a mux tree.

module lfpga_priority_encoder #(
    parameter integer WIDTH = 8
) (
    input  wire [WIDTH-1:0]         req,
    output wire [WIDTH-1:0]         grant,   // one-hot (zero if no req)
    output reg  [$clog2(WIDTH)-1:0] index,   // of the granted bit
    output wire                     valid    // any request present
);
    assign grant = req & (~req + {{(WIDTH-1){1'b0}}, 1'b1});
    assign valid = |req;

    integer i;
    always @* begin
        index = {$clog2(WIDTH){1'b0}};
        for (i = WIDTH - 1; i >= 0; i = i - 1)
            if (req[i]) index = i[$clog2(WIDTH)-1:0];
    end
endmodule
