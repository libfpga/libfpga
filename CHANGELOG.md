# Changelog

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
