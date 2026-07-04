// Self-checking: random Q4.4 * Q4.4 -> Q4.4 vs rounding/saturating model.
`timescale 1ns/1ps
module tb_fix_mult;
    reg  signed [7:0] a, b;
    wire signed [7:0] p;
    integer i, errors = 0, prod, model;
    reg [31:0] lfsr = 32'hFEed;

    lfpga_fix_mult #(.W(8), .AF(4), .BF(4), .OF(4)) dut (.a(a), .b(b), .p(p));

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_fix_mult);
        for (i = 0; i < 4000; i = i + 1) begin
            lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            a = lfsr[7:0]; b = lfsr[15:8]; #1;
            prod = a * b;                     // Q8.8
            model = (prod + 8) >>> 4;  // round half up ->Q4.4
            if (model > 127)       model = 127;
            else if (model < -128) model = -128;
            if (p !== model[7:0]) begin
                errors = errors + 1;
                if (errors < 8)
                    $display("FAIL: %0d * %0d -> %0d want %0d", a, b, p, model);
            end
        end
        if (errors == 0) $display("TB PASS: fix_mult");
        else $display("TB FAIL: fix_mult (%0d errors)", errors);
        $finish;
    end
endmodule
