// libfpga :: lfpga_crc — parallel CRC, any polynomial, one data word per clock
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Galois-form CRC advanced one full data word per enabled clock. The
// for-loop unrolls at synthesis into the same XOR network the classic
// parallel-CRC generators emit. MSB-first, not reflected: for reflected
// protocols (Ethernet, SD) bit-reverse input bytes and the final value.
// Presets: CRC-16-CCITT POLY=16'h1021 INIT=16'hFFFF; CRC-32 (IEEE poly,
// unreflected) POLY=32'h04C11DB7 INIT=32'hFFFFFFFF.

module lfpga_crc #(
    parameter integer WIDTH  = 16,
    parameter [63:0]  POLY   = 64'h1021,
    parameter [63:0]  INIT   = 64'hFFFF,
    parameter integer DWIDTH = 8
) (
    input  wire              clk,
    input  wire              rst,      // sync, loads INIT
    input  wire              en,       // fold data_in into the CRC
    input  wire [DWIDTH-1:0] data_in,  // bit DWIDTH-1 enters first
    output reg  [WIDTH-1:0]  crc
);
    function [WIDTH-1:0] advance;
        input [WIDTH-1:0]  c;
        input [DWIDTH-1:0] d;
        integer i;
        reg fb;
        begin
            advance = c;
            for (i = DWIDTH - 1; i >= 0; i = i - 1) begin
                fb = advance[WIDTH-1] ^ d[i];
                advance = {advance[WIDTH-2:0], 1'b0};
                if (fb) advance = advance ^ POLY[WIDTH-1:0];
            end
        end
    endfunction

    wire [WIDTH-1:0] crc_next = advance(crc, data_in);

    always @(posedge clk) begin
        if (rst)     crc <= INIT[WIDTH-1:0];
        else if (en) crc <= crc_next;
    end
endmodule
