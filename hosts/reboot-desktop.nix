{ lib, pkgs, ... }:

{
  networking.hostName = "reboot-desktop";
  boot.zfs.forceImportRoot = false;

  # Template installato: adattare i dischi alla macchina reale.
  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/sda" ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  fileSystems."/" = {
    device = "/dev/sda2";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/sda1";
    fsType = "vfat";
  };

  hardware.enableRedistributableFirmware = true;

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.cinnamon.enable = true;
  };

  services.pipewire.enable = true;
  networking.networkmanager.enable = true;

  users.users.nixos = {
    isNormalUser = true;
    description = "reboot user";
    initialPassword = "reboot";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
  };

  services.rebootAutoUpdate = {
    enable = true;
    host = "reboot-desktop";
    reboot.mode = "manual";
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    jq
    nixos-rebuild
  ];

  system.stateVersion = "26.05";
}
