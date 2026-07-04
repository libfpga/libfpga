// libfpga formal :: lfpga_priority_encoder picks a one-hot lowest bit
// SPDX-License-Identifier: MIT

module fv_priority_encoder (input [7:0] req);
    wire [7:0] grant;
    wire [2:0] index;
    wire valid;
    lfpga_priority_encoder #(.WIDTH(8)) dut (
        .req(req), .grant(grant), .index(index), .valid(valid));

    always @(*) begin
        assert ((grant & (grant - 8'd1)) == 8'd0);  // one-hot (or zero)
        assert ((grant & ~req) == 8'd0);            // subset of req
        assert (valid == (req != 0));
        // the granted bit is the lowest set bit: no lower bit is set
        if (valid) assert ((req & (grant - 8'd1)) == 8'd0);
    end
endmodule
