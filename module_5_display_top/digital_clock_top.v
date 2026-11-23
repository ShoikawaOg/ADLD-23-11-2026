// -----------------------------------------------------------------------------
// Module : digital_clock_top   (Member 5 - Top-level integration)
// Purpose: 24-hour digital clock (HH:MM:SS) with BCD outputs.
//
//   clk,rst_n -> tick_gen -> seconds_counter -> minutes_counter -> hours_counter
//                 (1 s)        (min_tick)         (hour_tick)          |
//                                                                      v
//                              sec/min/hour counts ------------> display_ctrl -> 6 BCD digits
//
// All blocks share ONE clock; the carries are enables, not generated clocks.
// -----------------------------------------------------------------------------
module digital_clock_top #(
    parameter integer CLK_FREQ_HZ = 50000000
)(
    input  wire       clk,
    input  wire       rst_n,
    output wire [3:0] hour_tens,
    output wire [3:0] hour_ones,
    output wire [3:0] min_tens,
    output wire [3:0] min_ones,
    output wire [3:0] sec_tens,
    output wire [3:0] sec_ones
);

    // Internal interconnect
    wire       tick_1s;
    wire       min_tick;
    wire       hour_tick;
    wire [5:0] sec_count;
    wire [5:0] min_count;
    wire [4:0] hour_count;

    tick_gen #(.CLK_FREQ_HZ(CLK_FREQ_HZ)) U_TICK_GEN (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s)
    );

    seconds_counter U_SECONDS (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s),
        .sec_count(sec_count), .min_tick(min_tick)
    );

    minutes_counter U_MINUTES (
        .clk(clk), .rst_n(rst_n), .min_tick(min_tick),
        .min_count(min_count), .hour_tick(hour_tick)
    );

    hours_counter U_HOURS (
        .clk(clk), .rst_n(rst_n), .hour_tick(hour_tick),
        .hour_count(hour_count)
    );

    display_ctrl U_DISPLAY (
        .hour_count(hour_count), .min_count(min_count), .sec_count(sec_count),
        .hour_tens(hour_tens), .hour_ones(hour_ones),
        .min_tens(min_tens),   .min_ones(min_ones),
        .sec_tens(sec_tens),   .sec_ones(sec_ones)
    );

endmodule
