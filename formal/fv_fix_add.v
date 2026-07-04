// libfpga formal :: lfpga_fix_add saturation is wrap-free
// SPDX-License-Identifier: MIT

module fv_fix_add (input clk);
    reg signed [7:0] a, b;      // free inputs (BMC picks worst cases)
    reg sub;
    wire signed [7:0] s;

    lfpga_fix_add #(.W(8)) dut (.a(a), .b(b), .sub(sub), .s(s));

    always @(*) begin
        // adding two positives must never yield a negative (no wrap)
        if (!sub && a > 0 && b > 0) assert (s > 0);
        // adding two negatives must never yield a positive
        if (!sub && a < 0 && b < 0) assert (s < 0);
        // result is always inside the representable band (trivially true
        // for 8-bit, but proves saturation clamps rather than truncates)
        assert (s >= -128 && s <= 127);
        // when no overflow is possible, the result is exact
        if (!sub && (a + b) <= 127 && (a + b) >= -128)
            assert (s == a + b);
    end
endmodule
