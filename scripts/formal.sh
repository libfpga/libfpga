#!/bin/sh
# Formal verification: bounded model checking of the property wrappers in
# formal/. Each fv_<mod>.v pairs with its RTL; we prove the assertions
# hold for DEPTH steps from a clean reset. Requires yosys + yosys-smtbmc + z3.
set -u
cd "$(dirname "$0")/.."
mkdir -p build/formal
DEPTH=${DEPTH:-12}
fails=0

# fv file -> RTL sources it needs
check() {
    name="$1"; shift
    top="fv_$name"
    if ! yosys -q -p "read_verilog -formal formal/$top.v $*; \
            prep -top $top; write_smt2 build/formal/$name.smt2" \
            > "build/formal/$name.ys.log" 2>&1; then
        echo "FORMAL BUILD FAIL: $name"; cat "build/formal/$name.ys.log"
        fails=$((fails+1)); return
    fi
    if yosys-smtbmc -s z3 -i -t "$DEPTH" "build/formal/$name.smt2" \
            > "build/formal/$name.log" 2>&1 && \
       grep -q "Status: PASSED" "build/formal/$name.log"; then
        echo "FORMAL PROVEN: $name (induction)"
    else
        echo "FORMAL FAIL: $name"; tail -20 "build/formal/$name.log"
        fails=$((fails+1))
    fi
}

check fix_add          rtl/fix/lfpga_fix_add.v
check arbiter_rr       rtl/stream/lfpga_arbiter_rr.v
check priority_encoder rtl/util/lfpga_priority_encoder.v
check fifo_sync        rtl/fifo/lfpga_fifo_sync.v
check skid_buffer      rtl/stream/lfpga_skid_buffer.v

[ "$fails" -eq 0 ] && echo "FORMAL OK" || echo "FORMAL FAILED ($fails)"
exit "$fails"
