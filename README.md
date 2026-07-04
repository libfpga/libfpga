# libfpga

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

## Modules

| Module | What it is | Cost* |
|---|---|---|
| [`lfpga_sync_bit`](rtl/cdc/lfpga_sync_bit.v) | N-flop synchronizer for one async level bit | 2 FF |
| [`lfpga_sync_pulse`](rtl/cdc/lfpga_sync_pulse.v) | toggle-based pulse crossing, either direction | 2 LUT4 + 4 FF |
| [`lfpga_reset_sync`](rtl/cdc/lfpga_reset_sync.v) | reset: async assert, sync deassert | 2 FF |

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

## Roadmap

- **v0.1** — CDC set (here), sync/async FIFOs, skid buffer, round-robin
  arbiter, UART, SPI master, parallel CRC, LFSR, Gray codecs, AXI-Lite CSR
  bridge (pairs with the [register-map generator](https://libfpga.com/tools/register-map))
- **v0.2** — the neural micro-kit: INT8 MAC array, activations, weight
  loaders, and a complete quantized MLP inference core with a NumPy
  quantizer ([why FPGAs are shaped like neural networks](https://libfpga.com/blog/fpgas-for-ai))
- **v0.3** — formal properties (SymbiYosys) for the protocol modules,
  FuseSoC packaging, board demo projects

Want a module? [Open an issue](https://github.com/libfpga/libfpga/issues)
or use the [request box](https://libfpga.com/tools/) — the roadmap is
ranked by real requests.

## License

MIT — Copyright (c) 2026 Antonio Roldao, Ph.D. See [LICENSE](LICENSE).
