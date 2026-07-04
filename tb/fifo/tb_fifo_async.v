// Self-checking scoreboard across two unrelated clocks (10 ns vs 7.3 ns):
// order preserved, nothing lost or duplicated, flags never optimistic.
//
// TB pattern: each domain drives and commits at its own negedge only
// (signals hold until the posedge, so the negedge decision equals the
// edge outcome). No posedge waits in the TB = no event-order races
// against the DUT's clocked blocks.
`timescale 1ns/1ps
module tb_fifo_async;
    reg wclk = 0, rclk = 0, wrst = 1, rrst = 1;
    reg wr_en = 0, rd_en = 0;
    reg  [7:0] wr_data = 0;
    wire [7:0] rd_data;
    wire full, empty;
    reg [7:0] model [0:4095];
    integer head = 0, tail = 0;
    integer wi, ri, errors = 0;
    reg [31:0] wlfsr = 32'hA5A5, rlfsr = 32'h5A5A;
    reg write_done = 0;

    lfpga_fifo_async #(.WIDTH(8), .DEPTH(16)) dut (
        .wclk(wclk), .wrst(wrst), .wr_en(wr_en), .wr_data(wr_data),
        .full(full),
        .rclk(rclk), .rrst(rrst), .rd_en(rd_en), .rd_data(rd_data),
        .empty(empty));

    always #5 wclk = ~wclk;
    always #3.65 rclk = ~rclk;

    // write domain
    initial begin
        repeat (4) @(negedge wclk); wrst = 0;
        for (wi = 0; wi < 3000; wi = wi + 1) begin
            @(negedge wclk);
            wlfsr = {wlfsr[30:0], wlfsr[31]^wlfsr[21]^wlfsr[1]^wlfsr[0]};
            wr_en = wlfsr[0]; wr_data = wlfsr[15:8];
            #1;
            if (wr_en && !full) begin      // this is what the edge will do
                model[tail % 4096] = wr_data;
                tail = tail + 1;
            end
        end
        @(negedge wclk); wr_en = 0; write_done = 1;
    end

    // read domain (sole driver of rd_en; drains hard once writes finish)
    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_fifo_async);
        repeat (4) @(negedge rclk); rrst = 0;
        for (ri = 0; ri < 12000; ri = ri + 1) begin
            @(negedge rclk);
            rlfsr = {rlfsr[30:0], rlfsr[31]^rlfsr[21]^rlfsr[1]^rlfsr[0]};
            rd_en = write_done ? 1'b1 : rlfsr[0];
            #1;
            if (rd_en && !empty) begin
                if (rd_data !== model[head % 4096]) begin
                    errors = errors + 1;
                    if (errors < 6)
                        $display("FAIL @%0t: rd=%h expect=%h (item %0d)",
                                 $time, rd_data, model[head % 4096], head);
                end
                head = head + 1;
            end
            if (write_done && head == tail && ri > 6000) ri = 12000;
        end
        if (head !== tail) begin
            errors = errors + 1;
            $display("FAIL: pushed %0d, popped %0d", tail, head);
        end
        if (tail < 1000) begin
            errors = errors + 1;
            $display("FAIL: too few pushes exercised (%0d)", tail);
        end
        if (errors == 0) $display("TB PASS: fifo_async");
        else $display("TB FAIL: fifo_async (%0d errors)", errors);
        $finish;
    end

    initial begin
        #120000;
        $display("TB FAIL: fifo_async (timeout)");
        $finish;
    end
endmodule
