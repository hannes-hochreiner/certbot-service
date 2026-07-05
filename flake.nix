{
  description = "A flake to run certbot as a service with a temporary opening of the DNS challenge port.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    acme-dns-client = {
      url = "github:hannes-hochreiner/acme-dns-client";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, acme-dns-client, ... }: let
    system = "x86_64-linux";
  in {
    defaultPackage.x86_64-linux =
      with import nixpkgs {
        inherit system;
      };
      stdenv.mkDerivation {
        name = "certbot-service-2.0.0";
        src = ./.;

        buildInputs = [
          certbot
          nushell
        ];

        installPhase = ''
          mkdir -p $out/bin
          mv certbot-wrapper.nu $out/bin
          chmod +x $out/bin/certbot-wrapper.nu
        '';
      };
    nixosModules.default = { config, lib, nixpkgs, ... } :
    with lib;
    let
      cfg = config.hochreiner.services.certbot;
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      options.hochreiner.services.certbot = {
        enable = mkEnableOption "Enables the certbot service";
      };

      config = mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.certbot
          acme-dns-client.packages.${system}.default
        ];
        systemd.services."hochreiner.certbot" = {
          description = "certbot service";
          startAt = "weekly";
          serviceConfig = let pkg = self.defaultPackage.x86_64-linux; in {
            Type = "oneshot";
            ExecStart = "${pkg}/bin/certbot-wrapper.nu";
          };
        };
      };
    };
  };
}