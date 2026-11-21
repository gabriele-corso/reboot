{ lib, pkgs, nixpkgs, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nixpkgs.config.allowUnfree = true;

  hardware.enableRedistributableFirmware = true;

  isoImage.makeBiosBootable = true;
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.volumeID = "REBOOT-ISO";
  isoImage.edition = "reboot";
  isoImage.appendToMenuLabel = " (kernel built from source)";
  isoImage.squashfsCompression = "zstd -Xcompression-level 15";

  system.nixos.distroName = "reboot";
  networking.hostName = "reboot";

  environment.systemPackages = with pkgs; [
    git
    curl
    jq
    nixos-rebuild
  ];
}
