// -----------------------------------------------------------------------------
// Module : tick_gen            (Member 1 - Clock Divider)
// Purpose: Divide the system clock down to a one-clock-cycle pulse once per
//          second. This pulse (tick_1s) is a clock ENABLE, not a clock.
//          (Replaces the 60 Hz -> divide-by-60 -> 1 Hz chain of the textbook
//           diagram with a single counter on the fast system clock.)
// Reset  : asynchronous, active low (rst_n)
// -----------------------------------------------------------------------------
module tick_gen #(
    parameter integer CLK_FREQ_HZ = 50000000   // override with a small value in simulation
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick_1s
);

    reg [31:0] cnt;                             // counts clock cycles 0 .. CLK_FREQ_HZ-1

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 32'd0;
            tick_1s <= 1'b0;
        end else if (cnt == CLK_FREQ_HZ - 1) begin
            cnt     <= 32'd0;                   // wrap
            tick_1s <= 1'b1;                    // one-cycle pulse
        end else begin
            cnt     <= cnt + 32'd1;
            tick_1s <= 1'b0;
        end
    end

endmodule
