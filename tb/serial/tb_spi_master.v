// Self-checking: behavioral mode-0 slave checks what it receives and
// feeds a known response back; framing (cs_n, sck count) verified.
`timescale 1ns/1ps
module tb_spi_master;
    reg clk = 0, rst = 1, start = 0;
    reg  [7:0] tx_data = 0;
    wire [7:0] rx_data;
    wire busy, done, sck, mosi, cs_n;
    reg miso = 0;
    reg [7:0] slave_rx, slave_tx;
    integer edges, f, errors = 0;
    reg [7:0] tests_tx [0:2];
    reg [7:0] tests_rsp [0:2];

    lfpga_spi_master #(.CLK_DIV(2)) dut (
        .clk(clk), .rst(rst), .start(start), .tx_data(tx_data),
        .rx_data(rx_data), .busy(busy), .done(done),
        .sck(sck), .mosi(mosi), .miso(miso), .cs_n(cs_n));

    always #5 clk = ~clk;

    // behavioral slave: sample mosi on rising sck, present miso after
    // falling sck (mode 0)
    always @(posedge sck) begin
        slave_rx = {slave_rx[6:0], mosi};
        edges = edges + 1;
    end
    always @(negedge sck) begin
        miso     <= slave_tx[6];             // present next bit (pre-shift)
        slave_tx <= {slave_tx[6:0], 1'b0};
    end

    task xfer(input [7:0] t, input [7:0] r);
        begin
            @(negedge clk);
            slave_tx = r; miso = r[7]; edges = 0;
            tx_data = t; start = 1;
            @(negedge clk); start = 0;
            wait (done === 1'b1);
            @(negedge clk);
            if (slave_rx !== t) begin errors = errors + 1;
                $display("FAIL: slave got %h want %h", slave_rx, t); end
            if (rx_data !== r) begin errors = errors + 1;
                $display("FAIL: master got %h want %h", rx_data, r); end
            if (edges !== 8) begin errors = errors + 1;
                $display("FAIL: %0d sck pulses", edges); end
            if (cs_n !== 1'b1 || sck !== 1'b0) begin errors = errors + 1;
                $display("FAIL: bad idle state after frame"); end
        end
    endtask

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_spi_master);
        tests_tx[0] = 8'hA5; tests_rsp[0] = 8'h3C;
        tests_tx[1] = 8'h00; tests_rsp[1] = 8'hFF;
        tests_tx[2] = 8'hF0; tests_rsp[2] = 8'h81;
        repeat (2) @(negedge clk); rst = 0;
        if (cs_n !== 1'b1) begin errors = errors + 1;
            $display("FAIL: cs_n not idle high"); end
        for (f = 0; f < 3; f = f + 1)
            xfer(tests_tx[f], tests_rsp[f]);
        if (errors == 0) $display("TB PASS: spi_master");
        else $display("TB FAIL: spi_master (%0d errors)", errors);
        $finish;
    end

    initial begin #100000 $display("TB FAIL: spi_master (timeout)"); $finish; end
endmodule
