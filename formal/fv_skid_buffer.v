// libfpga formal :: lfpga_skid_buffer honors the valid/ready contract
// SPDX-License-Identifier: MIT

module fv_skid_buffer (input clk, input rst, input s_valid,
                       input [7:0] s_data, input m_ready);
    wire s_ready, m_valid;
    wire [7:0] m_data;
    lfpga_skid_buffer #(.WIDTH(8)) dut (
        .clk(clk), .rst(rst),
        .s_valid(s_valid), .s_ready(s_ready), .s_data(s_data),
        .m_valid(m_valid), .m_ready(m_ready), .m_data(m_data));

    initial assume (rst);

    // remember the previous cycle to state temporal properties
    reg had_reset = 0;
    reg p_valid, p_ready;
    reg [7:0] p_data;
    always @(posedge clk) begin
        had_reset <= 1;
        p_valid <= m_valid; p_ready <= m_ready; p_data <= m_data;
    end

    always @(*) if (had_reset && !rst) begin
        // master VALID must not drop until a transfer completes:
        // if last cycle m_valid && !m_ready, this cycle m_valid holds
        // and the payload is unchanged.
        if (p_valid && !p_ready) begin
            assert (m_valid);
            assert (m_data == p_data);
        end
    end
endmodule
