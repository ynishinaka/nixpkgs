{
  buildGoModule,
  doCheck ? !stdenv.hostPlatform.isDarwin, # Can't start localhost test server in MacOS sandbox.
  fetchFromGitHub,
  installShellFiles,
  lib,
  stdenv,
}:
let
  version = "25.1.9";
  src = fetchFromGitHub {
    owner = "redpanda-data";
    repo = "redpanda";
    rev = "v${version}";
    sha256 = "sha256-X7pBbR2XCyHB4V0Z/PjZ10o/heXswyhzVj1yp+jvUEM=";
  };
in
buildGoModule rec {
  pname = "redpanda-rpk";
  inherit doCheck src version;
  modRoot = "./src/go/rpk";
  runVend = false;
  vendorHash = "sha256-I/jUlOYUXOSmAD2r8lBlnEBYlxf+V6gSICgnMXosP+4=";

  ldflags = [
    ''-X "github.com/redpanda-data/redpanda/src/go/rpk/pkg/cli/cmd/version.version=${version}"''
    ''-X "github.com/redpanda-data/redpanda/src/go/rpk/pkg/cli/cmd/version.rev=v${version}"''
    ''-X "github.com/redpanda-data/redpanda/src/go/rpk/pkg/cli/cmd/container/common.tag=v${version}"''
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    for shell in bash fish zsh; do
      $out/bin/rpk generate shell-completion $shell > rpk.$shell
      installShellCompletion rpk.$shell
    done
  '';

  meta = with lib; {
    description = "Redpanda client";
    homepage = "https://redpanda.com/";
    license = licenses.bsl11;
    maintainers = with maintainers; [
      avakhrenev
      happysalada
    ];
    platforms = platforms.all;
    mainProgram = "rpk";
  };
}
