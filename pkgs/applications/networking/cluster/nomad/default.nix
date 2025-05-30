{
  lib,
  buildGoModule,
  buildGo124Module,
  fetchFromGitHub,
  nixosTests,
  installShellFiles,
}:

let
  generic =
    {
      buildGoModule,
      version,
      sha256,
      vendorHash,
      license,
      ...
    }@attrs:
    let
      attrs' = builtins.removeAttrs attrs [
        "buildGoModule"
        "version"
        "sha256"
        "vendorHash"
        "license"
      ];
    in
    buildGoModule (
      rec {
        pname = "nomad";
        inherit version vendorHash;

        subPackages = [ "." ];

        src = fetchFromGitHub {
          owner = "hashicorp";
          repo = pname;
          rev = "v${version}";
          inherit sha256;
        };

        nativeBuildInputs = [ installShellFiles ];

        ldflags = [
          "-X github.com/hashicorp/nomad/version.Version=${version}"
          "-X github.com/hashicorp/nomad/version.VersionPrerelease="
          "-X github.com/hashicorp/nomad/version.BuildDate=1970-01-01T00:00:00Z"
        ];

        # ui:
        #  Nomad release commits include the compiled version of the UI, but the file
        #  is only included if we build with the ui tag.
        tags = [ "ui" ];

        postInstall = ''
          echo "complete -C $out/bin/nomad nomad" > nomad.bash
          installShellCompletion nomad.bash
        '';

        meta = with lib; {
          homepage = "https://www.nomadproject.io/";
          description = "Distributed, Highly Available, Datacenter-Aware Scheduler";
          mainProgram = "nomad";
          inherit license;
          maintainers = with maintainers; [
            rushmorem
            pradeepchhetri
            techknowlogick
            cottand
          ];
        };
      }
      // attrs'
    );
in
rec {
  # Nomad never updates major go versions within a release series and is unsupported
  # on Go versions that it did not ship with. Due to historic bugs when compiled
  # with different versions we pin Go for all versions.
  # Upstream partially documents used Go versions here
  # https://github.com/hashicorp/nomad/blob/master/contributing/golang.md

  nomad = nomad_1_9;

  nomad_1_9 = generic {
    buildGoModule = buildGo124Module;
    version = "1.9.7";
    sha256 = "sha256-U02H6DPr1friQ9EwqD/wQnE2Fm20OE5xNccPDJfnsqI=";
    vendorHash = "sha256-9GnwqkexJAxrhW9yJFaDTdSaZ+p+/dcMuhlusp4cmyw=";
    license = lib.licenses.bsl11;
    passthru.tests.nomad = nixosTests.nomad;
    preCheck = ''
      export PATH="$PATH:$NIX_BUILD_TOP/go/bin"
    '';
  };
}
