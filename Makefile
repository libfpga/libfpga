# libfpga — make test / lint / synth / all (see scripts/verify.sh)
.PHONY: all test lint synth clean
all:   ; @scripts/verify.sh all
test:  ; @scripts/verify.sh sim
lint:  ; @scripts/verify.sh lint
synth: ; @scripts/verify.sh synth
clean: ; rm -rf build
