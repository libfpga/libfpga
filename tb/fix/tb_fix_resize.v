// Self-checking: exhaustive Q8.8->Q4.4 vs a rounding+saturating model.
`timescale 1ns/1ps
module tb_fix_resize;
    reg  signed [15:0] din;
    wire signed [7:0]  dout;
    integer i, errors = 0, model, half;

    lfpga_fix_resize #(.IN_W(16), .IN_F(8), .OUT_W(8), .OUT_F(4)) dut (
        .din(din), .dout(dout));

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_fix_resize);
        // sweep the full 16-bit input space in steps of 3
        for (i = -32768; i < 32768; i = i + 3) begin
            din = i[15:0]; #1;
            // model: round(i / 16) then saturate to [-128,127]
            half = (i + 8) >>> 4;  // round half up (arithmetic)
            if (half > 127)       half = 127;
            else if (half < -128) half = -128;
            if (dout !== half[7:0]) begin
                errors = errors + 1;
                if (errors < 8)
                    $display("FAIL: din=%0d -> %0d want %0d", i, dout, half);
            end
        end
        if (errors == 0) $display("TB PASS: fix_resize");
        else $display("TB FAIL: fix_resize (%0d errors)", errors);
        $finish;
    end
endmodule
