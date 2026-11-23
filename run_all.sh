#!/usr/bin/env bash
# Compile and run every testbench with Icarus Verilog. Usage: ./run_all.sh
set -e
cd "$(dirname "$0")"

M1=module_1_tick_gen; M2=module_2_seconds_counter; M3=module_3_minutes_counter
M4=module_4_hours_counter; M5=module_5_display_top
OUT=$(mktemp -d)

run() {  # run <name> <files...>
  name=$1; shift
  iverilog -g2001 -Wall -o "$OUT/$name" "$@"
  vvp "$OUT/$name" | grep -E "PASS|FAIL"
}

run tick_gen        $M1/tick_gen.v            $M1/tb_tick_gen.v
run seconds_counter $M2/seconds_counter.v     $M2/tb_seconds_counter.v
run minutes_counter $M3/minutes_counter.v     $M3/tb_minutes_counter.v
run hours_counter   $M4/hours_counter.v       $M4/tb_hours_counter.v
run digital_clock   $M1/tick_gen.v $M2/seconds_counter.v $M3/minutes_counter.v \
                    $M4/hours_counter.v $M5/display_ctrl.v $M5/digital_clock_top.v \
                    $M5/tb_digital_clock_top.v
rm -rf "$OUT"
