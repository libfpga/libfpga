// libfpga :: lfpga_debounce — switch debouncer: 2-flop sync + stability counter
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Output follows the input only after CNT_MAX consecutive stable
// samples. press/release are one-cycle event pulses. Compute CNT_MAX
// with libfpga.com/tools/cdc-synchronizer (debounce mode).

module lfpga_debounce #(
    parameter integer CNT_MAX = 2000000   // 20 ms at 100 MHz
) (
    input  wire clk,
    input  wire rst,
    input  wire din,       // raw, asynchronous, bouncy
    output reg  q,         // clean level
    output wire press,     // 1-cycle pulse on clean rising edge
    output wire release_   // 1-cycle pulse on clean falling edge
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync_ff;
    always @(posedge clk) sync_ff <= {sync_ff[0], din};

    reg [$clog2(CNT_MAX+1)-1:0] cnt;
    reg q_prev;

    always @(posedge clk) begin
        if (rst) begin
            cnt <= 0; q <= 1'b0; q_prev <= 1'b0;
        end else begin
            q_prev <= q;
            if (sync_ff[1] == q)
                cnt <= 0;
            else if (cnt == CNT_MAX[$clog2(CNT_MAX+1)-1:0] - 1) begin
                q   <= sync_ff[1];
                cnt <= 0;
            end else
                cnt <= cnt + 1;
        end
    end

    assign press    = q & ~q_prev;
    assign release_ = ~q & q_prev;
endmodule
