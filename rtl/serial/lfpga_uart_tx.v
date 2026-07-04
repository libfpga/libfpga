// libfpga :: lfpga_uart_tx — UART transmitter, 8N1, valid/ready input
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// CLKS_PER_BIT = round(f_clk / baud); compute it with
// libfpga.com/tools/uart-baud. Line idles high; LSB first.

module lfpga_uart_tx #(
    parameter integer CLKS_PER_BIT = 868   // 100 MHz / 115200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       valid,     // byte offered
    output wire       ready,     // accepted when valid && ready
    input  wire [7:0] data,
    output reg        tx
);
    localparam integer CW = $clog2(CLKS_PER_BIT);

    reg [3:0]  bitpos;   // 0 idle, 1 start, 2..9 data, 10 stop
    reg [CW:0] cnt;
    reg [7:0]  sh;

    assign ready = (bitpos == 4'd0);

    always @(posedge clk) begin
        if (rst) begin
            bitpos <= 4'd0;
            tx     <= 1'b1;
            cnt    <= 0;
        end else if (bitpos == 4'd0) begin
            tx <= 1'b1;
            if (valid) begin
                sh     <= data;
                bitpos <= 4'd1;
                cnt    <= 0;
                tx     <= 1'b0;             // start bit
            end
        end else if (cnt == CLKS_PER_BIT[CW:0] - 1) begin
            cnt <= 0;
            if (bitpos == 4'd10) begin
                bitpos <= 4'd0;             // stop bit done -> idle
                tx     <= 1'b1;
            end else begin
                bitpos <= bitpos + 4'd1;
                if (bitpos >= 4'd1 && bitpos <= 4'd8) begin
                    tx <= sh[0];            // data bits, LSB first
                    sh <= {1'b1, sh[7:1]};
                end else begin
                    tx <= 1'b1;             // stop bit
                end
            end
        end else begin
            cnt <= cnt + 1;
        end
    end
endmodule
