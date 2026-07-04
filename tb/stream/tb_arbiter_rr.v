// Self-checking: one-hot grants, only to requesters, fair rotation.
`timescale 1ns/1ps
module tb_arbiter_rr;
    reg clk = 0, rst = 1;
    reg  [3:0] req = 0;
    wire [3:0] grant;
    integer i, errors = 0;
    integer counts [0:3];
    reg [31:0] lfsr = 32'hA4B1;

    lfpga_arbiter_rr #(.N(4)) dut (
        .clk(clk), .rst(rst), .en(1'b1), .req(req), .grant(grant));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_arbiter_rr);
        counts[0]=0; counts[1]=0; counts[2]=0; counts[3]=0;
        repeat (2) @(negedge clk); rst = 0;

        // all requesting: over 400 cycles each must get exactly 100 grants
        req = 4'b1111;
        for (i = 0; i < 400; i = i + 1) begin
            #1;
            if (grant == 4'b0001) counts[0] = counts[0] + 1;
            else if (grant == 4'b0010) counts[1] = counts[1] + 1;
            else if (grant == 4'b0100) counts[2] = counts[2] + 1;
            else if (grant == 4'b1000) counts[3] = counts[3] + 1;
            else begin errors = errors + 1;
                if (errors < 6) $display("FAIL: grant not one-hot: %b", grant); end
            @(posedge clk);
        end
        for (i = 0; i < 4; i = i + 1)
            if (counts[i] !== 100) begin
                errors = errors + 1;
                $display("FAIL: unfair: req%0d got %0d/400", i, counts[i]);
            end

        // random subsets: grant must be one-hot subset of req (or zero)
        for (i = 0; i < 500; i = i + 1) begin
            @(negedge clk);
            lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            req = lfsr[3:0];
            #1;
            if (req == 0 && grant !== 4'b0000) begin
                errors = errors + 1;
                if (errors < 6) $display("FAIL: grant with no request"); end
            if (req != 0) begin
                if ((grant & req) !== grant || grant == 0
                    || (grant & (grant - 4'd1)) !== 4'd0) begin
                    errors = errors + 1;
                    if (errors < 6)
                        $display("FAIL: req=%b grant=%b", req, grant);
                end
            end
            @(posedge clk);
        end
        if (errors == 0) $display("TB PASS: arbiter_rr");
        else $display("TB FAIL: arbiter_rr (%0d errors)", errors);
        $finish;
    end
endmodule
