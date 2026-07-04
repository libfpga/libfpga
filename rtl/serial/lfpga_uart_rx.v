// libfpga :: lfpga_uart_rx — UART receiver, 8N1, mid-bit sampling, start-bit glitch reject
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Samples each bit at its centre; a start edge that doesn't survive to
// the half-bit check is rejected as a glitch. Synchronize rx with
// lfpga_sync_bit first if it comes from a pin (it does).

module lfpga_uart_rx #(
    parameter integer CLKS_PER_BIT = 868
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,        // already synchronized to clk
    output reg  [7:0] data,
    output reg        valid      // 1-cycle pulse per good frame
);
    localparam integer CW = $clog2(CLKS_PER_BIT);

    reg [3:0]  state;   // 0 idle, 1 start, 2..9 data, 10 stop
    reg [CW:0] cnt;
    reg [7:0]  sh;

    always @(posedge clk) begin
        valid <= 1'b0;
        if (rst) begin
            state <= 4'd0;
            cnt   <= 0;
        end else begin
            case (state)
                4'd0: if (rx == 1'b0) begin       // start edge seen
                    state <= 4'd1;
                    cnt   <= 0;
                end
                4'd1: if (cnt == CLKS_PER_BIT[CW:0]/2 - 1) begin
                    cnt <= 0;
                    if (rx == 1'b0) state <= 4'd2; // real start bit
                    else            state <= 4'd0; // glitch: reject
                end else cnt <= cnt + 1;
                4'd10: if (cnt == CLKS_PER_BIT[CW:0] - 1) begin
                    cnt   <= 0;
                    state <= 4'd0;
                    if (rx == 1'b1) begin          // stop bit good
                        data  <= sh;
                        valid <= 1'b1;
                    end
                end else cnt <= cnt + 1;
                default: if (cnt == CLKS_PER_BIT[CW:0] - 1) begin
                    cnt   <= 0;
                    sh    <= {rx, sh[7:1]};        // LSB first
                    state <= state + 4'd1;
                end else cnt <= cnt + 1;
            endcase
        end
    end
endmodule
