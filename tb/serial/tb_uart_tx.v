// Self-checking: sample the line at bit centers, reconstruct each frame.
`timescale 1ns/1ps
module tb_uart_tx;
    localparam integer CPB = 16;   // clocks per bit (fast for sim)
    reg clk = 0, rst = 1, valid = 0;
    reg  [7:0] data = 0;
    wire ready, tx;
    integer b, f, errors = 0;
    reg [7:0] rxed;
    reg [7:0] bytes [0:4];

    lfpga_uart_tx #(.CLKS_PER_BIT(CPB)) dut (
        .clk(clk), .rst(rst), .valid(valid), .ready(ready),
        .data(data), .tx(tx));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_uart_tx);
        bytes[0] = 8'h55; bytes[1] = 8'hA3; bytes[2] = 8'h00;
        bytes[3] = 8'hFF; bytes[4] = 8'h7E;
        repeat (2) @(negedge clk); rst = 0;
        if (tx !== 1'b1) begin errors = errors + 1;
            $display("FAIL: line not idle-high"); end

        for (f = 0; f < 5; f = f + 1) begin
            @(negedge clk); data = bytes[f]; valid = 1;
            // the falling start edge IS the acceptance moment; waiting on
            // it before deasserting valid avoids missing the edge
            @(negedge tx);
            valid = 0;
            #(CPB * 10 / 2);                    // centre of start bit
            if (tx !== 1'b0) begin errors = errors + 1;
                $display("FAIL: start bit"); end
            for (b = 0; b < 8; b = b + 1) begin
                #(CPB * 10);
                rxed[b] = tx;                   // LSB first
            end
            #(CPB * 10);                        // centre of stop bit
            if (tx !== 1'b1) begin errors = errors + 1;
                $display("FAIL: stop bit frame %0d", f); end
            if (rxed !== bytes[f]) begin
                errors = errors + 1;
                $display("FAIL: frame %0d sent %h line-read %h",
                         f, bytes[f], rxed);
            end
            #(CPB * 10);
        end
        if (errors == 0) $display("TB PASS: uart_tx");
        else $display("TB FAIL: uart_tx (%0d errors)", errors);
        $finish;
    end

    initial begin #200000 $display("TB FAIL: uart_tx (timeout)"); $finish; end
endmodule
