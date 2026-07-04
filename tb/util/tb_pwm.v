// Count high cycles over full periods for several duties; check a
// mid-period duty change only takes effect next period.
`timescale 1ns/1ps
module tb_pwm;
    reg clk = 0, rst = 1, en = 0;
    reg [7:0] duty = 0;
    wire pwm, period_start;
    integer highs, i, p, errors = 0;
    lfpga_pwm #(.WIDTH(8)) dut (.clk(clk), .rst(rst), .en(en),
                                .duty(duty), .pwm(pwm),
                                .period_start(period_start));
    always #5 clk = ~clk;

    task measure(input [7:0] d, input integer want);
        begin
            duty = d;
            @(posedge period_start);           // wait for a period boundary
            @(negedge clk);
            highs = 0;
            for (i = 0; i < 256; i = i + 1) begin
                @(posedge clk); #1;
                if (pwm) highs = highs + 1;
            end
            if (highs !== want) begin
                errors = errors + 1;
                $display("FAIL: duty=%0d -> %0d highs (want %0d)",
                         d, highs, want);
            end
        end
    endtask

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_pwm);
        repeat (2) @(negedge clk); rst = 0; en = 1;
        measure(8'd0,   0);
        measure(8'd1,   1);
        measure(8'd128, 128);
        measure(8'd255, 255);
        if (errors == 0) $display("TB PASS: pwm");
        else $display("TB FAIL: pwm (%0d errors)", errors);
        $finish;
    end

    initial begin #200000 $display("TB FAIL: pwm (timeout)"); $finish; end
endmodule
