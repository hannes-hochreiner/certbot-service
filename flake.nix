{
  description = "A flake to run certbot as a service with a temporary opening of the challenge port.";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-24.05;
  };

  outputs = { self, nixpkgs, ... }: let 
    system = "x86_64-linux";
  in {
    defaultPackage.x86_64-linux =
      with import nixpkgs {
        inherit system;
      };
      stdenv.mkDerivation {
        name = "certbot-service-1.0.0";
        src = ./.;

        # Required at run time
        buildInputs = [
          certbot
          nginx
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
        environment.systemPackages = with pkgs; [
          certbot
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
