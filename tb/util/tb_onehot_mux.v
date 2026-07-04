// Every select line routes its word; zero select yields zero.
`timescale 1ns/1ps
module tb_onehot_mux;
    reg  [31:0] din;
    reg  [3:0]  sel = 0;
    wire [7:0]  dout;
    integer j, errors = 0;
    lfpga_onehot_mux #(.WIDTH(8), .N(4)) dut (
        .din(din), .sel(sel), .dout(dout));
    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_onehot_mux);
        din = {8'hD4, 8'hC3, 8'hB2, 8'hA1};   // in3..in0
        sel = 4'b0000; #1;
        if (dout !== 8'h00) begin errors = errors + 1;
            $display("FAIL: zero select -> %h", dout); end
        for (j = 0; j < 4; j = j + 1) begin
            sel = 4'b0001 << j; #1;
            if (dout !== din[j*8 +: 8]) begin
                errors = errors + 1;
                $display("FAIL: sel=%b dout=%h want %h",
                         sel, dout, din[j*8 +: 8]);
            end
        end
        if (errors == 0) $display("TB PASS: onehot_mux");
        else $display("TB FAIL: onehot_mux (%0d errors)", errors);
        $finish;
    end
endmodule
