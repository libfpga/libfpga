#!/bin/sh
# libfpga verification driver: sim | lint | synth | all
# Every RTL module must pass all three. Exits non-zero on any failure.
set -u
cd "$(dirname "$0")/.."
mkdir -p build
fails=0
YDIRS=""; for d in rtl/*/; do YDIRS="$YDIRS -y $d"; done
ALLRTL=$(find rtl -name "*.v" | sort | tr "\n" " ")

sim() {
    for tb in tb/*/tb_*.v; do
        name=$(basename "$tb" .v | sed 's/^tb_//')
        dir=$(basename "$(dirname "$tb")")
        rtl="rtl/$dir/lfpga_$name.v"
        if ! iverilog -g2012 -Wall -Wno-timescale $YDIRS -o "build/$name.vvp" "$rtl" "$tb"; then
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
        if verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-MULTITOP -Wno-UNUSEDPARAM $YDIRS "$rtl" > "build/lint.log" 2>&1; then
            echo "LINT PASS: $(basename "$rtl")"
        else
            echo "LINT FAIL: $(basename "$rtl")"; cat build/lint.log; fails=$((fails+1))
        fi
    done
}

synth() {
    for rtl in rtl/*/*.v; do
        name=$(basename "$rtl" .v)
        top=$(basename "$rtl" .v)
        # paired-module files (e.g. gray) have no module named after the
        # file: let yosys pick the top in that case.
        if grep -q "module $top\b" "$rtl"; then TOPARG="-top $top"; else TOPARG=""; fi
        if yosys -q -p "read_verilog $ALLRTL; synth -lut 4 -flatten $TOPARG; tee -o build/$name.stat.json stat -json" \
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

gen() {
    # regenerate the MLP example and verify it against its own model
    python3 gen/mlp_gen.py gen/examples/mlp_xor.json build/genout/ > /dev/null
    YD=""; for d in rtl/*/; do YD="$YD -y $d"; done
    if ! verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDPARAM $YD \
         build/genout/mlp_xor.v > build/genlint.log 2>&1; then
        echo "GEN LINT FAIL"; cat build/genlint.log; fails=$((fails+1)); return
    fi
    iverilog -g2012 -Wall -Wno-timescale $YD -o build/genout/gen.vvp \
        build/genout/mlp_xor.v build/genout/tb_mlp_xor.v 2>/dev/null
    (cd build/genout && vvp -n gen.vvp) > build/gen.log 2>&1
    if grep -q "TB PASS" build/gen.log; then echo "GEN PASS: mlp_xor";
    else echo "GEN FAIL: mlp_xor"; cat build/gen.log; fails=$((fails+1)); fi
}

case "${1:-all}" in
    sim)   sim ;;
    gen)   gen ;;
    lint)  lint ;;
    synth) synth ;;
    all)   lint; sim; synth; gen ;;
    *) echo "usage: verify.sh [sim|lint|synth|all]"; exit 2 ;;
esac

[ "$fails" -eq 0 ] && echo "VERIFY OK" || echo "VERIFY FAILED ($fails)"
exit "$fails"
