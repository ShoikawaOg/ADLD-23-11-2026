# 24-Hour Digital Clock — ASIC RTL Design (HH:MM:SS)

Verilog-2001 RTL and self-checking testbenches for a 24-hour digital clock, built to the team
**RTL Interface Agreement** given by *Prof. Ajaykumar Devarapalli*
(Dept. of Electronics & Communication Engineering, BMS College of Engineering, Bengaluru).

- Hours `00–23`, minutes `00–59`, seconds `00–59`
- One system clock, one **active-low asynchronous reset** (`rst_n`)
- Counter carries are **one-cycle enable pulses** — no generated/divided clocks
- Output: six 4-bit **BCD digits** (`HH : MM : SS`)

## Architecture

The design follows the classic cascaded-counter clock (one counter per field, each enabled by the
carry of the previous one), adapted to 24 hours and to a single synchronous clock.

```
            clk, rst_n (shared by every block)
                 |
          +------------+  tick_1s   +-----------------+  min_tick   +-----------------+  hour_tick
          |  tick_gen  |----------->| seconds_counter |------------>| minutes_counter |-----------+
          +------------+  (1 s)     +-----------------+  (60 s)     +-----------------+  (60 min) |
                                           | sec_count                 | min_count                v
                                           |                           |                 +----------------+
                                           |                           |                 | hours_counter  |
                                           |                           |                 +----------------+
                                           |                           |                          | hour_count
                                           v                           v                          v
                                    +--------------------------------------------------------------+
                                    |                        display_ctrl                          |
                                    +--------------------------------------------------------------+
                                       | hour_tens/ones   | min_tens/ones   | sec_tens/ones
                                       v                  v                 v
                                     HH (BCD)     :     MM (BCD)    :     SS (BCD)
```

## Repository layout

```
.
├── README.md
├── run_all.sh                      # compile + run every testbench (Icarus Verilog)
├── .gitignore
├── module_1_tick_gen/              # Member 1
│   ├── tick_gen.v
│   └── tb_tick_gen.v
├── module_2_seconds_counter/       # Member 2
│   ├── seconds_counter.v
│   └── tb_seconds_counter.v
├── module_3_minutes_counter/       # Member 3
│   ├── minutes_counter.v
│   └── tb_minutes_counter.v
├── module_4_hours_counter/         # Member 4
│   ├── hours_counter.v
│   └── tb_hours_counter.v
└── module_5_display_top/           # Member 5
    ├── display_ctrl.v
    ├── digital_clock_top.v
    └── tb_digital_clock_top.v      # full-day system test
```

## Modules and interfaces (frozen)

| Module | File | Ports (in → out) | Function |
|---|---|---|---|
| `tick_gen` | `tick_gen.v` | `clk, rst_n` → `tick_1s` | Divides `CLK_FREQ_HZ` down to a 1-cycle pulse per second |
| `seconds_counter` | `seconds_counter.v` | `clk, rst_n, tick_1s` → `sec_count[5:0], min_tick` | Counts 0–59, carry on 59→00 |
| `minutes_counter` | `minutes_counter.v` | `clk, rst_n, min_tick` → `min_count[5:0], hour_tick` | Counts 0–59, carry on 59→00 |
| `hours_counter` | `hours_counter.v` | `clk, rst_n, hour_tick` → `hour_count[4:0]` | Counts 0–23, wraps 23→00 |
| `display_ctrl` | `display_ctrl.v` | `hour_count, min_count, sec_count` → six 4-bit BCD digits | Binary → BCD (combinational) |
| `digital_clock_top` | `digital_clock_top.v` | `clk, rst_n` → six 4-bit BCD digits | Integrates all of the above |

Parameter: `CLK_FREQ_HZ` (default `50000000`) on `tick_gen` and `digital_clock_top`.
Per the interface-freeze rule, **no port name, width or module name may be changed without team approval.**

## Design notes

- **Reset:** `always @(posedge clk or negedge rst_n)` — asynchronous, active low. Resets to `00:00:00`.
- **Enable-based cascade:** `tick_1s → min_tick → hour_tick`. Every counter updates on the same clock;
  a counter only changes when its enable is high (the same idea as the `EN` inputs in the textbook diagram).
- **Carry pulses (`min_tick`, `hour_tick`)** are decoded from the current count and the incoming enable
  (e.g. `min_tick = tick_1s && sec_count == 59`). They are exactly one clock cycle wide, and the next
  counter updates on the *same* edge as the rollover, so `23:59:59 → 00:00:00` happens in a single clock
  edge and the display never shows a transient wrong time.
- **`tick_gen`** counts `0 … CLK_FREQ_HZ-1`; the registered `tick_1s` is high for one cycle per period.
- **Differences from the 12-hour textbook diagram:** 24-hour hours counter (`0–23`, 5 bits) instead of the
  1–12 FF + divide-by-10; 1 Hz comes from dividing a fast system clock instead of 60 Hz mains;
  output stops at BCD (BCD → 7-segment decoding is not part of this design).

## Simulation

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/) (and optionally GTKWave).

```bash
# Run everything
chmod +x run_all.sh
./run_all.sh

# Or one module at a time, e.g. module 2
cd module_2_seconds_counter
iverilog -g2001 -o sim seconds_counter.v tb_seconds_counter.v
vvp sim                 # add  +dump  to write a .vcd waveform
gtkwave tb_seconds_counter.vcd

# System test (needs all five RTL files)
cd module_5_display_top
iverilog -g2001 -o sim ../module_1_tick_gen/tick_gen.v ../module_2_seconds_counter/seconds_counter.v \
    ../module_3_minutes_counter/minutes_counter.v ../module_4_hours_counter/hours_counter.v \
    display_ctrl.v digital_clock_top.v tb_digital_clock_top.v
vvp sim
```

Each testbench is self-checking and ends with `PASS: ...` or `FAIL: ...`.
In simulation `CLK_FREQ_HZ` is overridden with a tiny value (5 in `tb_tick_gen`, 2 in the top-level test)
so that "one second" is only a few clock cycles.

### Verification checklist (from the interface agreement)

| Check | Covered by |
|---|---|
| Reset initialises to `00:00:00` | every testbench |
| Seconds increment only on `tick_1s` | `tb_seconds_counter` |
| `00:00:59 → 00:01:00` | `tb_seconds_counter`, `tb_digital_clock_top` |
| `00:59:59 → 01:00:00` | `tb_minutes_counter`, `tb_digital_clock_top` |
| `23:59:59 → 00:00:00` | `tb_hours_counter`, `tb_digital_clock_top` |
| Hours ≤ 23, minutes/seconds ≤ 59 | counter testbenches |
| BCD conversion correct | `tb_digital_clock_top` (every second of a full day) |
| `min_tick` / `hour_tick` one cycle wide | `tb_seconds_counter`, `tb_minutes_counter` |

## ASIC implementation (next steps)

This repo is the RTL and verification stage only. The full flow additionally needs a PDK / standard-cell
library, SDC timing constraints, and a typical open-source flow: **Yosys** (synthesis) →
**OpenSTA** (timing) → **OpenROAD / OpenLane** (floorplan, placement, CTS, routing) →
**Magic / KLayout** (layout, DRC/LVS). Document the PDK and tool versions used.

## Team

| Member | Module(s) |
|---|---|
| 1 | `tick_gen` |
| 2 | `seconds_counter` |
| 3 | `minutes_counter` |
| 4 | `hours_counter` |
| 5 | `display_ctrl`, `digital_clock_top` (integration) |

Faculty guide: Prof. Ajaykumar Devarapalli, Assistant Professor, Dept. of ECE, BMS College of Engineering, Bengaluru.

*Prepared for academic use — Digital System Design / ASIC Design project.*
