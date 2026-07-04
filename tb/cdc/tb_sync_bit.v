// Self-checking testbench for lfpga_sync_bit.
`timescale 1ns/1ps
module tb_sync_bit;
    reg  clk = 0;
    reg  d = 0;
    wire q;
    integer errors = 0;

    lfpga_sync_bit #(.STAGES(2)) dut (.clk(clk), .d_async(d), .q(q));

    always #5 clk = ~clk;

    task expect_q(input v, input [127:0] what);
        if (q !== v) begin
            errors = errors + 1;
            $display("FAIL: %0s: q=%b expected %b (t=%0t)", what, q, v, $time);
        end
    endtask

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_sync_bit);
        repeat (3) @(posedge clk);

        // clean edge-aligned change follows within STAGES(+1) cycles
        @(negedge clk) d = 1;
        repeat (3) @(posedge clk); #1;
        expect_q(1'b1, "rise follows");

        @(negedge clk) d = 0;
        repeat (3) @(posedge clk); #1;
        expect_q(1'b0, "fall follows");

        // mid-cycle (asynchronous) change also lands within STAGES+1 cycles
        #7 d = 1;
        repeat (4) @(posedge clk); #1;
        expect_q(1'b1, "async-offset rise follows");

        // stability: q must not glitch while d is stable
        begin : stability
            integer i;
            for (i = 0; i < 10; i = i + 1) begin
                @(posedge clk); #1;
                expect_q(1'b1, "stable hold");
            end
        end

        if (errors == 0) $display("TB PASS: sync_bit");
        else             $display("TB FAIL: sync_bit (%0d errors)", errors);
        $finish;
    end
endmodule
