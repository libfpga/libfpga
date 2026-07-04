#!/bin/sh
# libfpga verification driver: sim | lint | synth | all
# Every RTL module must pass all three. Exits non-zero on any failure.
set -u
cd "$(dirname "$0")/.."
mkdir -p build
fails=0

sim() {
    for tb in tb/*/tb_*.v; do
        name=$(basename "$tb" .v | sed 's/^tb_//')
        dir=$(basename "$(dirname "$tb")")
        rtl="rtl/$dir/lfpga_$name.v"
        if ! iverilog -g2012 -Wall -Wno-timescale -o "build/$name.vvp" "$rtl" "$tb"; then
            echo "SIM FAIL (compile): $name"; fails=$((fails+1)); continue
        fi
        (cd build && vvp -n "$name.vvp") > "build/$name.log" 2>&1
        if grep -q "TB PASS" "build/$name.log"; then
            echo "SIM PASS: $name"
        else
            echo "SIM FAIL: $name"; cat "build/$name.log"; fails=$((fails+1))
        fi
    done
}

lint() {
    for rtl in rtl/*/*.v; do
        if verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-MULTITOP "$rtl" > "build/lint.log" 2>&1; then
            echo "LINT PASS: $(basename "$rtl")"
        else
            echo "LINT FAIL: $(basename "$rtl")"; cat build/lint.log; fails=$((fails+1))
        fi
    done
}

synth() {
    for rtl in rtl/*/*.v; do
        name=$(basename "$rtl" .v)
        if yosys -q -p "read_verilog $rtl; synth -lut 4 -flatten; tee -o build/$name.stat.json stat -json" \
             > "build/$name.synth.log" 2>&1; then
            luts=$(python3 -c "
import json
d = json.load(open('build/$name.stat.json'))
cells = {}
for m in d.get('modules', {}).values():
    for t, n in m.get('num_cells_by_type', {}).items():
        cells[t] = cells.get(t, 0) + n
luts = cells.get('\$lut', 0)
ffs = sum(n for t, n in cells.items() if t.startswith('\$') and 'dff' in t.lower())
print(f'{luts} LUT4, {ffs} FF')")
            echo "SYNTH PASS: $name ($luts)"
        else
            echo "SYNTH FAIL: $name"; cat "build/$name.synth.log"; fails=$((fails+1))
        fi
    done
}

case "${1:-all}" in
    sim)   sim ;;
    lint)  lint ;;
    synth) synth ;;
    all)   lint; sim; synth ;;
    *) echo "usage: verify.sh [sim|lint|synth|all]"; exit 2 ;;
esac

[ "$fails" -eq 0 ] && echo "VERIFY OK" || echo "VERIFY FAILED ($fails)"
exit "$fails"
