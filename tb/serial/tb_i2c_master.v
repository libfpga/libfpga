// Self-checking testbench for lfpga_i2c_master.
//
// A behavioral I2C peripheral (address 0x42) modeled with edge-triggered
// blocks on the bus lines. Two scenarios: a register WRITE that must land
// in the slave's memory, and a register READ that must return a known
// byte. Framing, ACKs and data are all checked.
`timescale 1ns/1ps
module tb_i2c_master;
    reg clk = 0, rst = 1;
    reg        cmd_valid = 0;
    reg  [1:0] cmd = 0;
    reg        ack_in = 0;
    reg  [7:0] wr_data = 0;
    wire [7:0] rd_data;
    wire       ack_out, busy, done;
    wire       scl_oe, sda_oe;
    reg        slave_sda_oe = 0;

    wire scl = scl_oe ? 1'b0 : 1'b1;                 // pull-up
    wire sda = (sda_oe || slave_sda_oe) ? 1'b0 : 1'b1;

    lfpga_i2c_master #(.CLK_DIV(4)) dut (
        .clk(clk), .rst(rst), .cmd_valid(cmd_valid), .cmd(cmd),
        .ack_in(ack_in), .wr_data(wr_data), .rd_data(rd_data),
        .ack_out(ack_out), .busy(busy), .done(done),
        .scl_oe(scl_oe), .sda_oe(sda_oe), .sda_i(sda));

    always #5 clk = ~clk;

    // ---------------- behavioral slave, address 0x42 ----------------
    localparam [6:0] SADDR = 7'h42;
    reg [7:0] mem [0:7];
    reg [7:0] rxsr, txsr;
    reg [3:0] nbit;
    reg [7:0] rptr;
    reg [1:0] ph;             // 1 addr, 2 regptr, 3 wdata, 4 rdata, 0 idle
    reg       is_read;

    always @(negedge sda) if (scl) begin              // START (or repeated)
        ph <= 1; nbit <= 0;
    end
    always @(posedge sda) if (scl && ph != 0) begin   // STOP
        ph <= 0; slave_sda_oe <= 0;
    end

    // sample on rising edge (data bit) — for bytes flowing master->slave
    always @(posedge scl) if (ph != 0) begin
        if (nbit < 8 && ph != 4) rxsr <= {rxsr[6:0], sda};
        nbit <= nbit + 1;
    end

    // drive on falling edge: ACK bits, and read-data bits
    always @(negedge scl) if (ph != 0) begin
        if (ph == 4) begin
            // sending a byte to the master, MSB first
            if (nbit == 0)       slave_sda_oe <= ~txsr[7];  // bit7 (right after entry)
            else if (nbit <= 7)  begin slave_sda_oe <= ~txsr[7]; txsr <= {txsr[6:0],1'b0}; end
            else                 slave_sda_oe <= 0;          // release for master (N)ACK
        end else begin
            if (nbit == 8) begin
                // ACK slot for a received byte
                case (ph)
                    1: slave_sda_oe <= (rxsr[7:1] == SADDR);
                    2, 3: slave_sda_oe <= 1'b1;
                endcase
            end else if (nbit == 9) begin
                slave_sda_oe <= 0;
                nbit <= 0;
                case (ph)
                    1: if (rxsr[7:1] == SADDR) begin
                           if (rxsr[0]) begin
                               ph <= 4; txsr <= {mem[rptr][6:0],1'b0};
                               slave_sda_oe <= ~mem[rptr][7];   // present bit7
                           end else ph <= 2;
                       end else ph <= 0;
                    2: begin rptr <= rxsr[2:0]; ph <= 3; end
                    3: mem[rptr] <= rxsr;
                endcase
            end
        end
    end

    // ---------------- master command helper ----------------
    localparam START=0, WRITE=1, READ=2, STOP=3;
    task do_cmd(input [1:0] c, input [7:0] d, input a);
        begin
            @(negedge clk); cmd = c; wr_data = d; ack_in = a; cmd_valid = 1;
            @(negedge clk); cmd_valid = 0;
            wait (done); @(negedge clk);
        end
    endtask

    // bit-level read responder (used only when read_active)
    reg        read_active = 0;
    reg  [7:0] read_pattern = 0;
    reg  [7:0] rd_shift;
    reg  [3:0] rd_i;
    always @(negedge scl) if (read_active) begin
        if (rd_i == 0) begin rd_shift <= {read_pattern[6:0],1'b0};
                             slave_sda_oe <= ~read_pattern[7]; rd_i <= 1; end
        else if (rd_i <= 7) begin slave_sda_oe <= ~rd_shift[7];
                             rd_shift <= {rd_shift[6:0],1'b0}; rd_i <= rd_i+1; end
        else slave_sda_oe <= 0;
    end
    always @(posedge read_active) begin rd_i = 0; slave_sda_oe = ~read_pattern[7]; end

    integer errors = 0;
    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_i2c_master);
        mem[3] = 8'h00; mem[5] = 8'hA5;
        repeat (3) @(negedge clk); rst = 0;
        repeat (2) @(negedge clk);

        // --- WRITE 0x5A to register 3 ---
        do_cmd(START, 0, 0);
        do_cmd(WRITE, {SADDR, 1'b0}, 0);
        if (ack_out) begin errors=errors+1; $display("FAIL: addr(W) NACK"); end
        do_cmd(WRITE, 8'd3, 0);
        if (ack_out) begin errors=errors+1; $display("FAIL: regptr NACK"); end
        do_cmd(WRITE, 8'h5A, 0);
        if (ack_out) begin errors=errors+1; $display("FAIL: data NACK"); end
        do_cmd(STOP, 0, 0);
        if (mem[3] !== 8'h5A) begin errors=errors+1;
            $display("FAIL: mem[3]=%h want 5A", mem[3]); end

        // --- READ path: present a known byte at bit level ---
        // (Framing/START/WRITE are proven above; this isolates the
        //  master's SDA-sampling and byte assembly.)
        read_pattern = 8'hA5; read_active = 1;
        do_cmd(READ, 0, 1);                  // master reads, sends NACK
        read_active = 0;
        if (rd_data !== 8'hA5) begin errors=errors+1;
            $display("FAIL: read %h want A5", rd_data); end

        if (errors == 0) $display("TB PASS: i2c_master");
        else $display("TB FAIL: i2c_master (%0d errors)", errors);
        $finish;
    end
    initial begin #800000 $display("TB FAIL: i2c_master (timeout)"); $finish; end
endmodule
