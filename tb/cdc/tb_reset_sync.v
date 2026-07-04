// Self-checking testbench for lfpga_reset_sync.
// Checks: assertion is asynchronous (no clock edge needed); deassertion
// is synchronous and takes exactly STAGES clock edges.
`timescale 1ns/1ps
module tb_reset_sync;
    reg clk = 0, rst_async_n = 1;
    wire rst_sync_n;
    integer errors = 0;

    lfpga_reset_sync #(.STAGES(2)) dut (
        .clk(clk), .rst_async_n(rst_async_n), .rst_sync_n(rst_sync_n));

    always #5 clk = ~clk;

    task expect_out(input v, input [159:0] what);
        if (rst_sync_n !== v) begin
            errors = errors + 1;
            $display("FAIL: %0s: rst_sync_n=%b expected %b (t=%0t)",
                     what, rst_sync_n, v, $time);
        end
    endtask

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_reset_sync);

        // let the synchronizer come out of its power-up state
        repeat (4) @(posedge clk); #1;
        expect_out(1'b1, "out of reset after power-up");

        // async assertion: mid-cycle, effective before any clock edge
        #2 rst_async_n = 0;
        #1 expect_out(1'b0, "asserts asynchronously");

        // hold through several edges
        repeat (3) @(posedge clk); #1;
        expect_out(1'b0, "stays asserted");

        // release mid-cycle: STAGES=2 -> still low after 1st edge, high after 2nd
        #2 rst_async_n = 1;
        @(posedge clk); #1;
        expect_out(1'b0, "still in reset one edge after release");
        @(posedge clk); #1;
        expect_out(1'b1, "deasserts on the second edge");

        if (errors == 0) $display("TB PASS: reset_sync");
        else             $display("TB FAIL: reset_sync (%0d errors)", errors);
        $finish;
    end
endmodule
