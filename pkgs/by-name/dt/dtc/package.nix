{
  stdenv,
  lib,
  fetchpatch2,
  fetchzip,
  meson,
  ninja,
  flex,
  bison,
  pkg-config,
  which,
  pythonSupport ? false,
  python ? null,
  swig,
  libyaml,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dtc";
  version = "1.7.2";

  src = fetchzip {
    url = "https://git.kernel.org/pub/scm/utils/dtc/dtc.git/snapshot/dtc-v${finalAttrs.version}.tar.gz";
    hash = "sha256-KZCzrvdWd6zfQHppjyp4XzqNCfH2UnuRneu+BNIRVAY=";
  };

  patches = [
    # backport of https://github.com/dgibson/dtc/pull/141
    # to 1.7.2, to drop in 1.8.
    ./static.patch
    # backport fix for SWIG 4.3
    (fetchpatch2 {
      url = "https://github.com/dgibson/dtc/commit/9a969f3b70b07bbf1c9df44a38d7f8d1d3a6e2a5.patch";
      hash = "sha256-YrRzc3ATNmU6LYNHEQeU8wtjt1Ap7/gNFvtRR14PQEE=";
    })
    # glibc-2.41 support
    (fetchpatch2 {
      url = "https://github.com/dgibson/dtc/commit/ce1d8588880aecd7af264e422a16a8b33617cef7.patch";
      hash = "sha256-t1CxKnbCXUArtVcniAIdNvahOGXPbYhPCZiTynGLvfo=";
    })
  ];

  env.SETUPTOOLS_SCM_PRETEND_VERSION = finalAttrs.version;

  nativeBuildInputs = [
    meson
    ninja
    flex
    bison
    pkg-config
    which
  ]
  ++ lib.optionals pythonSupport [
    python
    python.pkgs.setuptools-scm
    swig
  ];

  buildInputs = [ libyaml ];

  postPatch = ''
    patchShebangs setup.py
  '';

  # Required for installation of Python library and is innocuous otherwise.
  env.DESTDIR = "/";

  mesonAutoFeatures = "auto";
  mesonFlags = [
    (lib.mesonBool "tests" finalAttrs.finalPackage.doCheck)
  ];

  doCheck =
    # Checks are broken on aarch64 darwin
    # https://github.com/NixOS/nixpkgs/pull/118700#issuecomment-885892436
    !stdenv.hostPlatform.isDarwin
    &&
      # Checks are broken when building statically on x86_64 linux with musl
      # One of the test tries to build a shared library and this causes the linker:
      # x86_64-unknown-linux-musl-ld: /nix/store/h9gcvnp90mpniyx2v0d0p3s06hkx1v2p-x86_64-unknown-linux-musl-gcc-13.3.0/lib/gcc/x86_64-unknown-linux-musl/13.3.0/crtbeginT.o: relocation R_X86_64_32 against hidden symbol `__TMC_END__' can not be used when making a shared object
      # x86_64-unknown-linux-musl-ld: failed to set dynamic section sizes: bad value
      !stdenv.hostPlatform.isStatic
    &&

      # we must explicitly disable this here so that mesonFlags receives
      # `-Dtests=disabled`; without it meson will attempt to run
      # hostPlatform binaries during the configurePhase.
      (with stdenv; buildPlatform.canExecute hostPlatform);

  meta = with lib; {
    description = "Device Tree Compiler";
    homepage = "https://git.kernel.org/pub/scm/utils/dtc/dtc.git";
    license = licenses.gpl2Plus; # dtc itself is GPLv2, libfdt is dual GPL/BSD
    maintainers = [ maintainers.dezgeg ];
    platforms = platforms.unix;
    mainProgram = "dtc";
  };
})
