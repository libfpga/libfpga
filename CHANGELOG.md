# Changelog

## v0.4.0 — 2026-07-04

- `lfpga_i2c_master`: single-master 7-bit I2C controller. Byte-level
  START / WRITE / READ / STOP commands, open-drain pin controls, ACK/NACK
  reporting. Verified against a behavioral slave (register write + read
  back) and a bit-level read check. 29 modules total.

## v0.3.0 — 2026-07-04

The fixed-point + neural micro-kit. 7 new modules and a code generator:

- Fixed point: `lfpga_fix_resize` (round + saturate requantize),
  `lfpga_fix_mult`, `lfpga_fix_add`
- Neural: `lfpga_mac` (multiply-accumulate), `lfpga_relu` (ReLU/leaky)
- DSP utilities: `lfpga_barrel_shifter`, `lfpga_bitreverse`
- **`gen/mlp_gen.py`**: JSON spec -> pipelined MLP core + self-checking
  testbench (bit-exact vs a software model). CI regenerates and verifies
  the XOR example on every push.

## v0.2.0 — 2026-07-04

The utilities tier — 7 new modules (catalog inspired by the excellent,
unrelated Wren6991/libfpga; implementations our own):

- `lfpga_popcount`, `lfpga_priority_encoder`, `lfpga_onehot_mux`
- `lfpga_edge_detect`, `lfpga_debounce` (press/release events),
  `lfpga_pwm` (glitch-free duty), `lfpga_clkdiv_frac` (fractional-rate
  enable via phase accumulator)

## v0.1.0 — 2026-07-04

The core library. 11 new modules, all with self-checking testbenches,
Verilator-clean, Yosys-checked:

- FIFOs: `lfpga_fifo_sync` (show-ahead + count),
  `lfpga_fifo_async` (dual-clock, gray-coded pointers)
- Streams: `lfpga_skid_buffer`, `lfpga_arbiter_rr`
- Serial: `lfpga_uart_tx`, `lfpga_uart_rx` (glitch-rejecting),
  `lfpga_spi_master` (mode 0, full duplex)
- Math: `lfpga_crc` (parallel, any polynomial, checked against
  CCITT-FALSE 0x29B1), `lfpga_lfsr` (XAPP052 taps), `lfpga_gray`
- Bus: `lfpga_axil_bridge` (AXI4-Lite to simple register interface)

## v0.0 (scaffolding)

- Initial scaffolding: MIT license, CI (lint + sim + synth on the open
  toolchain), verification harness.
- CDC set: `lfpga_sync_bit`, `lfpga_sync_pulse`, `lfpga_reset_sync`.
