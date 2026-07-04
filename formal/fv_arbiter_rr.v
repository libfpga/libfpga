// libfpga formal :: lfpga_arbiter_rr grant is a one-hot subset of req
// SPDX-License-Identifier: MIT

module fv_arbiter_rr (input clk, input rst, input [3:0] req);
    wire [3:0] grant;
    lfpga_arbiter_rr #(.N(4)) dut (
        .clk(clk), .rst(rst), .en(1'b1), .req(req), .grant(grant));

    always @(*) begin
        assert ((grant & (grant - 4'd1)) == 4'd0);  // at most one bit set
        assert ((grant & ~req) == 4'd0);            // only granted a requester
        if (req != 0) assert (grant != 0);          // someone gets it
        if (req == 0) assert (grant == 0);          // nobody if no request
    end
endmodule
