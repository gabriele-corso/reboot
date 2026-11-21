{ config, lib, pkgs, ... }:

let
  cfg = config.reboot.kernel;

  kernelFor = series:
    if series == "latest" then
      pkgs.linuxPackages_latest.kernel
    else
      pkgs.linuxKernel.kernels.linux_6_18;

  kernel = (kernelFor cfg.series).override {
    structuredExtraConfig = {
      BPF_SYSCALL = lib.kernel.yes;
      CGROUP_BPF = lib.kernel.yes;
      WIREGUARD = lib.kernel.module;
      OVERLAY_FS = lib.kernel.module;
      SQUASHFS = lib.kernel.module;
      IKCONFIG = lib.kernel.yes;
      IKCONFIG_PROC = lib.kernel.yes;
    };
  };
in
{
  options.reboot.kernel = {
    series = lib.mkOption {
      type = lib.types.enum [ "latest" "6_18" ];
      default = "latest";
      description = ''
        `latest` segue il kernel più nuovo presente nel nixpkgs pinnato.
        La CI aggiorna il lockfile ogni 6 ore, quindi il kernel si aggiorna
        senza toccare questo file.

        `6_18` è l'unica via di fuga, da usare solo se il kernel nuovo
        dovesse dare problemi su qualche macchina.
      '';
    };
  };

  config = {
    boot.kernelPackages = pkgs.linuxPackagesFor kernel;
  };
}
