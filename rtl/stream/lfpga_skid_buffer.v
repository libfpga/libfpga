// libfpga :: lfpga_skid_buffer — valid/ready register slice, full throughput, breaks the ready path
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Registers both data and the backpressure path so timing doesn't chain
// through long ready networks. One transfer per cycle sustained; AXI-
// Stream compatible handshake (valid must not wait for ready).

module lfpga_skid_buffer #(
    parameter integer WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             s_valid,
    output wire             s_ready,
    input  wire [WIDTH-1:0] s_data,
    output reg              m_valid,
    input  wire             m_ready,
    output reg  [WIDTH-1:0] m_data
);
    reg             skid_valid;
    reg [WIDTH-1:0] skid_data;

    assign s_ready = !skid_valid;

    always @(posedge clk) begin
        if (rst) begin
            m_valid    <= 1'b0;
            skid_valid <= 1'b0;
        end else begin
            if (s_valid && s_ready) begin
                if (!m_valid || m_ready) begin
                    m_valid <= 1'b1;
                    m_data  <= s_data;
                end else begin
                    skid_valid <= 1'b1;   // main reg busy: park it
                    skid_data  <= s_data;
                end
            end else if (m_ready && skid_valid) begin
                m_valid    <= 1'b1;
                m_data     <= skid_data;
                skid_valid <= 1'b0;
            end else if (m_ready && !skid_valid) begin
                m_valid <= 1'b0;
            end
        end
    end
endmodule
