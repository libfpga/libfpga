// libfpga :: lfpga_fifo_async — asynchronous (dual-clock) FIFO with gray-coded pointers
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// The classic Cummings-style CDC FIFO: binary pointers are gray-coded
// before crossing through 2-flop synchronizers, so a mid-transition
// sample is never off by more than one - flags are conservative, never
// wrong. Constrain the crossings (set_max_delay -datapath_only or your
// flow's equivalent); see libfpga.com/tools/cdc-synchronizer.
//
// rd_data shows the oldest word when !empty (show-ahead); rd_en pops.

module lfpga_fifo_async #(
    parameter integer WIDTH = 8,
    parameter integer DEPTH = 16   // must be a power of 2, >= 4
) (
    input  wire             wclk,
    input  wire             wrst,     // sync to wclk
    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,
    output wire             full,
    input  wire             rclk,
    input  wire             rrst,     // sync to rclk
    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,
    output wire             empty
);
    localparam integer AW = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg full_r, empty_r;

    // write side: binary + gray pointers
    reg  [AW:0] wbin, wgray;
    wire [AW:0] wbin_next  = wbin + {{AW{1'b0}}, (wr_en && !full_r)};
    wire [AW:0] wgray_next = wbin_next ^ (wbin_next >> 1);

    // read side
    reg  [AW:0] rbin, rgray;
    wire [AW:0] rbin_next  = rbin + {{AW{1'b0}}, (rd_en && !empty_r)};
    wire [AW:0] rgray_next = rbin_next ^ (rbin_next >> 1);

    // pointer synchronizers
    (* ASYNC_REG = "TRUE" *) reg [AW:0] rgray_w1, rgray_w2; // rptr -> wclk
    (* ASYNC_REG = "TRUE" *) reg [AW:0] wgray_r1, wgray_r2; // wptr -> rclk

    // Registered flags (the classic Cummings formulation): pessimistic by
    // one cycle, never optimistic, and free of combinational feedback.
    assign full  = full_r;
    assign empty = empty_r;

    always @(posedge wclk) begin
        if (wrst) begin
            wbin <= 0; wgray <= 0;
            rgray_w1 <= 0; rgray_w2 <= 0;
            full_r <= 1'b0;
        end else begin
            if (wr_en && !full_r) mem[wbin[AW-1:0]] <= wr_data;
            wbin  <= wbin_next;
            wgray <= wgray_next;
            rgray_w1 <= rgray;
            rgray_w2 <= rgray_w1;
            // full: next write gray meets the double-synced read gray with
            // its top two bits flipped (canonical Cummings comparison)
            full_r <= (wgray_next ==
                       {~rgray_w2[AW:AW-1], rgray_w2[AW-2:0]});
        end
    end

    always @(posedge rclk) begin
        if (rrst) begin
            rbin <= 0; rgray <= 0;
            wgray_r1 <= 0; wgray_r2 <= 0;
            empty_r <= 1'b1;
        end else begin
            rbin  <= rbin_next;
            rgray <= rgray_next;
            wgray_r1 <= wgray;
            wgray_r2 <= wgray_r1;
            // empty: next read gray catches the double-synced write gray
            empty_r <= (rgray_next == wgray_r2);
        end
    end

    assign rd_data = mem[rbin[AW-1:0]];
endmodule
