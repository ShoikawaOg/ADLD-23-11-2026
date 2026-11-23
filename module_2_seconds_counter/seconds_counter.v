// -----------------------------------------------------------------------------
// Module : seconds_counter     (Member 2 - Seconds Counter)
// Purpose: Count 0..59 on every tick_1s. When the count rolls over (59 -> 0)
//          min_tick is asserted for one clock cycle to enable the minutes counter.
//          (Equivalent to CTR DIV 10 + CTR DIV 6 of the textbook diagram.)
// Design : min_tick is decoded from the current state, so the minutes counter
//          increments on the SAME clock edge that seconds wraps to 00
//          -> the display never shows an inconsistent time.
// Reset  : asynchronous, active low (rst_n)
// -----------------------------------------------------------------------------
module seconds_counter(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick_1s,      // increment enable (one pulse per second)
    output reg  [5:0] sec_count,    // 0..59
    output reg        min_tick      // 1-cycle carry to the minutes counter
);

    // Carry: high for exactly one cycle (same width as tick_1s) when 59 rolls to 0
    always @(*) begin
        min_tick = tick_1s && (sec_count == 6'd59);
    end

    // Count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sec_count <= 6'd0;
        else if (tick_1s) begin
            if (sec_count == 6'd59)
                sec_count <= 6'd0;
            else
                sec_count <= sec_count + 6'd1;
        end
    end

endmodule
