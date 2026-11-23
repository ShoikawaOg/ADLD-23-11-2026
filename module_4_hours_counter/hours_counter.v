// -----------------------------------------------------------------------------
// Module : hours_counter       (Member 4 - Hours Counter)
// Purpose: 24-hour counter, 0..23, incrementing only when hour_tick is high.
//          23 -> 00 is the day rollover.
//          (The textbook diagram is a 12-hour clock; this is the 24-hour version.)
// Reset  : asynchronous, active low (rst_n)
// -----------------------------------------------------------------------------
module hours_counter(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       hour_tick,    // increment enable from minutes_counter
    output reg  [4:0] hour_count    // 0..23
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            hour_count <= 5'd0;
        else if (hour_tick) begin
            if (hour_count == 5'd23)
                hour_count <= 5'd0;             // 23 -> 00
            else
                hour_count <= hour_count + 5'd1;
        end
    end

endmodule
