// Self-checking: random dot products vs a wide integer model.
`timescale 1ns/1ps
module tb_mac;
    reg clk = 0, rst = 1, clr = 0, en = 0;
    reg  signed [7:0] a = 0, b = 0;
    wire signed [31:0] acc;
    integer k, n, model, errors = 0;
    reg [31:0] lfsr = 32'h3AC1;

    lfpga_mac #(.W(8), .ACC_W(32)) dut (
        .clk(clk), .rst(rst), .clr(clr), .en(en), .a(a), .b(b), .acc(acc));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_mac);
        repeat (2) @(negedge clk); rst = 0;
        // 20 independent dot products of random length 1..16
        for (k = 0; k < 20; k = k + 1) begin
            @(negedge clk); clr = 1; en = 0;
            @(negedge clk); clr = 0; en = 1;
            model = 0;
            n = 1 + (k % 16);
            repeat (n) begin
                lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
                a = lfsr[7:0]; b = lfsr[15:8];
                model = model + $signed(a) * $signed(b);
                @(negedge clk);
            end
            en = 0; #1;
            if (acc !== model) begin
                errors = errors + 1;
                if (errors < 6)
                    $display("FAIL dot %0d (len %0d): acc=%0d want %0d",
                             k, n, acc, model);
            end
        end
        if (errors == 0) $display("TB PASS: mac");
        else $display("TB FAIL: mac (%0d errors)", errors);
        $finish;
    end
endmodule
