// Self-checking: reverse-of-reverse is identity; spot bits.
`timescale 1ns/1ps
module tb_bitreverse;
    reg  [15:0] din;
    wire [15:0] dout, back;
    integer i, j, errors = 0;
    reg [31:0] lfsr = 32'h1234;

    lfpga_bitreverse #(.WIDTH(16)) dut  (.din(din),  .dout(dout));
    lfpga_bitreverse #(.WIDTH(16)) dut2 (.din(dout), .dout(back));

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_bitreverse);
        for (i = 0; i < 2000; i = i + 1) begin
            lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            din = lfsr[15:0]; #1;
            for (j = 0; j < 16; j = j + 1)
                if (dout[j] !== din[15-j]) begin
                    errors = errors + 1;
                    if (errors < 4) $display("FAIL bit %0d", j);
                end
            if (back !== din) begin errors = errors + 1;
                if (errors < 4) $display("FAIL: reverse^2 != identity"); end
        end
        if (errors == 0) $display("TB PASS: bitreverse");
        else $display("TB FAIL: bitreverse (%0d errors)", errors);
        $finish;
    end
endmodule
