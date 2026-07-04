// Self-checking: random shifts vs Verilog's own shift operators.
`timescale 1ns/1ps
module tb_barrel_shifter;
    reg  [15:0] din;
    reg  [3:0]  amt;
    reg         dir, arith;
    wire [15:0] dout;
    integer i, errors = 0;
    reg  [15:0] model;
    reg [31:0] lfsr = 32'hB522;

    lfpga_barrel_shifter #(.WIDTH(16)) dut (
        .din(din), .amt(amt), .dir(dir), .arith(arith), .dout(dout));

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_barrel_shifter);
        for (i = 0; i < 5000; i = i + 1) begin
            lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            din = lfsr[15:0]; amt = lfsr[19:16]; dir = lfsr[20]; arith = lfsr[21];
            #1;
            if (!dir)                 model = din << amt;
            else if (arith)           model = $signed(din) >>> amt;
            else                      model = din >> amt;
            if (dout !== model) begin
                errors = errors + 1;
                if (errors < 6)
                    $display("FAIL: din=%h amt=%0d dir=%b arith=%b -> %h want %h",
                             din, amt, dir, arith, dout, model);
            end
        end
        if (errors == 0) $display("TB PASS: barrel_shifter");
        else $display("TB FAIL: barrel_shifter (%0d errors)", errors);
        $finish;
    end
endmodule
