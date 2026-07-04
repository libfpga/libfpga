// Model-based random check of all three pulse outputs.
`timescale 1ns/1ps
module tb_edge_detect;
    reg clk = 0, rst = 1, din = 0;
    wire rise, fall, toggle;
    reg model_prev = 0;
    integer i, errors = 0;
    reg [31:0] lfsr = 32'h3D6E;
    lfpga_edge_detect dut (.clk(clk), .rst(rst), .din(din),
                           .rise(rise), .fall(fall), .toggle(toggle));
    always #5 clk = ~clk;
    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_edge_detect);
        repeat (2) @(negedge clk); rst = 0;
        for (i = 0; i < 300; i = i + 1) begin
            @(negedge clk);
            lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            din = lfsr[0];
            #1;
            if (rise !== (din & ~model_prev) || fall !== (~din & model_prev)
                || toggle !== (din ^ model_prev)) begin
                errors = errors + 1;
                if (errors < 6) $display("FAIL @%0t", $time);
            end
            @(posedge clk);
            model_prev = din;
        end
        if (errors == 0) $display("TB PASS: edge_detect");
        else $display("TB FAIL: edge_detect (%0d errors)", errors);
        $finish;
    end
endmodule
