`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// Testbench: tb_digital_clock_top   (system-level, also verifies display_ctrl)
// Method   : a reference model computes the expected time from the number of
//            clock edges since reset release, then every cycle the six BCD
//            outputs are compared against it. Runs one FULL DAY plus a little
//            more, so it covers 00:00:59->00:01:00, 00:59:59->01:00:00 and
//            23:59:59->00:00:00 and every BCD digit.
// Note     : CLK_FREQ_HZ = 2 here, so "1 second" = 2 clock cycles.
// -----------------------------------------------------------------------------
module tb_digital_clock_top;

    localparam integer N = 2;                   // clock cycles per "second"

    reg        clk, rst_n;
    wire [3:0] hour_tens, hour_ones, min_tens, min_ones, sec_tens, sec_ones;

    integer errors;
    integer k;                                  // clock edges since reset release
    integer total, h, m, s;                     // reference model

    digital_clock_top #(.CLK_FREQ_HZ(N)) dut (
        .clk(clk), .rst_n(rst_n),
        .hour_tens(hour_tens), .hour_ones(hour_ones),
        .min_tens(min_tens),   .min_ones(min_ones),
        .sec_tens(sec_tens),   .sec_ones(sec_ones)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Count clock edges after reset is released
    always @(posedge clk) if (rst_n) k = k + 1;

    // Reference model + checker, sampled on the falling edge
    // tick_1s is registered, so the first second is counted after edge N+1:
    //   total seconds after k edges = (k-1)/N   (0 while k = 0)
    always @(negedge clk) begin
        if (rst_n) begin
            total = (k > 0) ? ((k - 1) / N) : 0;
            h = (total / 3600) % 24;
            m = (total / 60)   % 60;
            s = total % 60;
            if (hour_tens !== h/10 || hour_ones !== h%10 ||
                min_tens  !== m/10 || min_ones  !== m%10 ||
                sec_tens  !== s/10 || sec_ones  !== s%10) begin
                errors = errors + 1;
                if (errors < 10)
                    $display("FAIL @%0t: got %0d%0d:%0d%0d:%0d%0d expected %0d:%0d:%0d",
                             $time, hour_tens, hour_ones, min_tens, min_ones,
                             sec_tens, sec_ones, h, m, s);
            end
        end
    end

    initial begin
        // (waveform of a full day is huge, so dumping is opt-in: vvp sim +dump)
        if ($test$plusargs("dump")) begin
            $dumpfile("tb_digital_clock_top.vcd");
            $dumpvars(0, tb_digital_clock_top);
        end
        errors = 0; k = 0; rst_n = 1'b0;

        // Reset -> 00:00:00
        #23;
        if ({hour_tens,hour_ones,min_tens,min_ones,sec_tens,sec_ones} !== 24'h000000) begin
            errors = errors + 1; $display("FAIL: outputs not 00:00:00 in reset");
        end
        @(negedge clk); rst_n = 1'b1;

        // Run one full day (86400 s) plus a few seconds to cross 23:59:59 -> 00:00:00
        repeat (N * (86400 + 5)) @(negedge clk);

        // Asynchronous reset in the middle of operation
        #2 rst_n = 1'b0; #1;
        if ({hour_tens,hour_ones,min_tens,min_ones,sec_tens,sec_ones} !== 24'h000000) begin
            errors = errors + 1; $display("FAIL: async reset did not clear the clock");
        end

        if (errors == 0) $display("PASS: tb_digital_clock_top - full 24-hour day verified");
        else             $display("FAIL: tb_digital_clock_top - %0d mismatch(es)", errors);
        $finish;
    end

endmodule
