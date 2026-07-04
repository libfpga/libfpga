// Average tick rate over a long window must match INC / 2^WIDTH exactly
// (the accumulator is exact over 2^WIDTH cycles).
`timescale 1ns/1ps
module tb_clkdiv_frac;
    reg clk = 0, rst = 1;
    wire tick;
    integer i, ticks = 0, errors = 0;
    // INC = 13107 -> 13107 ticks per 65536 cycles (~0.2 * fclk)
    lfpga_clkdiv_frac #(.WIDTH(16), .INC(13107)) dut (
        .clk(clk), .rst(rst), .en(1'b1), .tick(tick));
    always #5 clk = ~clk;
    always @(posedge clk) if (tick) ticks = ticks + 1;
    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_clkdiv_frac);
        repeat (2) @(negedge clk); rst = 0;
        ticks = 0;
        for (i = 0; i < 65536; i = i + 1) @(posedge clk);
        // one pipeline reg: allow the boundary tick to land either side
        if (ticks < 13106 || ticks > 13108) begin
            errors = errors + 1;
            $display("FAIL: %0d ticks in 65536 cycles (want ~13107)", ticks);
        end
        if (errors == 0) $display("TB PASS: clkdiv_frac");
        else $display("TB FAIL: clkdiv_frac (%0d errors)", errors);
        $finish;
    end
endmodule
