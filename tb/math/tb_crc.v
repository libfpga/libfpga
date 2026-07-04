// Self-checking: known CCITT-FALSE vector + serial reference cross-check.
`timescale 1ns/1ps
module tb_crc;
    reg clk = 0, rst = 1, en = 0;
    reg [7:0] data = 0;
    wire [15:0] crc16;
    wire [31:0] crc32;
    reg [15:0] ref16;
    reg [31:0] ref32;
    reg [7:0] msg [0:8];
    integer i, j, errors = 0;
    reg fb;

    lfpga_crc #(.WIDTH(16), .POLY(64'h1021), .INIT(64'hFFFF), .DWIDTH(8))
        u16 (.clk(clk), .rst(rst), .en(en), .data_in(data), .crc(crc16));
    lfpga_crc #(.WIDTH(32), .POLY(64'h04C11DB7), .INIT(64'hFFFFFFFF), .DWIDTH(8))
        u32 (.clk(clk), .rst(rst), .en(en), .data_in(data), .crc(crc32));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_crc);
        msg[0]="1"; msg[1]="2"; msg[2]="3"; msg[3]="4"; msg[4]="5";
        msg[5]="6"; msg[6]="7"; msg[7]="8"; msg[8]="9";
        ref16 = 16'hFFFF; ref32 = 32'hFFFFFFFF;
        repeat (2) @(negedge clk); rst = 0;
        for (i = 0; i < 9; i = i + 1) begin
            @(negedge clk); data = msg[i]; en = 1;
            // serial reference models
            for (j = 7; j >= 0; j = j - 1) begin
                fb = ref16[15] ^ msg[i][j];
                ref16 = {ref16[14:0], 1'b0};
                if (fb) ref16 = ref16 ^ 16'h1021;
                fb = ref32[31] ^ msg[i][j];
                ref32 = {ref32[30:0], 1'b0};
                if (fb) ref32 = ref32 ^ 32'h04C11DB7;
            end
            @(posedge clk); #1;
            if (crc16 !== ref16 || crc32 !== ref32) begin
                errors = errors + 1;
                $display("FAIL byte %0d: crc16=%h ref=%h crc32=%h ref=%h",
                         i, crc16, ref16, crc32, ref32);
            end
        end
        @(negedge clk); en = 0;
        // CRC-16-CCITT-FALSE of "123456789" is the classic 0x29B1
        if (crc16 !== 16'h29B1) begin
            errors = errors + 1;
            $display("FAIL: CCITT-FALSE check value: %h != 29B1", crc16);
        end
        if (errors == 0) $display("TB PASS: crc");
        else $display("TB FAIL: crc (%0d errors)", errors);
        $finish;
    end
endmodule
