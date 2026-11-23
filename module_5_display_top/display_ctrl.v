// -----------------------------------------------------------------------------
// Module : display_ctrl        (Member 5 - Display Controller)
// Purpose: Convert the binary hour/minute/second counts into six BCD digits
//          (tens and ones). Example: 14:35:48 -> 1,4 : 3,5 : 4,8.
//          (Replaces the BCD-per-digit counters of the textbook diagram; the
//           BCD -> 7-segment decoders are outside this design.)
// Type   : purely combinational (no clock / reset)
// -----------------------------------------------------------------------------
module display_ctrl(
    input  wire [4:0] hour_count,   // 0..23
    input  wire [5:0] min_count,    // 0..59
    input  wire [5:0] sec_count,    // 0..59
    output reg  [3:0] hour_tens,
    output reg  [3:0] hour_ones,
    output reg  [3:0] min_tens,
    output reg  [3:0] min_ones,
    output reg  [3:0] sec_tens,
    output reg  [3:0] sec_ones
);

    // Division / modulo by the constant 10 -> small combinational logic
    always @(*) begin
        hour_tens = hour_count / 10;
        hour_ones = hour_count % 10;
        min_tens  = min_count  / 10;
        min_ones  = min_count  % 10;
        sec_tens  = sec_count  / 10;
        sec_ones  = sec_count  % 10;
    end

endmodule
