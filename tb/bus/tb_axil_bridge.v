// Self-checking: AXI-Lite write/read tasks against a 4-register file,
// including a wstrb byte-lane write.
`timescale 1ns/1ps
module tb_axil_bridge;
    reg clk = 0, rst_n = 0;
    reg  [7:0]  awaddr = 0;  reg awvalid = 0; wire awready;
    reg  [31:0] wdata = 0;   reg [3:0] wstrb = 4'hF; reg wvalid = 0;
    wire wready; wire [1:0] bresp; wire bvalid; reg bready = 1;
    reg  [7:0]  araddr = 0;  reg arvalid = 0; wire arready;
    wire [31:0] rdata; wire [1:0] rresp; wire rvalid; reg rready = 1;
    wire reg_wen; wire [7:0] reg_waddr; wire [31:0] reg_wdata;
    wire [3:0] reg_wstrb; wire [7:0] reg_raddr;
    reg [31:0] regs [0:3];
    wire [31:0] reg_rdata = regs[reg_raddr[3:2]];
    integer errors = 0;
    reg [31:0] got;

    lfpga_axil_bridge #(.ADDR_WIDTH(8)) dut (
        .clk(clk), .rst_n(rst_n),
        .s_axil_awaddr(awaddr), .s_axil_awvalid(awvalid),
        .s_axil_awready(awready),
        .s_axil_wdata(wdata), .s_axil_wstrb(wstrb), .s_axil_wvalid(wvalid),
        .s_axil_wready(wready), .s_axil_bresp(bresp), .s_axil_bvalid(bvalid),
        .s_axil_bready(bready),
        .s_axil_araddr(araddr), .s_axil_arvalid(arvalid),
        .s_axil_arready(arready),
        .s_axil_rdata(rdata), .s_axil_rresp(rresp), .s_axil_rvalid(rvalid),
        .s_axil_rready(rready),
        .reg_wen(reg_wen), .reg_waddr(reg_waddr), .reg_wdata(reg_wdata),
        .reg_wstrb(reg_wstrb), .reg_raddr(reg_raddr), .reg_rdata(reg_rdata));

    always #5 clk = ~clk;

    // the register file under the bridge
    always @(posedge clk) if (reg_wen) begin
        if (reg_wstrb[0]) regs[reg_waddr[3:2]][7:0]   <= reg_wdata[7:0];
        if (reg_wstrb[1]) regs[reg_waddr[3:2]][15:8]  <= reg_wdata[15:8];
        if (reg_wstrb[2]) regs[reg_waddr[3:2]][23:16] <= reg_wdata[23:16];
        if (reg_wstrb[3]) regs[reg_waddr[3:2]][31:24] <= reg_wdata[31:24];
    end

    task axi_write(input [7:0] a, input [31:0] d, input [3:0] s);
        begin
            @(negedge clk); awaddr = a; wdata = d; wstrb = s;
            awvalid = 1; wvalid = 1;
            wait (bvalid); @(negedge clk); awvalid = 0; wvalid = 0;
            wait (!bvalid); @(negedge clk);
        end
    endtask

    task axi_read(input [7:0] a);
        begin
            @(negedge clk); araddr = a; arvalid = 1;
            wait (rvalid); got = rdata;
            @(negedge clk); arvalid = 0;
            wait (!rvalid); @(negedge clk);
        end
    endtask

    task check(input [31:0] want, input [127:0] what);
        if (got !== want) begin
            errors = errors + 1;
            $display("FAIL: %0s: got %h want %h", what, got, want);
        end
    endtask

    initial begin
        $dumpfile("wave.vcd"); $dumpvars(0, tb_axil_bridge);
        regs[0]=0; regs[1]=0; regs[2]=0; regs[3]=0;
        repeat (3) @(negedge clk); rst_n = 1;

        axi_write(8'h00, 32'hDEADBEEF, 4'hF);
        axi_read(8'h00);  check(32'hDEADBEEF, "full write/read");

        axi_write(8'h04, 32'h11223344, 4'hF);
        axi_write(8'h04, 32'hAABBCCDD, 4'b0101);   // byte lanes 0 and 2
        axi_read(8'h04);  check(32'h11BB33DD, "wstrb lanes");

        axi_write(8'h0C, 32'h0000CAFE, 4'hF);
        axi_read(8'h0C);  check(32'h0000CAFE, "reg 3");
        axi_read(8'h00);  check(32'hDEADBEEF, "reg 0 retained");

        if (errors == 0) $display("TB PASS: axil_bridge");
        else $display("TB FAIL: axil_bridge (%0d errors)", errors);
        $finish;
    end

    initial begin #100000 $display("TB FAIL: axil_bridge (timeout)"); $finish; end
endmodule
