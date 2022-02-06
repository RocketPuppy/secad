.PHONY: enter
enter:
	nix develop

.PHONY: clean
clean:
	unlink result-bin

build: result-bin;

result-bin: src Cargo.nix
	nix build

Cargo.nix: Cargo.lock Cargo.toml
	nix develop --command cargo2nix -f

Cargo.lock: Cargo.toml
	nix develop --command cargo generate-lockfile
