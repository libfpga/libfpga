// Exhaustive at 8 bits against $countones-equivalent model.
`timescale 1ns/1ps
module tb_popcount;
    reg  [7:0] din = 8'hFF;   // != first test value so @* fires at t=0
    wire [3:0] count;
    integer i, j, model, errors = 0;
    lfpga_popcount #(.WIDTH(8)) dut (.din(din), .count(count));
    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_popcount);
        for (i = 0; i < 256; i = i + 1) begin
            din = i[7:0]; #1;
            model = 0;
            for (j = 0; j < 8; j = j + 1) model = model + din[j];
            if (count !== model[3:0]) begin
                errors = errors + 1;
                $display("FAIL: %b -> %0d want %0d", din, count, model);
            end
        end
        if (errors == 0) $display("TB PASS: popcount");
        else $display("TB FAIL: popcount (%0d errors)", errors);
        $finish;
    end
endmodule
