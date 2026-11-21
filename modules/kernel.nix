{ config, lib, pkgs, ... }:

let
  cfg = config.reboot.kernel;

  kernelFor = series:
    {
      "6_18" = pkgs.linuxKernel.kernels.linux_6_18;
      "7_3" = pkgs.linuxKernel.kernels.linux_7_3;
    }."${series}";

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
      type = lib.types.enum [ "6_18" "7_3" ];
      default = "6_18";
      description = ''
        Kernel source series built by nixpkgs.

        `6_18` is the maintained LTS line used by default for wider hardware
        compatibility. `7_3` is the newest maintained line shipped by the
        pinned nixpkgs revision.
      '';
    };
  };

  config = {
    boot.kernelPackages = pkgs.linuxPackagesFor kernel;
  };
}
