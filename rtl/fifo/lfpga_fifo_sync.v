// libfpga :: lfpga_fifo_sync — synchronous FIFO, show-ahead (FWFT), power-of-2 depth
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Show-ahead: rd_data presents the oldest word whenever !empty; rd_en
// pops it. Writes when full and reads when empty are ignored. Size the
// depth with libfpga.com/tools/fifo-depth.

module lfpga_fifo_sync #(
    parameter integer WIDTH = 8,
    parameter integer DEPTH = 16   // must be a power of 2
) (
    input  wire             clk,
    input  wire             rst,      // sync, empties the FIFO
    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,
    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,
    output wire             full,
    output wire             empty,
    output reg  [$clog2(DEPTH):0] count
);
    localparam integer AW = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW-1:0] wptr, rptr;

    wire push = wr_en && !full;
    wire pop  = rd_en && !empty;

    always @(posedge clk) begin
        if (rst) begin
            wptr  <= {AW{1'b0}};
            rptr  <= {AW{1'b0}};
            count <= {(AW+1){1'b0}};
        end else begin
            if (push) begin
                mem[wptr] <= wr_data;
                wptr <= wptr + {{(AW-1){1'b0}}, 1'b1};
            end
            if (pop)
                rptr <= rptr + {{(AW-1){1'b0}}, 1'b1};
            count <= count + {{AW{1'b0}}, push} - {{AW{1'b0}}, pop};
        end
    end

    assign rd_data = mem[rptr];
    assign full    = (count == DEPTH[AW:0]);
    assign empty   = (count == {(AW+1){1'b0}});
endmodule
