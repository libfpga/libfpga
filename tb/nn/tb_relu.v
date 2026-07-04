// Self-checking: ReLU and leaky variants vs a quantizing model.
`timescale 1ns/1ps
module tb_relu;
    reg  signed [31:0] din;
    wire signed [7:0]  d_relu, d_leaky;
    integer i, errors = 0, act, model;

    lfpga_relu #(.ACC_W(32), .ACC_F(8), .OUT_W(8), .OUT_F(4), .KIND(0))
        u0 (.din(din), .dout(d_relu));
    lfpga_relu #(.ACC_W(32), .ACC_F(8), .OUT_W(8), .OUT_F(4), .KIND(1))
        u1 (.din(din), .dout(d_leaky));

    function integer qresize(input integer v);   // Q.8 -> Q.4, round half up, sat
        begin
            qresize = (v + 8) >>> 4;
            if (qresize > 127) qresize = 127;
            else if (qresize < -128) qresize = -128;
        end
    endfunction

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_relu);
        for (i = -20000; i < 20000; i = i + 7) begin
            din = i; #1;
            // ReLU
            act = (i >= 0) ? i : 0;
            model = qresize(act);
            if (d_relu !== model[7:0]) begin errors=errors+1;
                if (errors<6) $display("FAIL relu %0d -> %0d want %0d",i,d_relu,model); end
            // leaky
            act = (i >= 0) ? i : (i >>> 3);
            model = qresize(act);
            if (d_leaky !== model[7:0]) begin errors=errors+1;
                if (errors<6) $display("FAIL leaky %0d -> %0d want %0d",i,d_leaky,model); end
        end
        if (errors == 0) $display("TB PASS: relu");
        else $display("TB FAIL: relu (%0d errors)", errors);
        $finish;
    end
endmodule
