// Self-checking: full period for 8 and 12 bits, no lockup, no repeats early.
`timescale 1ns/1ps
module tb_lfsr;
    reg clk = 0, rst = 1;
    wire [7:0]  q8;
    wire [11:0] q12;
    integer i, errors = 0, seen0;

    lfpga_lfsr #(.WIDTH(8))  u8  (.clk(clk), .rst(rst), .en(1'b1), .lfsr(q8));
    lfpga_lfsr #(.WIDTH(12)) u12 (.clk(clk), .rst(rst), .en(1'b1), .lfsr(q12));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_lfsr);
        repeat (2) @(negedge clk); rst = 0;
        // 8-bit: from 0, must return to 0 after exactly 255 steps
        seen0 = 0;
        for (i = 1; i <= 255; i = i + 1) begin
            @(posedge clk); #1;
            if (q8 == 8'd0 && i < 255) seen0 = seen0 + 1;
        end
        if (q8 !== 8'd0) begin
            errors = errors + 1;
            $display("FAIL: 8-bit period != 255 (q8=%h)", q8);
        end
        if (seen0 != 0) begin
            errors = errors + 1;
            $display("FAIL: 8-bit revisited 0 early (%0d times)", seen0);
        end
        // 12-bit: after 4095 total steps from reset it must be back at 0
        for (i = 256; i <= 4095; i = i + 1) @(posedge clk);
        #1;
        if (q12 !== 12'd0) begin
            errors = errors + 1;
            $display("FAIL: 12-bit period != 4095 (q12=%h)", q12);
        end
        if (errors == 0) $display("TB PASS: lfsr");
        else $display("TB FAIL: lfsr (%0d errors)", errors);
        $finish;
    end
endmodule
