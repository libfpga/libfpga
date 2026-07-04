// libfpga :: lfpga_arbiter_rr — round-robin arbiter, one-hot grant, parameterizable width
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Grants exactly one requester per cycle (when any request), rotating
// priority so the most recently granted requester becomes lowest
// priority. Classic double-vector trick keeps it compact.

module lfpga_arbiter_rr #(
    parameter integer N = 4
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         en,       // advance priority on grant
    input  wire [N-1:0] req,
    output wire [N-1:0] grant
);
    reg  [N-1:0] last;   // one-hot: most recent grant

    // priority rotates to start just after `last`
    wire [2*N-1:0] dbl   = {req, req};
    wire [2*N-1:0] base  = {{(N){1'b0}}, {last[N-2:0], last[N-1]}};
    wire [2*N-1:0] gnt2  = dbl & ~(dbl - base);

    assign grant = (|req) ? (gnt2[N-1:0] | gnt2[2*N-1:N]) : {N{1'b0}};

    always @(posedge clk) begin
        if (rst)                  last <= {{(N-1){1'b0}}, 1'b1};
        else if (en && (|grant))  last <= grant;
    end
endmodule
