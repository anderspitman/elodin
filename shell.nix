{pkgs ? import <nixpkgs> {}}:
with pkgs;
  mkShell {
    buildInputs = [
      bazelisk
      python3
      xcbuild
      apple-sdk_15
      (darwinMinVersionHook "15.0")
    ];
  }
