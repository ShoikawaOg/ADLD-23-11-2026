`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// Testbench: tb_minutes_counter
// Checks   : reset -> 0 | increments only when min_tick=1 | 58->59->00 rollover
//            hour_tick is high only on the 59->00 step (one cycle wide)
// -----------------------------------------------------------------------------
module tb_minutes_counter;

    reg        clk, rst_n, min_tick;
    wire [5:0] min_count;
    wire       hour_tick;
    integer    errors, i;

    minutes_counter dut (
        .clk(clk), .rst_n(rst_n), .min_tick(min_tick),
        .min_count(min_count), .hour_tick(hour_tick)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Apply one min_tick pulse; check hour_tick before the edge, min_count after it
    task do_tick;
        input [5:0] exp_min;
        input       exp_ht;
        begin
            @(negedge clk); min_tick = 1'b1; #1;
            if (hour_tick !== exp_ht) begin
                errors = errors + 1;
                $display("FAIL: hour_tick=%b expected %b (going to %0d)", hour_tick, exp_ht, exp_min);
            end
            @(negedge clk); min_tick = 1'b0;
            if (min_count !== exp_min) begin
                errors = errors + 1;
                $display("FAIL: min_count=%0d expected %0d", min_count, exp_min);
            end
        end
    endtask

    initial begin
        if ($test$plusargs("dump")) begin
            $dumpfile("tb_minutes_counter.vcd");
            $dumpvars(0, tb_minutes_counter);
        end
        errors = 0; min_tick = 1'b0; rst_n = 1'b0;

        // Reset
        #12;
        if (min_count !== 6'd0) begin errors = errors + 1; $display("FAIL: reset value"); end
        @(negedge clk); rst_n = 1'b1;

        // No tick -> no change
        repeat (5) @(negedge clk);
        if (min_count !== 6'd0) begin errors = errors + 1; $display("FAIL: counted without min_tick"); end

        // Two full hours of ticks
        for (i = 0; i < 120; i = i + 1)
            do_tick((i + 1) % 60, ((i % 60) == 59));

        // hour_tick must stay low when min_tick is low
        for (i = 0; i < 59; i = i + 1) do_tick(i + 1, 1'b0);
        @(negedge clk);
        if (hour_tick !== 1'b0) begin errors = errors + 1; $display("FAIL: hour_tick high without min_tick"); end

        // Async reset in the middle
        #2 rst_n = 1'b0; #1;
        if (min_count !== 6'd0) begin errors = errors + 1; $display("FAIL: async reset"); end

        if (errors == 0) $display("PASS: tb_minutes_counter - all checks passed");
        else             $display("FAIL: tb_minutes_counter - %0d error(s)", errors);
        $finish;
    end

endmodule
