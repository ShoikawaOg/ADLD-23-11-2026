// -----------------------------------------------------------------------------
// Module : minutes_counter     (Member 3 - Minutes Counter)
// Purpose: Count 0..59, incrementing only when min_tick is high. On rollover
//          (59 -> 0) hour_tick is asserted for one clock cycle.
//          (Equivalent to the "Minutes counter (divide-by-60)" block.)
// Design : hour_tick is decoded from the current state and min_tick, so the
//          hours counter updates on the same clock edge (23:59:59 -> 00:00:00
//          happens in a single edge).
// Reset  : asynchronous, active low (rst_n)
// -----------------------------------------------------------------------------
module minutes_counter(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       min_tick,     // increment enable from seconds_counter
    output reg  [5:0] min_count,    // 0..59
    output reg        hour_tick     // 1-cycle carry to the hours counter
);

    // Carry: high when a minute tick arrives while minutes = 59
    always @(*) begin
        hour_tick = min_tick && (min_count == 6'd59);
    end

    // Count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            min_count <= 6'd0;
        else if (min_tick) begin
            if (min_count == 6'd59)
                min_count <= 6'd0;
            else
                min_count <= min_count + 6'd1;
        end
    end

endmodule
