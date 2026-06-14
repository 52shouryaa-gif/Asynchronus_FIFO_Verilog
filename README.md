# Async-Fifo-Gray-Verilog

> **Asynchronous FIFO with Gray-Code Pointers** — RTL implementation in Verilog targeting FPGA/ASIC flows. Dual-clock, depth-8, 8-bit wide, with 2-FF synchronizers for CDC-safe full/empty flag generation.

---

## Table of Contents

- [Overview](#overview)
- [Module Hierarchy](#module-hierarchy)
- [Port Interface](#port-interface)
- [Design Parameters](#design-parameters)
- [File Structure](#file-structure)
- [How to Simulate](#how-to-simulate)
- [Simulation Waveform](#simulation-waveform)
- [Key Design Decisions](#key-design-decisions)
- [Known Limitations](#known-limitations)

---

## Overview

This project implements a **dual-clock asynchronous FIFO** — a fundamental building block in any SoC or FPGA design where data must cross between two independent clock domains without metastability. The design follows the industry-standard methodology described in Clifford E. Cummings' *Simulation and Synthesis Techniques for Asynchronous FIFO Design* (SNUG 2002).

**Core features:**
- Depth: 8 entries, Data width: 8 bits
- N+1 bit (4-bit) Gray-code pointers for full/empty disambiguation
- Separate write-domain and read-domain resets
- 2-stage flip-flop synchronizers for clock-domain crossing (CDC)
- Full and empty flags generated combinatorially from synchronized pointer comparisons
- Testbench covers: fill-to-full, drain-to-empty, and concurrent read/write

---

## Module Hierarchy

```
fifo_top
├── wr_hndlr          — Write pointer (binary + Gray), full flag
├── rd_hndlr          — Read pointer (binary + Gray), empty flag
├── fifo_mem          — 8×8 dual-port synchronous SRAM
├── ffsynchro (×2)
│   ├── instance: ffsynchror  — g_rptr → wclk domain → g_rptr_sync
│   └── instance: ffsynchrow  — g_wptr → rclk domain → g_wptr_sync
```

---

## Port Interface

### `fifo_top` (top-level)

| Port       | Dir    | Width | Description                          |
|------------|--------|-------|--------------------------------------|
| `wclk`     | input  | 1     | Write clock                          |
| `wrst_n`   | input  | 1     | Write-domain active-low async reset  |
| `w_en`     | input  | 1     | Write enable                         |
| `data_in`  | input  | 8     | Write data                           |
| `full`     | output | 1     | FIFO full flag (write-domain)        |
| `rclk`     | input  | 1     | Read clock                           |
| `rrst_n`   | input  | 1     | Read-domain active-low async reset   |
| `r_en`     | input  | 1     | Read enable                          |
| `data_out` | output | 8     | Read data                            |
| `empty`    | output | 1     | FIFO empty flag (read-domain)        |

---

## Design Parameters

| Parameter          | Value      | Notes                                       |
|--------------------|------------|---------------------------------------------|
| FIFO Depth         | 8          | `mem[0:7]`, address = `b_ptr[2:0]`          |
| Data Width         | 8 bits     | Parameterizable by editing `fifo_mem`       |
| Pointer Width      | 4 bits     | N+1 = 3+1; MSB used for full/empty wrap     |
| Synchronizer Depth | 2 FFs      | Standard for MTBF in most FPGA/ASIC targets |
| Write Clock (TB)   | 10 ns      | `#5` toggle                                 |
| Read Clock (TB)    | 25 ns      | `#12.5` toggle — 2.5× slower than wclk     |

---

## File Structure

```
async-fifo-gray-verilog/
├── rtl/
│   ├── fifo_top.v        # Top-level structural wrapper
│   ├── wr_hndlr.v        # Write handler: binary/Gray pointer + full flag
│   ├── rd_hndlr.v        # Read handler: binary/Gray pointer + empty flag
│   ├── fifo_mem.v        # Dual-port SRAM (8×8)
│   └── ffsynchro.v       # 2-FF synchronizer (generic, reused ×2)
├── tb/
│   └── tb_async_fifo.v   # Testbench: fill, drain, concurrent R/W
├── sim/
│   └── fifo_wave.vcd     # Dumped waveform (generated on sim run)
├── docs/
│   └── DOCUMENTATION.md  # Full technical documentation
└── README.md
```

---

## How to Simulate

### Icarus Verilog + GTKWave

```bash
# Compile
iverilog -o fifo_sim rtl/fifo_top.v rtl/wr_hndlr.v rtl/rd_hndlr.v \
         rtl/fifo_mem.v rtl/ffsynchro.v tb/tb_async_fifo.v

# Run
vvp fifo_sim

# View waveform
gtkwave fifo_wave.vcd
```

### ModelSim / Questa

```tcl
vlog rtl/fifo_top.v rtl/wr_hndlr.v rtl/rd_hndlr.v rtl/fifo_mem.v rtl/ffsynchro.v tb/tb_async_fifo.v
vsim -novopt tb_fifo_top
add wave -r /*
run -all
```

### Vivado (Simulation Only)

Add all `.v` files to a project, set `tb_async_fifo.v` as the top-level simulation source, and run Behavioral Simulation.

---

## Simulation Waveform

Three phases are exercised by the testbench:

| Phase              | Description                                              |
|--------------------|----------------------------------------------------------|
| **Fill**           | Write until `full=1`. wclk@10ns, random `data_in`       |
| **Drain**          | Read until `empty=1`. rclk@25ns                         |
| **Concurrent R/W** | Both enabled simultaneously for 15 wclk cycles          |

Signals verified in waveform:
- Gray-code pointers (`g_wptr`, `g_rptr`) incrementing correctly
- Synchronized pointers (`g_wptr_sync`, `g_rptr_sync`) lagging by 2 cycles
- `full` asserted when `g_wptr_next == {~g_rptr_sync[3:2], g_rptr_sync[1:0]}`
- `empty` asserted when `g_wptr_sync == g_rptr_next`
- `data_out` correctly tracking written data with read latency

---

## Key Design Decisions

**1. Gray-code pointers for CDC**
Binary pointer crossing between clock domains risks multi-bit transitions sampling in different cycles, causing invalid addresses. Gray code ensures only 1 bit changes per increment — safe to synchronize with 2 FFs.

**2. N+1 pointer bits**
With N=3 (depth 8), using only 3-bit pointers makes `rptr == wptr` ambiguous between full and empty. The extra MSB differentiates: pointers equal (all 4 bits) → empty; MSBs opposite, lower bits equal → full.

**3. Full detection uses inverted MSBs**
```verilog
wfull = (g_wptr_next == {~g_rptr_sync[3:2], g_rptr_sync[1:0]});
```
In Gray space, the condition for full is that the write pointer has wrapped around and "caught up" to the read pointer from the other side. Inverting the top 2 bits of the synchronized read Gray pointer captures this correctly.

**4. Empty detection is a simple equality**
```verilog
rempty = (g_wptr_sync == g_rptr_next);
```
No bit inversion needed — empty is when both pointers are at the same position in the same wrap.

**5. Asynchronous reset, synchronous data path**
Both `wr_hndlr` and `rd_hndlr` use `negedge rst_n` in sensitivity list (async assert), with data clocked on `posedge clk` (sync deassert after reset).

---

## Known Limitations

- `fifo_mem` depth and width are not parameterized (hardcoded `reg [7:0] mem[0:7]`)
- `data_out` is asynchronous (combinatorial read from `b_rptr`) — no output register
- No `wrst_n` passed to `fifo_mem`; memory contents are not cleared on reset
- Synchronizer depth fixed at 2 — may need 3 FFs for very high-frequency designs
- No SVA assertions or formal property checking (planned for future iteration)

---
