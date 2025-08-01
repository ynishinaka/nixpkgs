{
  stdenv,
  lib,
  fetchFromGitLab,
  gitUpdater,
  testers,
  # https://gitlab.com/ubports/development/core/biometryd/-/issues/8
  boost186,
  cmake,
  cmake-extras,
  dbus,
  dbus-cpp,
  gtest,
  libapparmor,
  libelf,
  pkg-config,
  process-cpp,
  properties-cpp,
  qtbase,
  qtdeclarative,
  sqlite,
  validatePkgConfig,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "biometryd";
  version = "0.3.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/biometryd";
    rev = finalAttrs.version;
    hash = "sha256-derU7pKdNf6pwhskaW7gCLcU9ixBG3U0EI/qtANmmTs=";
  };

  outputs = [
    "out"
    "dev"
  ];

  postPatch = ''
    # GTest needs C++17
    # Remove when https://gitlab.com/ubports/development/core/biometryd/-/merge_requests/39 merged & in release
    substituteInPlace CMakeLists.txt \
      --replace-fail 'std=c++14' 'std=c++17'

    # Substitute systemd's prefix in pkg-config call
    substituteInPlace data/CMakeLists.txt \
      --replace-fail 'pkg_get_variable(SYSTEMD_SYSTEM_UNIT_DIR systemd systemdsystemunitdir)' 'pkg_get_variable(SYSTEMD_SYSTEM_UNIT_DIR systemd systemdsystemunitdir DEFINE_VARIABLES prefix=''${CMAKE_INSTALL_PREFIX})'

    substituteInPlace src/biometry/qml/Biometryd/CMakeLists.txt \
      --replace-fail "\''${CMAKE_INSTALL_LIBDIR}/qt5/qml" "\''${CMAKE_INSTALL_PREFIX}/${qtbase.qtQmlPrefix}"

    # For our automatic pkg-config output patcher to work, prefix must be used here
    substituteInPlace data/biometryd.pc.in \
      --replace-fail 'libdir=''${exec_prefix}' 'libdir=''${prefix}' \
      --replace-fail 'includedir=''${exec_prefix}' 'includedir=''${prefix}' \
  ''
  + lib.optionalString (!finalAttrs.finalPackage.doCheck) ''
    sed -i -e '/add_subdirectory(tests)/d' CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
    qtdeclarative # qmlplugindump
    validatePkgConfig
  ];

  buildInputs = [
    boost186
    cmake-extras
    dbus
    dbus-cpp
    libapparmor
    libelf
    process-cpp
    properties-cpp
    qtbase
    qtdeclarative
    sqlite
  ];

  checkInputs = [
    gtest
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    # maybe-uninitialized warnings
    (lib.cmakeBool "ENABLE_WERROR" false)
    (lib.cmakeBool "WITH_HYBRIS" false)
  ];

  preBuild = ''
    # Generating plugins.qmltypes (also used in checkPhase?)
    export QT_PLUGIN_PATH=${lib.getBin qtbase}/${qtbase.qtPluginPrefix}
  '';

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
    updateScript = gitUpdater { };
  };

  meta = with lib; {
    description = "Mediates/multiplexes access to biometric devices";
    longDescription = ''
      biometryd mediates and multiplexes access to biometric devices present
      on the system, enabling applications and system components to leverage
      them for identification and verification of users.
    '';
    homepage = "https://gitlab.com/ubports/development/core/biometryd";
    changelog = "https://gitlab.com/ubports/development/core/biometryd/-/${finalAttrs.version}/ChangeLog";
    license = licenses.lgpl3Only;
    teams = [ teams.lomiri ];
    mainProgram = "biometryd";
    platforms = platforms.linux;
    pkgConfigModules = [
      "biometryd"
    ];
  };
})
