{
  description = "reboot — NixOS self-updating OS built from the Linux kernel source";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      lib = nixpkgs.lib;

      mkPkgs = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.problems.handlers.zfs.broken = "warn";
      };

      forEachSystem = f:
        lib.listToAttrs (map (system: {
          name = system;
          value = f system;
        }) systems);
    in
    {
      nixosConfigurations.reboot-iso = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self nixpkgs; };

        modules = [
          ./modules/kernel.nix
          ./modules/auto-update.nix
          ./hosts/reboot-iso.nix
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.config.problems.handlers.zfs.broken = "warn";
            networking.hostName = "reboot";
            boot.zfs.forceImportRoot = false;
            system.stateVersion = "26.05";
          }
        ];
      };

      nixosConfigurations.reboot-node = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/auto-update.nix
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.config.problems.handlers.zfs.broken = "warn";
            networking.hostName = "reboot-node";
            boot.zfs.forceImportRoot = false;
            boot.loader.grub.devices = [ "/dev/sda" ];
            fileSystems."/" = {
              device = "/dev/sda1";
              fsType = "ext4";
            };
            services.rebootAutoUpdate = {
              enable = true;
              host = "reboot-node";
            };
            system.stateVersion = "26.05";
          }
        ];
      };

      nixosConfigurations.reboot-desktop = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/kernel.nix
          ./modules/auto-update.nix
          ./modules/agents.nix
          ./hosts/reboot-desktop.nix
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.config.problems.handlers.zfs.broken = "warn";
            networking.hostName = "reboot-desktop";
            boot.zfs.forceImportRoot = false;
            system.stateVersion = "26.05";
          }
        ];
      };

      packages.x86_64-linux.iso =
        self.nixosConfigurations.reboot-iso.config.system.build.isoImage;

      devShells = forEachSystem (system: {
        default = (mkPkgs system).mkShell {
          packages = with (mkPkgs system); [
            git
            nixfmt
          ];
        };
      });

      formatter = forEachSystem (system: (mkPkgs system).nixfmt);
    };
}
