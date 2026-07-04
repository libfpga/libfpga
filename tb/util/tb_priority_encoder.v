// Exhaustive at 8 bits: grant one-hot, lowest set, index matches.
`timescale 1ns/1ps
module tb_priority_encoder;
    reg  [7:0] req = 0;
    wire [7:0] grant;
    wire [2:0] index;
    wire valid;
    integer i, j, low, errors = 0;
    lfpga_priority_encoder #(.WIDTH(8)) dut (
        .req(req), .grant(grant), .index(index), .valid(valid));
    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_priority_encoder);
        for (i = 0; i < 256; i = i + 1) begin
            req = i[7:0]; #1;
            low = -1;
            for (j = 7; j >= 0; j = j - 1) if (req[j]) low = j;
            if (i == 0) begin
                if (valid !== 1'b0 || grant !== 8'd0) begin
                    errors = errors + 1; $display("FAIL: zero case");
                end
            end else begin
                if (valid !== 1'b1 || grant !== (8'd1 << low)
                    || index !== low[2:0]) begin
                    errors = errors + 1;
                    $display("FAIL: req=%b grant=%b idx=%0d (want bit %0d)",
                             req, grant, index, low);
                end
            end
        end
        if (errors == 0) $display("TB PASS: priority_encoder");
        else $display("TB FAIL: priority_encoder (%0d errors)", errors);
        $finish;
    end
endmodule
