// Self-checking: exhaustive 8-bit add and subtract vs saturating model.
`timescale 1ns/1ps
module tb_fix_add;
    reg  signed [7:0] a, b; reg sub;
    wire signed [7:0] s;
    integer ia, ib, errors = 0, model;

    lfpga_fix_add #(.W(8)) dut (.a(a), .b(b), .sub(sub), .s(s));

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_fix_add);
        for (ia = -128; ia < 128; ia = ia + 5) begin
            for (ib = -128; ib < 128; ib = ib + 5) begin
                a = ia[7:0]; b = ib[7:0];
                sub = 0; #1;
                model = ia + ib;
                if (model > 127) model = 127; else if (model < -128) model = -128;
                if (s !== model[7:0]) begin errors=errors+1;
                    if (errors<8) $display("FAIL add %0d+%0d=%0d want %0d",ia,ib,s,model); end
                sub = 1; #1;
                model = ia - ib;
                if (model > 127) model = 127; else if (model < -128) model = -128;
                if (s !== model[7:0]) begin errors=errors+1;
                    if (errors<8) $display("FAIL sub %0d-%0d=%0d want %0d",ia,ib,s,model); end
            end
        end
        if (errors == 0) $display("TB PASS: fix_add");
        else $display("TB FAIL: fix_add (%0d errors)", errors);
        $finish;
    end
endmodule
