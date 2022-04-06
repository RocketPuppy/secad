.PHONY: enter
enter:
	nix develop

.PHONY: clean
clean:
	unlink result-bin
	unlink win-result-bin

build: result-bin win-result-bin;

result-bin: src Cargo.nix
	nix build

win-result-bin: src Cargo.nix
	nix build --out-link win-result '.#packages.x86_64-linux."secad.exe"'

Cargo.nix: Cargo.lock Cargo.toml
	nix develop --command cargo2nix -f

Cargo.lock: Cargo.toml
	nix develop --command cargo generate-lockfile
