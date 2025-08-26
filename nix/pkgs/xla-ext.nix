{
  pkgs,
  stdenv,
  lib,
  bazelisk,
  apple-sdk_15,
  darwinMinVersionHook,
  ...
}:
with pkgs; let
  extSrc = ../../libs/noxla/extension/.;
in
  stdenv.mkDerivation {
    name = "xla-ext";

    src = fetchzip {
      url = "https://github.com/openxla/xla/archive/2a6015f068e4285a69ca9a535af63173ba92995b.tar.gz";
      sha256 = "sey2yXF3tofTgmS1wXJZS6HwngzBYzktl/QRbMZfrYE=";
    };

    outputs = ["out"];

    buildInputs = [
      bazelisk
      python3
      apple-sdk_15
      (darwinMinVersionHook "15.0")
    ];

    nativeBuildInputs = [
      apple-sdk_15
      (darwinMinVersionHook "15.0")
    ];

    dontConfigure = true;

    unpackPhase = ''
      # The unpacked directory is read-only so we need to
      # set things up in our build directory.
      mkdir xla
      # We only modify the xla sub-directory so symlink the rest.
      ln -s $src/* xla/
      # And don't forget to symlink the dot files!
      ln -s $src/.??* xla/
      # We need a fresh directory to symlink our extension into
      # since the linked xla directory will be read-only.
      rm xla/xla
      mkdir xla/xla
      # Symlink the contents of the xla sub-directory
      ln -s $src/xla/* xla/xla
      # And add ourselves
      ln -s ${extSrc} xla/xla/extension
    '';

    buildPhase = ''
      export HOME=$TMP
      export SDKROOT=${apple-sdk_15}
      echo "Using Apple SDK $SDKROOT"
      cd xla
      echo "Output base: `bazelisk info output_base`"
      bazelisk build \
        --enable_workspace \
        --experimental_cc_static_library \
        --xcode_version=15.0 \
        --macos_sdk_version=15.0 \
        xla/extension:tarball
    '';

    # let tarball = xla_dir.join("bazel-bin/xla/extension/xla_extension.tar.gz");
    # This phase executes any tests provided by the package to verify its functionality.
    checkPhase = ''
    '';

    # The built artifacts are copied to the output directory ($out) in this phase,
    # organizing the package's file structure.
    installPhase = ''
      runHook preInstall
      zig build -Doptimize=ReleaseFast -Demit-man-pages --prefix $out install
      runHook postInstall
    '';

    # This phase performs post-installation adjustments, such as stripping binaries,
    # adjusting library paths, and handling other Nix-specific requirements
    # for the final package.
    fixupPhase = ''
    '';

    # This phase performs integration tests on the final output to ensure the package
    # functions correctly within the Nix environment.
    installCheckPhase = ''
    '';

    # This phase, though rarely used, is for creating distribution archives
    # of the built package.
    distPhase = ''
    '';
  }
