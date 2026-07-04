// Self-checking: bit-banged frames must be received exactly; a short
// glitch on the line must not produce a byte.
`timescale 1ns/1ps
module tb_uart_rx;
    localparam integer CPB = 16;
    localparam integer BIT = CPB * 10;   // ns per bit
    reg clk = 0, rst = 1, rx = 1;
    wire [7:0] data;
    wire valid;
    integer f, b, got = 0, errors = 0;
    reg [7:0] bytes [0:4];
    reg [7:0] last_rx;

    lfpga_uart_rx #(.CLKS_PER_BIT(CPB)) dut (
        .clk(clk), .rst(rst), .rx(rx), .data(data), .valid(valid));

    always #5 clk = ~clk;

    always @(posedge clk) if (valid) begin
        got = got + 1;
        last_rx = data;
    end

    task send_byte(input [7:0] v);
        integer i;
        begin
            rx = 0; #BIT;                       // start
            for (i = 0; i < 8; i = i + 1) begin
                rx = v[i]; #BIT;                // LSB first
            end
            rx = 1; #BIT;                       // stop
        end
    endtask

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_uart_rx);
        bytes[0] = 8'h55; bytes[1] = 8'hC2; bytes[2] = 8'h00;
        bytes[3] = 8'hFF; bytes[4] = 8'h13;
        repeat (4) @(negedge clk); rst = 0;
        #(2 * BIT);

        // a glitch far shorter than half a bit must be ignored
        rx = 0; #20; rx = 1; #(3 * BIT);
        if (got !== 0) begin errors = errors + 1;
            $display("FAIL: glitch produced a byte"); end

        for (f = 0; f < 5; f = f + 1) begin
            send_byte(bytes[f]);
            #(BIT);
            if (got !== f + 1) begin
                errors = errors + 1;
                $display("FAIL: frame %0d not received", f);
            end else if (last_rx !== bytes[f]) begin
                errors = errors + 1;
                $display("FAIL: frame %0d got %h want %h", f, last_rx, bytes[f]);
            end
        end
        if (errors == 0) $display("TB PASS: uart_rx");
        else $display("TB FAIL: uart_rx (%0d errors)", errors);
        $finish;
    end

    initial begin #200000 $display("TB FAIL: uart_rx (timeout)"); $finish; end
endmodule
