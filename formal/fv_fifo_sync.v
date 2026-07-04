// libfpga formal :: lfpga_fifo_sync flag and count invariants
// SPDX-License-Identifier: MIT

module fv_fifo_sync (input clk, input rst, input wr_en, input rd_en,
                     input [7:0] wr_data);
    wire [7:0] rd_data;
    wire full, empty;
    wire [4:0] count;
    lfpga_fifo_sync #(.WIDTH(8), .DEPTH(16)) dut (
        .clk(clk), .rst(rst), .wr_en(wr_en), .wr_data(wr_data),
        .rd_en(rd_en), .rd_data(rd_data), .full(full), .empty(empty),
        .count(count));

    // assume synchronous reset asserted in the first cycle (clean init)
    initial assume (rst);

    always @(*) begin
        assert (count <= 16);                 // never overfills
        assert (full  == (count == 16));      // flags track count
        assert (empty == (count == 0));
        assert (!(full && empty));            // never both
    end
endmodule
