# Contributing to libfpga

Small library, high bar. Every module PR needs all three, and CI enforces
them:

1. **A self-checking testbench** in `tb/<area>/tb_<name>.v` that prints
   `TB PASS: <name>` only when every check passed (and `TB FAIL: ...`
   otherwise). Eyeball-the-waveform testbenches are not accepted.
2. **Lint clean**: `verilator --lint-only -Wall` with no waivers beyond
   the harness defaults.
3. **Synthesizable**: passes the Yosys smoke test (`make synth`).

Style:

- Plain Verilog-2005, one module per file, file named after the module.
- Module names prefixed `lfpga_`. Parameters SCREAMING_SNAKE, signals
  lower_snake. Active-low signals end `_n`.
- No vendor primitives in `rtl/` — vendor-specific wrappers, if ever
  needed, live in a clearly marked area.
- Every file starts with the standard header (see any existing module)
  and a comment block stating what it is, when to use it, and its
  gotchas. The comment is part of the module.
- Handshakes are valid/ready with AXI-Stream semantics: `valid` must not
  wait for `ready`; payload stable while `valid && !ready`.

Run `make` before pushing — it is exactly what CI runs.
