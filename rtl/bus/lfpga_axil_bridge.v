// libfpga :: lfpga_axil_bridge — AXI4-Lite slave to simple register-bus bridge
// https://github.com/libfpga/libfpga  |  docs & playground: https://libfpga.com
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Antonio Roldao, Ph.D.
//
// Terminates the AXI4-Lite handshake (single outstanding transaction)
// and exposes a simple synchronous register interface: one write strobe
// with address/data/strb, and a read address whose reg_rdata must be
// valid combinationally in the same cycle (default for register files).
// Generate a full CSR block instead at libfpga.com/tools/register-map.

module lfpga_axil_bridge #(
    parameter integer ADDR_WIDTH = 8
) (
    input  wire                    clk,
    input  wire                    rst_n,
    // AXI4-Lite slave
    input  wire [ADDR_WIDTH-1:0]   s_axil_awaddr,
    input  wire                    s_axil_awvalid,
    output reg                     s_axil_awready,
    input  wire [31:0]             s_axil_wdata,
    input  wire [3:0]              s_axil_wstrb,
    input  wire                    s_axil_wvalid,
    output reg                     s_axil_wready,
    output reg  [1:0]              s_axil_bresp,
    output reg                     s_axil_bvalid,
    input  wire                    s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]   s_axil_araddr,
    input  wire                    s_axil_arvalid,
    output reg                     s_axil_arready,
    output reg  [31:0]             s_axil_rdata,
    output reg  [1:0]              s_axil_rresp,
    output reg                     s_axil_rvalid,
    input  wire                    s_axil_rready,
    // simple register bus
    output reg                     reg_wen,     // 1-cycle write strobe
    output reg  [ADDR_WIDTH-1:0]   reg_waddr,
    output reg  [31:0]             reg_wdata,
    output reg  [3:0]              reg_wstrb,
    output wire [ADDR_WIDTH-1:0]   reg_raddr,
    input  wire [31:0]             reg_rdata    // combinational response
);
    wire wr_en = s_axil_awvalid & s_axil_wvalid & ~s_axil_bvalid
                 & ~s_axil_awready;
    wire rd_en = s_axil_arvalid & ~s_axil_rvalid & ~s_axil_arready;

    assign reg_raddr = s_axil_araddr;

    always @(posedge clk) begin
        if (!rst_n) begin
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;
            s_axil_bvalid  <= 1'b0;
            s_axil_bresp   <= 2'b00;
            reg_wen        <= 1'b0;
        end else begin
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;
            reg_wen        <= 1'b0;
            if (wr_en) begin
                s_axil_awready <= 1'b1;
                s_axil_wready  <= 1'b1;
                s_axil_bvalid  <= 1'b1;
                s_axil_bresp   <= 2'b00;
                reg_wen   <= 1'b1;
                reg_waddr <= s_axil_awaddr;
                reg_wdata <= s_axil_wdata;
                reg_wstrb <= s_axil_wstrb;
            end
            if (s_axil_bvalid && s_axil_bready)
                s_axil_bvalid <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid  <= 1'b0;
            s_axil_rresp   <= 2'b00;
            s_axil_rdata   <= 32'd0;
        end else begin
            s_axil_arready <= 1'b0;
            if (rd_en) begin
                s_axil_arready <= 1'b1;
                s_axil_rvalid  <= 1'b1;
                s_axil_rresp   <= 2'b00;
                s_axil_rdata   <= reg_rdata;
            end
            if (s_axil_rvalid && s_axil_rready)
                s_axil_rvalid <= 1'b0;
        end
    end
endmodule
