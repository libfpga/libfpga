// libfpga :: lfpga_lfsr — maximal-length Fibonacci LFSR (XNOR), widths 2-64
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Taps from Xilinx XAPP052; period 2^WIDTH - 1. XNOR feedback makes the
// all-zeros state valid, so reset-to-zero is safe (all-ones locks up).
// Pseudo-random only - not cryptographic.

module lfpga_lfsr #(
    parameter integer WIDTH = 16
) (
    input  wire             clk,
    input  wire             rst,   // sync, resets to all-zeros (valid seed)
    input  wire             en,
    output reg  [WIDTH-1:0] lfsr
);
    // Tap mask for the feedback XNOR (1-indexed taps t -> bit t-1).
    function [63:0] tapmask;
        input integer w;
        begin
            case (w)
                2:  tapmask = 64'h0000000000000003;
                3:  tapmask = 64'h0000000000000006;
                4:  tapmask = 64'h000000000000000C;
                5:  tapmask = 64'h0000000000000014;
                6:  tapmask = 64'h0000000000000030;
                7:  tapmask = 64'h0000000000000060;
                8:  tapmask = 64'h00000000000000B8;
                9:  tapmask = 64'h0000000000000110;
                10: tapmask = 64'h0000000000000240;
                11: tapmask = 64'h0000000000000500;
                12: tapmask = 64'h0000000000000829;
                13: tapmask = 64'h000000000000100D;
                14: tapmask = 64'h0000000000002015;
                15: tapmask = 64'h0000000000006000;
                16: tapmask = 64'h000000000000D008;
                17: tapmask = 64'h0000000000012000;
                18: tapmask = 64'h0000000000020400;
                19: tapmask = 64'h0000000000040023;
                20: tapmask = 64'h0000000000090000;
                21: tapmask = 64'h0000000000140000;
                22: tapmask = 64'h0000000000300000;
                23: tapmask = 64'h0000000000420000;
                24: tapmask = 64'h0000000000E10000;
                25: tapmask = 64'h0000000001200000;
                26: tapmask = 64'h0000000002000023;
                27: tapmask = 64'h0000000004000013;
                28: tapmask = 64'h0000000009000000;
                29: tapmask = 64'h0000000014000000;
                30: tapmask = 64'h0000000020000029;
                31: tapmask = 64'h0000000048000000;
                32: tapmask = 64'h0000000080200003;
                64: tapmask = 64'hD800000000000000;
                default: tapmask = 64'h000000000000D008; // fallback: 16
            endcase
        end
    endfunction

    localparam [63:0] TAPS = tapmask(WIDTH);

    wire fb = ~(^(lfsr & TAPS[WIDTH-1:0]));

    always @(posedge clk) begin
        if (rst)     lfsr <= {WIDTH{1'b0}};
        else if (en) lfsr <= {lfsr[WIDTH-2:0], fb};
    end
endmodule
