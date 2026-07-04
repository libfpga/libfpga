# libfpga — make test / lint / synth / all (see scripts/verify.sh)
.PHONY: all test lint synth gen clean
all:   ; @scripts/verify.sh all
gen:   ; @scripts/verify.sh gen
test:  ; @scripts/verify.sh sim
lint:  ; @scripts/verify.sh lint
synth: ; @scripts/verify.sh synth
clean: ; rm -rf build
