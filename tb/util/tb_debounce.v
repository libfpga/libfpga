// Bouncy press/release must yield exactly one clean event each; a
// bounce shorter than the window must be ignored.
`timescale 1ns/1ps
module tb_debounce;
    reg clk = 0, rst = 1, din = 0;
    wire q, press, release_;
    integer presses = 0, releases = 0, i, errors = 0;
    lfpga_debounce #(.CNT_MAX(20)) dut (
        .clk(clk), .rst(rst), .din(din),
        .q(q), .press(press), .release_(release_));
    always #5 clk = ~clk;
    always @(posedge clk) begin
        if (press)    presses  = presses  + 1;
        if (release_) releases = releases + 1;
    end
    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_debounce);
        repeat (3) @(negedge clk); rst = 0;
        // bouncy press: chatter then settle high
        for (i = 0; i < 6; i = i + 1) begin din = ~din; #37; end
        din = 1; #500;   // 50 cycles stable > window
        if (q !== 1'b1 || presses !== 1) begin errors = errors + 1;
            $display("FAIL: press (q=%b presses=%0d)", q, presses); end
        // short glitch low: must NOT register
        din = 0; #100; din = 1; #500;
        if (q !== 1'b1 || releases !== 0) begin errors = errors + 1;
            $display("FAIL: glitch registered (releases=%0d)", releases); end
        // bouncy release
        for (i = 0; i < 6; i = i + 1) begin din = ~din; #37; end
        din = 0; #500;
        if (q !== 1'b0 || releases !== 1 || presses !== 1) begin
            errors = errors + 1;
            $display("FAIL: release (q=%b p=%0d r=%0d)", q, presses, releases);
        end
        if (errors == 0) $display("TB PASS: debounce");
        else $display("TB FAIL: debounce (%0d errors)", errors);
        $finish;
    end
endmodule
