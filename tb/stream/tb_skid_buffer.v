// Self-checking: random stalls both sides; sequence integrity; protocol
// rules (payload stable while valid && !ready; valid never drops early).
`timescale 1ns/1ps
module tb_skid_buffer;
    reg clk = 0, rst = 1;
    reg s_valid = 0; wire s_ready; reg [7:0] s_data = 0;
    wire m_valid; reg m_ready = 0; wire [7:0] m_data;
    integer sent = 0, got = 0, i, errors = 0;
    reg [7:0] next_tx;
    reg [31:0] lfsr = 32'h51CD;
    reg [7:0] held_data; reg held_valid = 0; reg s_taken = 0;

    lfpga_skid_buffer #(.WIDTH(8)) dut (
        .clk(clk), .rst(rst),
        .s_valid(s_valid), .s_ready(s_ready), .s_data(s_data),
        .m_valid(m_valid), .m_ready(m_ready), .m_data(m_data));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_skid_buffer);
        repeat (2) @(negedge clk); rst = 0;
        next_tx = 0;
        for (i = 0; i < 3000; i = i + 1) begin
            @(negedge clk);
            lfsr = {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            // source may only change its offer if the last one was taken
            if (!s_valid) begin
                s_valid = lfsr[0];
                if (s_valid) s_data = next_tx;
            end
            m_ready = lfsr[1];
            #1;
            // protocol check: output payload stable while stalled
            if (held_valid && m_valid && (m_data !== held_data)) begin
                errors = errors + 1;
                if (errors < 6) $display("FAIL: m_data changed while stalled");
            end
            if (held_valid && !m_valid) begin
                errors = errors + 1;
                if (errors < 6) $display("FAIL: m_valid dropped w/o ready");
            end
            // sample handshakes exactly as the clock edge will see them
            s_taken = s_valid && s_ready;
            if (s_taken) begin
                sent = sent + 1; next_tx = next_tx + 8'd1;
            end
            if (m_valid && m_ready) begin
                if (m_data !== got[7:0]) begin
                    errors = errors + 1;
                    if (errors < 6)
                        $display("FAIL: got %h expected %h", m_data, got[7:0]);
                end
                got = got + 1;
            end
            held_valid = m_valid && !m_ready;
            held_data  = m_data;
            @(posedge clk); #1;
            if (s_taken) s_valid = 0;   // offer consumed at that edge
        end
        if (got < 1000) begin errors = errors + 1;
            $display("FAIL: too few transfers (%0d)", got); end
        if (errors == 0) $display("TB PASS: skid_buffer");
        else $display("TB FAIL: skid_buffer (%0d errors)", errors);
        $finish;
    end
endmodule
