// libfpga :: lfpga_pwm — pulse-width modulator with glitch-free duty updates
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Output high for `duty` counts out of 2^WIDTH per period. duty is
// sampled at each period start, so mid-period writes never glitch.
// duty = 0 -> constant low; duty = max -> high for max/(2^WIDTH).

module lfpga_pwm #(
    parameter integer WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             en,
    input  wire [WIDTH-1:0] duty,
    output reg              pwm,
    output wire             period_start   // 1-cycle pulse per period
);
    reg [WIDTH-1:0] cnt;
    reg [WIDTH-1:0] duty_r;

    assign period_start = en && (cnt == {WIDTH{1'b0}});

    always @(posedge clk) begin
        if (rst) begin
            cnt <= 0; duty_r <= 0; pwm <= 1'b0;
        end else if (en) begin
            cnt <= cnt + {{(WIDTH-1){1'b0}}, 1'b1};
            if (cnt == {WIDTH{1'b0}})
                duty_r <= duty;               // latch at period start
            pwm <= ((cnt == {WIDTH{1'b0}}) ? duty : duty_r) >
                   cnt ? 1'b1 : 1'b0;
        end
    end
endmodule
