`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// Testbench: tb_seconds_counter
// Checks   : reset -> 0 | increments only when tick_1s=1 | 58->59->00 rollover
//            min_tick is high only on the 59->00 tick (one cycle wide)
// -----------------------------------------------------------------------------
module tb_seconds_counter;

    reg        clk, rst_n, tick_1s;
    wire [5:0] sec_count;
    wire       min_tick;
    integer    errors, i;

    seconds_counter dut (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s),
        .sec_count(sec_count), .min_tick(min_tick)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Apply one tick_1s pulse; check min_tick before the edge, sec_count after it
    task do_tick;
        input [5:0] exp_sec;            // expected sec_count after the tick
        input       exp_mt;             // expected min_tick during the tick
        begin
            @(negedge clk); tick_1s = 1'b1; #1;
            if (min_tick !== exp_mt) begin
                errors = errors + 1;
                $display("FAIL: min_tick=%b expected %b (going to %0d)", min_tick, exp_mt, exp_sec);
            end
            @(negedge clk); tick_1s = 1'b0;
            if (sec_count !== exp_sec) begin
                errors = errors + 1;
                $display("FAIL: sec_count=%0d expected %0d", sec_count, exp_sec);
            end
        end
    endtask

    initial begin
        if ($test$plusargs("dump")) begin
            $dumpfile("tb_seconds_counter.vcd");
            $dumpvars(0, tb_seconds_counter);
        end
        errors = 0; tick_1s = 1'b0; rst_n = 1'b0;

        // Reset
        #12;
        if (sec_count !== 6'd0) begin errors = errors + 1; $display("FAIL: reset value"); end
        @(negedge clk); rst_n = 1'b1;

        // No tick -> no change
        repeat (5) @(negedge clk);
        if (sec_count !== 6'd0) begin errors = errors + 1; $display("FAIL: counted without tick_1s"); end

        // Two full minutes of ticks: 0->1 ... 59->0 ... 59->0
        for (i = 0; i < 120; i = i + 1)
            do_tick((i + 1) % 60, ((i % 60) == 59));

        // At 00 with tick low, min_tick must stay low
        for (i = 0; i < 59; i = i + 1) do_tick(i + 1, 1'b0);
        @(negedge clk);
        if (min_tick !== 1'b0) begin errors = errors + 1; $display("FAIL: min_tick high without tick_1s"); end

        // Async reset in the middle
        #2 rst_n = 1'b0; #1;
        if (sec_count !== 6'd0) begin errors = errors + 1; $display("FAIL: async reset"); end

        if (errors == 0) $display("PASS: tb_seconds_counter - all checks passed");
        else             $display("FAIL: tb_seconds_counter - %0d error(s)", errors);
        $finish;
    end

endmodule
