// libfpga :: lfpga_spi_master — SPI master, mode 0, 8-bit, MSB first
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Mode 0: sck idles low, mosi changes on falling sck, both sides sample
// on rising sck. One byte per start pulse; full-duplex (rx_data holds
// what the slave shifted back). SCK = clk / (2 * CLK_DIV).

module lfpga_spi_master #(
    parameter integer CLK_DIV = 4   // >= 1
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,      // begin a byte (when !busy)
    input  wire [7:0] tx_data,
    output reg  [7:0] rx_data,
    output reg        busy,
    output reg        done,       // 1-cycle pulse at end of frame
    output reg        sck,
    output reg        mosi,
    input  wire       miso,
    output reg        cs_n
);
    localparam integer CW = $clog2(CLK_DIV) + 1;

    reg [CW-1:0] div;
    reg [3:0]    bitcnt;
    reg [6:0]    sh;   // bit 7 goes straight to mosi at start

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            busy <= 1'b0; sck <= 1'b0; cs_n <= 1'b1; mosi <= 1'b0;
            div <= 0; bitcnt <= 0;
        end else if (!busy) begin
            sck <= 1'b0;
            if (start) begin
                busy   <= 1'b1;
                cs_n   <= 1'b0;
                sh     <= tx_data[6:0];
                mosi   <= tx_data[7];   // present MSB before first edge
                bitcnt <= 4'd0;
                div    <= 0;
            end
        end else if (div == CLK_DIV[CW-1:0] - 1) begin
            div <= 0;
            if (!sck) begin
                sck     <= 1'b1;                     // rising: sample miso
                rx_data <= {rx_data[6:0], miso};
            end else begin
                sck <= 1'b0;                         // falling: next bit out
                if (bitcnt == 4'd7) begin
                    busy <= 1'b0;
                    cs_n <= 1'b1;
                    done <= 1'b1;
                end else begin
                    bitcnt <= bitcnt + 4'd1;
                    sh     <= {sh[5:0], 1'b0};
                    mosi   <= sh[6];
                end
            end
        end else begin
            div <= div + 1;
        end
    end
endmodule
