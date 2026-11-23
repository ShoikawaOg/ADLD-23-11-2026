`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// Testbench: tb_hours_counter
// Checks   : reset -> 0 | increments only when hour_tick=1 | 22->23->00 rollover
//            hour_count never exceeds 23
// -----------------------------------------------------------------------------
module tb_hours_counter;

    reg        clk, rst_n, hour_tick;
    wire [4:0] hour_count;
    integer    errors, i;

    hours_counter dut (
        .clk(clk), .rst_n(rst_n), .hour_tick(hour_tick), .hour_count(hour_count)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Apply one hour_tick pulse and check the result
    task do_tick;
        input [4:0] exp_hour;
        begin
            @(negedge clk); hour_tick = 1'b1;
            @(negedge clk); hour_tick = 1'b0;
            if (hour_count !== exp_hour) begin
                errors = errors + 1;
                $display("FAIL: hour_count=%0d expected %0d", hour_count, exp_hour);
            end
            if (hour_count > 5'd23) begin
                errors = errors + 1;
                $display("FAIL: hour_count exceeded 23");
            end
        end
    endtask

    initial begin
        if ($test$plusargs("dump")) begin
            $dumpfile("tb_hours_counter.vcd");
            $dumpvars(0, tb_hours_counter);
        end
        errors = 0; hour_tick = 1'b0; rst_n = 1'b0;

        // Reset
        #12;
        if (hour_count !== 5'd0) begin errors = errors + 1; $display("FAIL: reset value"); end
        @(negedge clk); rst_n = 1'b1;

        // No tick -> no change
        repeat (5) @(negedge clk);
        if (hour_count !== 5'd0) begin errors = errors + 1; $display("FAIL: counted without hour_tick"); end

        // Two full days of ticks
        for (i = 0; i < 48; i = i + 1)
            do_tick((i + 1) % 24);

        // Async reset in the middle
        do_tick(5'd1); do_tick(5'd2);
        #2 rst_n = 1'b0; #1;
        if (hour_count !== 5'd0) begin errors = errors + 1; $display("FAIL: async reset"); end

        if (errors == 0) $display("PASS: tb_hours_counter - all checks passed");
        else             $display("FAIL: tb_hours_counter - %0d error(s)", errors);
        $finish;
    end

endmodule
