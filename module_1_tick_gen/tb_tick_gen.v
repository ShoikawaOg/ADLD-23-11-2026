`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// Testbench: tb_tick_gen
// Checks   : (1) tick_1s is low during reset
//            (2) tick_1s is exactly 1 clock cycle wide
//            (3) tick period == CLK_FREQ_HZ clock cycles
//            (4) asynchronous reset clears tick_1s and restarts the count
// Note     : CLK_FREQ_HZ is overridden with a small value so "1 second" is short.
// -----------------------------------------------------------------------------
module tb_tick_gen;

    localparam integer N = 5;                   // "1 second" = 5 clock cycles in simulation

    reg  clk;
    reg  rst_n;
    wire tick_1s;

    integer errors;
    integer cycles;                             // clock cycles since last tick
    integer ticks;                              // ticks seen since (re)start
    reg     seen;                               // at least one tick seen since (re)start
    reg     prev_tick;

    // Device under test
    tick_gen #(.CLK_FREQ_HZ(N)) dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .tick_1s(tick_1s)
    );

    // 10 ns clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Monitor: sample on the falling edge (away from the active edge -> no races)
    always @(negedge clk) begin
        if (rst_n) begin
            cycles = cycles + 1;
            if (tick_1s) begin
                if (seen && (cycles != N)) begin
                    errors = errors + 1;
                    $display("FAIL: tick period = %0d cycles, expected %0d", cycles, N);
                end
                if (prev_tick && (N > 1)) begin
                    errors = errors + 1;
                    $display("FAIL: tick_1s wider than one clock cycle");
                end
                seen   = 1'b1;
                cycles = 0;
                ticks  = ticks + 1;
            end
            prev_tick = tick_1s;
        end
    end

    initial begin
        if ($test$plusargs("dump")) begin
            $dumpfile("tb_tick_gen.vcd");
            $dumpvars(0, tb_tick_gen);
        end
        errors = 0; cycles = 0; ticks = 0; seen = 1'b0; prev_tick = 1'b0;

        // (1) reset: output must be 0
        rst_n = 1'b0;
        #23;
        if (tick_1s !== 1'b0) begin errors = errors + 1; $display("FAIL: tick_1s not 0 in reset"); end
        @(negedge clk); rst_n = 1'b1;

        // (2),(3) let 6 ticks happen
        wait (ticks == 6);

        // (4) asynchronous reset in the middle of operation
        #2 rst_n = 1'b0;
        #1 if (tick_1s !== 1'b0) begin errors = errors + 1; $display("FAIL: async reset did not clear tick_1s"); end
        @(negedge clk); @(negedge clk);
        cycles = 0; ticks = 0; seen = 1'b0; prev_tick = 1'b0;
        rst_n = 1'b1;
        wait (ticks == 3);

        if (errors == 0) $display("PASS: tb_tick_gen - all checks passed");
        else             $display("FAIL: tb_tick_gen - %0d error(s)", errors);
        $finish;
    end

    // Safety timeout
    initial begin
        #100000;
        $display("FAIL: tb_tick_gen - timeout");
        $finish;
    end

endmodule
