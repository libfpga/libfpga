// Self-checking: roundtrip + one-bit adjacency, exhaustive at 8 bits.
`timescale 1ns/1ps
module tb_gray;
    reg  [7:0] b = 0;
    wire [7:0] g, b2, g_next;
    integer i, errors = 0;
    reg [7:0] diff;

    lfpga_bin2gray #(.WIDTH(8)) u_b2g  (.bin(b), .gray(g));
    lfpga_gray2bin #(.WIDTH(8)) u_g2b  (.gray(g), .bin(b2));
    lfpga_bin2gray #(.WIDTH(8)) u_next (.bin(b + 8'd1), .gray(g_next));

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_gray);
        for (i = 0; i < 256; i = i + 1) begin
            b = i[7:0]; #1;
            if (b2 !== b) begin
                errors = errors + 1;
                $display("FAIL roundtrip: %0d -> %b -> %0d", b, g, b2);
            end
            diff = g ^ g_next;
            if ((diff & (diff - 8'd1)) != 8'd0 || diff == 8'd0) begin
                errors = errors + 1;
                $display("FAIL adjacency at %0d: diff=%b", b, diff);
            end
        end
        if (errors == 0) $display("TB PASS: gray");
        else $display("TB FAIL: gray (%0d errors)", errors);
        $finish;
    end
endmodule
