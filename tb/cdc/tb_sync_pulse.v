// Self-checking testbench for lfpga_sync_pulse.
// Unrelated clock periods (10 ns / 7 ns); every sent pulse must arrive
// exactly once and be exactly one clk_dst cycle wide.
`timescale 1ns/1ps
module tb_sync_pulse;
    reg clk_src = 0, clk_dst = 0;
    reg pulse_src = 0;
    wire pulse_dst;
    integer sent = 0, received = 0, errors = 0;
    reg prev_dst = 0;

    lfpga_sync_pulse #(.STAGES(2)) dut (
        .clk_src(clk_src), .pulse_src(pulse_src),
        .clk_dst(clk_dst), .pulse_dst(pulse_dst));

    always #5 clk_src = ~clk_src;
    always #3.5 clk_dst = ~clk_dst;

    // count arrivals; flag any 2-cycle-wide pulse
    always @(posedge clk_dst) begin
        if (pulse_dst) received = received + 1;
        if (pulse_dst && prev_dst) begin
            errors = errors + 1;
            $display("FAIL: pulse_dst wider than one cycle (t=%0t)", $time);
        end
        prev_dst <= pulse_dst;
    end

    task send_pulse;
        begin
            @(negedge clk_src) pulse_src = 1;
            @(negedge clk_src) pulse_src = 0;
            sent = sent + 1;
            repeat (6) @(posedge clk_dst);  // respect min spacing
        end
    endtask

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_sync_pulse);
        repeat (4) @(posedge clk_dst);
        repeat (8) send_pulse;
        repeat (8) @(posedge clk_dst);

        if (received !== sent) begin
            errors = errors + 1;
            $display("FAIL: sent %0d pulses, received %0d", sent, received);
        end
        if (errors == 0) $display("TB PASS: sync_pulse");
        else             $display("TB FAIL: sync_pulse (%0d errors)", errors);
        $finish;
    end
endmodule
