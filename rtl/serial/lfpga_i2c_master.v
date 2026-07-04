// libfpga :: lfpga_i2c_master — single-master I2C controller (7-bit addr)
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Byte-level I2C master: you issue START / WRITE / READ / STOP commands,
// it drives SCL/SDA with the classic four-phase bit timing and reports
// ACK/NACK. Open-drain: the module only ever drives lines LOW (via the
// *_oe outputs); external pull-ups provide the HIGH. Wire the pins as:
//   assign scl = scl_oe ? 1'b0 : 1'bz;   assign sda = sda_oe ? 1'b0 : 1'bz;
//   assign sda_i = sda;
// SCL frequency = clk / (4 * CLK_DIV). Single master, no clock-stretch or
// multi-master arbitration (add a stretch wait on a real SCL sense line
// if your slaves need it).

module lfpga_i2c_master #(
    parameter integer CLK_DIV = 25          // 100 MHz / (4*25) = 1 MHz... use 250 for 100 kHz
) (
    input  wire       clk,
    input  wire       rst,
    // command interface
    input  wire       cmd_valid,            // pulse to start a command
    input  wire [1:0] cmd,                  // 0 START, 1 WRITE, 2 READ, 3 STOP
    input  wire       ack_in,               // for READ: ACK(0)/NACK(1) to send
    input  wire [7:0] wr_data,              // for WRITE
    output reg  [7:0] rd_data,              // from READ
    output reg        ack_out,              // WRITE: slave's ACK(0)/NACK(1)
    output reg        busy,
    output reg        done,                 // 1-cycle pulse when a cmd finishes
    // open-drain pin controls
    output reg        scl_oe,               // 1 = pull SCL low
    output reg        sda_oe,               // 1 = pull SDA low
    input  wire       sda_i                 // sampled SDA (post pull-up)
);
    localparam CMD_START = 2'd0, CMD_WRITE = 2'd1,
               CMD_READ  = 2'd2, CMD_STOP  = 2'd3;

    // quarter-bit tick generator
    localparam integer CW = $clog2(CLK_DIV);
    reg [CW:0] div;
    wire tick = (div == CLK_DIV[CW:0] - 1);
    always @(posedge clk)
        if (rst || !busy) div <= 0;
        else              div <= tick ? 0 : div + 1'b1;

    // FSM
    localparam S_IDLE=0, S_START=1, S_WRITE=2, S_WR_ACK=3,
               S_READ=4, S_RD_ACK=5, S_STOP=6;
    reg [2:0] state;
    reg [1:0] phase;        // quarter-bit phase 0..3
    reg [2:0] bitcnt;
    reg [7:0] sh;

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            state <= S_IDLE; busy <= 0; scl_oe <= 0; sda_oe <= 0;
            phase <= 0; ack_out <= 1'b1;
        end else if (!busy) begin
            if (cmd_valid) begin
                busy <= 1'b1; phase <= 0; bitcnt <= 3'd7;
                sh <= wr_data;
                case (cmd)
                    CMD_START: state <= S_START;
                    CMD_WRITE: state <= S_WRITE;
                    CMD_READ:  state <= S_READ;
                    CMD_STOP:  state <= S_STOP;
                    default:   state <= S_STOP;
                endcase
            end
        end else if (tick) begin
            phase <= phase + 2'd1;
            case (state)
                // START: SDA high->low while SCL high
                //   phase0 SDA=1 SCL=1, p1 SDA=0 SCL=1, p2 SCL=0, p3 done
                S_START: begin
                    sda_oe <= (phase >= 2'd1);          // drive SDA low from p1
                    scl_oe <= (phase >= 2'd2);          // SCL low from p2
                    if (phase == 2'd3) begin busy<=0; done<=1; state<=S_IDLE; end
                end
                // WRITE one bit per 4 phases: p0 set SDA & SCL low,
                //   p1 SCL high, p2 SCL high (slave samples), p3 SCL low
                S_WRITE: begin
                    if (phase == 2'd0) begin
                        sda_oe <= ~sh[7];               // MSB first (0=>drive low)
                        scl_oe <= 1'b1;
                    end else if (phase == 2'd1) begin
                        scl_oe <= 1'b0;                 // release SCL (may stretch)
                    end else if (phase == 2'd3) begin
                        scl_oe <= 1'b1;                 // SCL low, next bit
                        sh <= {sh[6:0], 1'b0};
                        if (bitcnt == 0) state <= S_WR_ACK;
                        else bitcnt <= bitcnt - 3'd1;
                    end
                end
                // WR_ACK: release SDA, clock once, sample slave ACK
                S_WR_ACK: begin
                    if (phase == 2'd0) begin sda_oe <= 1'b0; scl_oe <= 1'b1; end
                    else if (phase == 2'd1) scl_oe <= 1'b0;
                    else if (phase == 2'd2) ack_out <= sda_i;   // 0=ACK
                    else if (phase == 2'd3) begin
                        scl_oe <= 1'b1; busy<=0; done<=1; state<=S_IDLE;
                    end
                end
                // READ one bit per 4 phases, SDA released, sample at SCL high
                S_READ: begin
                    if (phase == 2'd0) begin sda_oe <= 1'b0; scl_oe <= 1'b1; end
                    else if (phase == 2'd1) scl_oe <= 1'b0;
                    else if (phase == 2'd2) sh <= {sh[6:0], sda_i};
                    else if (phase == 2'd3) begin
                        scl_oe <= 1'b1;
                        if (bitcnt == 0) state <= S_RD_ACK;
                        else bitcnt <= bitcnt - 3'd1;
                    end
                end
                // RD_ACK: master drives ack_in, one clock
                S_RD_ACK: begin
                    if (phase == 2'd0) begin sda_oe <= ~ack_in ? 1'b1:1'b0; scl_oe <= 1'b1; end
                    else if (phase == 2'd1) scl_oe <= 1'b0;
                    else if (phase == 2'd3) begin
                        scl_oe <= 1'b1; sda_oe <= 1'b0;
                        rd_data <= sh; busy<=0; done<=1; state<=S_IDLE;
                    end
                end
                // STOP: SDA low->high while SCL high
                S_STOP: begin
                    if (phase == 2'd0) begin sda_oe <= 1'b1; scl_oe <= 1'b1; end
                    else if (phase == 2'd1) scl_oe <= 1'b0;   // SCL high
                    else if (phase == 2'd2) sda_oe <= 1'b0;   // SDA high = STOP
                    else if (phase == 2'd3) begin busy<=0; done<=1; state<=S_IDLE; end
                end
            endcase
        end
    end
endmodule
