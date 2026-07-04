// Self-checking: random push/pop scoreboard, flags, count, ordering.
`timescale 1ns/1ps
module tb_fifo_sync;
    reg clk = 0, rst = 1, wr_en = 0, rd_en = 0;
    reg  [7:0] wr_data = 0;
    wire [7:0] rd_data;
    wire full, empty;
    wire [4:0] count;
    reg [7:0] model [0:1023];
    integer head = 0, tail = 0;
    integer i, errors = 0;
    reg [31:0] lfsr = 32'h5EED;
    reg do_push, do_pop;

    lfpga_fifo_sync #(.WIDTH(8), .DEPTH(16)) dut (
        .clk(clk), .rst(rst), .wr_en(wr_en), .wr_data(wr_data),
        .rd_en(rd_en), .rd_data(rd_data), .full(full), .empty(empty),
        .count(count));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_fifo_sync);
        repeat (2) @(negedge clk); rst = 0;
        for (i = 0; i < 2000; i = i + 1) begin
            @(negedge clk);
            lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            wr_en = lfsr[0]; rd_en = lfsr[1]; wr_data = lfsr[15:8];
            #1;
            if (count !== (tail - head))
                begin errors = errors + 1; if (errors < 6)
                    $display("FAIL count=%0d model=%0d", count, tail-head); end
            if (full !== ((tail - head) == 16))
                begin errors = errors + 1; if (errors < 6)
                    $display("FAIL full flag"); end
            if (empty !== ((tail - head) == 0))
                begin errors = errors + 1; if (errors < 6)
                    $display("FAIL empty flag"); end
            if ((tail - head) > 0 && rd_data !== model[head % 1024])
                begin errors = errors + 1; if (errors < 6)
                    $display("FAIL data %h != %h", rd_data, model[head % 1024]); end
            do_push = wr_en && ((tail - head) < 16);
            do_pop  = rd_en && ((tail - head) > 0);
            @(posedge clk);
            if (do_push) begin model[tail % 1024] = wr_data; tail = tail + 1; end
            if (do_pop)  head = head + 1;
        end
        if (errors == 0) $display("TB PASS: fifo_sync");
        else $display("TB FAIL: fifo_sync (%0d errors)", errors);
        $finish;
    end
endmodule
