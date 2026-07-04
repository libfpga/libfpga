# libfpga

[![CI](https://github.com/libfpga/libfpga/actions/workflows/ci.yml/badge.svg)](https://github.com/libfpga/libfpga/actions/workflows/ci.yml)

**The FPGA standard library: verified, vendor-neutral building blocks.**

Every module here is small, documented, and held to one quality bar,
enforced in CI on a fully open toolchain:

- a **self-checking testbench** (Icarus Verilog) — behavior proven, not assumed
- **lint-clean** under `verilator --lint-only -Wall`
- a **synthesis smoke test** (Yosys) with LUT/FF resource stats

Plain Verilog-2005, consistent interfaces, no vendor primitives — the same
source synthesizes on Vivado, Quartus, and the open Yosys/nextpnr flow.

Companion site: **[libfpga.com](https://libfpga.com)** — every module gets a
doc page, and the free [Verilog playground](https://libfpga.com/learn/playground)
lets you simulate and modify library code in your browser, no installs.

Follow **[@libfpga](https://x.com/libfpga)** to keep up with new modules,
releases and tools — every release is announced there.

## Modules

**CDC**

| Module | What it is | Cost* |
|---|---|---|
| [`lfpga_sync_bit`](rtl/cdc/lfpga_sync_bit.v) | N-flop synchronizer for one async level bit | 2 FF |
| [`lfpga_sync_pulse`](rtl/cdc/lfpga_sync_pulse.v) | toggle-based pulse crossing, either direction | 2 LUT4 + 4 FF |
| [`lfpga_reset_sync`](rtl/cdc/lfpga_reset_sync.v) | reset: async assert, sync deassert | 2 FF |

**FIFOs & streams**

| Module | What it is | Cost* |
|---|---|---|
| [`lfpga_fifo_sync`](rtl/fifo/lfpga_fifo_sync.v) | synchronous show-ahead FIFO with count | 154 LUT4 + 145 FF |
| [`lfpga_fifo_async`](rtl/fifo/lfpga_fifo_async.v) | dual-clock FIFO, gray pointers (Cummings) | 154 LUT4 + 168 FF |
| [`lfpga_skid_buffer`](rtl/stream/lfpga_skid_buffer.v) | valid/ready register slice, full throughput | 16 LUT4 + 18 FF |
| [`lfpga_arbiter_rr`](rtl/stream/lfpga_arbiter_rr.v) | round-robin arbiter, one-hot grant | 18 LUT4 + 4 FF |

**Serial**

| Module | What it is | Cost* |
|---|---|---|
| [`lfpga_uart_tx`](rtl/serial/lfpga_uart_tx.v) | UART transmitter, 8N1, valid/ready | 48 LUT4 + 24 FF |
| [`lfpga_uart_rx`](rtl/serial/lfpga_uart_rx.v) | UART receiver, mid-bit sampling, glitch reject | 63 LUT4 + 32 FF |
| [`lfpga_spi_master`](rtl/serial/lfpga_spi_master.v) | SPI master, mode 0, full duplex | 32 LUT4 + 27 FF |
| [`lfpga_i2c_master`](rtl/serial/lfpga_i2c_master.v) | I2C master, 7-bit, open-drain, byte commands | 123 LUT4 + 38 FF |

**Math & integrity**

| Module | What it is | Cost* |
|---|---|---|
| [`lfpga_crc`](rtl/math/lfpga_crc.v) | parallel CRC, any polynomial, word per clock | 17 LUT4 + 16 FF |
| [`lfpga_lfsr`](rtl/math/lfpga_lfsr.v) | maximal-length LFSR, widths 2-32 & 64 | 1 LUT4 + 16 FF |
| [`lfpga_gray`](rtl/math/lfpga_gray.v) | binary <-> Gray converters | 3 LUT4 |

**Utilities**

| Module | What it is | Cost* |
|---|---|---|
| [`lfpga_popcount`](rtl/util/lfpga_popcount.v) | count set bits (combinational tree) | 12 LUT4 |
| [`lfpga_priority_encoder`](rtl/util/lfpga_priority_encoder.v) | lowest-set-bit: one-hot + index | 18 LUT4 |
| [`lfpga_onehot_mux`](rtl/util/lfpga_onehot_mux.v) | AND-OR mux for one-hot selects | 24 LUT4 |
| [`lfpga_edge_detect`](rtl/util/lfpga_edge_detect.v) | rise/fall/toggle pulses | 3 LUT4 + 1 FF |
| [`lfpga_debounce`](rtl/util/lfpga_debounce.v) | switch debouncer with press/release events | 44 LUT4 + 25 FF |
| [`lfpga_pwm`](rtl/util/lfpga_pwm.v) | PWM with glitch-free duty updates | 33 LUT4 + 17 FF |
| [`lfpga_clkdiv_frac`](rtl/util/lfpga_clkdiv_frac.v) | fractional-rate clock enable (phase accumulator) | 27 LUT4 + 16 FF |

**Fixed-point & neural (v0.3)**

| Module | What it is | Cost* |
|---|---|---|
| [`lfpga_fix_resize`](rtl/fix/lfpga_fix_resize.v) | requantize: shift + round + saturate | 31 LUT4 |
| [`lfpga_fix_mult`](rtl/fix/lfpga_fix_mult.v) | signed fixed-point multiply, resized | 240 LUT4 |
| [`lfpga_fix_add`](rtl/fix/lfpga_fix_add.v) | fixed-point add/sub, saturating | 48 LUT4 |
| [`lfpga_mac`](rtl/nn/lfpga_mac.v) | signed multiply-accumulate (the NN atom) | 326 LUT4 + 32 FF |
| [`lfpga_relu`](rtl/nn/lfpga_relu.v) | ReLU / leaky / clipped + requantize | 129 LUT4 |
| [`lfpga_barrel_shifter`](rtl/nn/lfpga_barrel_shifter.v) | single-cycle logical/arith shift | 139 LUT4 |
| [`lfpga_bitreverse`](rtl/nn/lfpga_bitreverse.v) | reverse bit order | 0 LUT4 |

**Bus**

| Module | What it is | Cost* |
|---|---|---|
| [`lfpga_axil_bridge`](rtl/bus/lfpga_axil_bridge.v) | AXI4-Lite slave to simple register bus | 5 LUT4 + 80 FF |

*\*generic Yosys `synth -lut 4` mapping at default parameters; vendor
results with 6-input LUTs typically come in at or below these numbers.*

## Usage

Copy the file(s) you need — every module is self-contained — or vendor the
repo. Instantiate:

```verilog
lfpga_reset_sync #(.STAGES(2)) u_rst_sync (
    .clk         (clk),
    .rst_async_n (board_rst_n & pll_locked),
    .rst_sync_n  (rst_n)
);
```

CDC modules ship with `ASYNC_REG` attributes; add the matching timing
exception for your flow (see the notes in each file, and the
[constraint cheatsheets](https://libfpga.com/ref/xdc-constraints)).

## Verify locally

```sh
make          # lint + simulate + synth-check everything
make test     # just the testbenches
```

Requires `iverilog`, `verilator`, `yosys` — all packaged on most distros,
or grab the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build).

### Formal verification

Testbenches prove the design works on the vectors you tried. **Formal**
proves properties hold for *every* input, for all time. The wrappers in
`formal/` state protocol and safety contracts and prove them by temporal
induction (yosys + z3):

```sh
make formal
```

Proven unbounded today:

| Module | Property proven |
|---|---|
| `lfpga_fix_add` | saturating add never wraps sign; exact when no overflow |
| `lfpga_arbiter_rr` | grant is always a one-hot subset of `req` |
| `lfpga_priority_encoder` | grant is the one-hot lowest set bit |
| `lfpga_fifo_sync` | `count ≤ DEPTH`; flags track count; never full ∧ empty |
| `lfpga_skid_buffer` | `valid` never drops before a transfer; payload stable |

CI runs these on every push.

## Roadmap

- **v0.1 — shipped.** Everything above.
- **v0.2 — shipped.** The utilities tier.
- **v0.3 — shipped.** The fixed-point + neural tier above, plus the MLP
  generator.
- **v0.4 — shipped.** I2C master (above).
- **v0.5 — shipped.** Formal verification (see above).
- **v0.6** — FuseSoC packaging, board demo projects, more formal
  coverage.

## The MLP generator

`gen/mlp_gen.py` turns a JSON network spec (trained, Q4.4-quantized
weights) into a pipelined Verilog inference core **and** a self-checking
testbench that proves the RTL matches a bit-exact software model on every
test vector. It's the library-grade generalization of
[fpga-neuron](https://github.com/libfpga/fpga-neuron):

```sh
python3 gen/mlp_gen.py gen/examples/mlp_xor.json out/
# emits out/mlp_xor.v and out/tb_mlp_xor.v; the TB self-checks vs the model
```

The layer primitives (`lfpga_mac`, `lfpga_relu`, `lfpga_fix_resize`) are
the building blocks it composes. See
[why FPGAs are shaped like neural networks](https://libfpga.com/blog/fpgas-for-ai)
and [how many bits you actually need](https://libfpga.com/blog/how-many-bits).

## Related projects

[Wren6991/libfpga](https://github.com/Wren6991/libfpga) — an excellent,
independent library that shares our name and our Verilog-2005 philosophy,
with a different focus (AHB-Lite fabric, caches, SDRAM). The two projects
are unrelated; several of our utility modules were inspired by the
*selection* in its catalog (implementations are our own). If you need
AHB-Lite infrastructure, go there.

Want a module? [Open an issue](https://github.com/libfpga/libfpga/issues)
or use the [request box](https://libfpga.com/tools/) — the roadmap is
ranked by real requests.

## License

MIT — Copyright (c) 2026 Antonio Roldao, Ph.D. See [LICENSE](LICENSE).
