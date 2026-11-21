# Architettura

## Componenti

- `flake.nix`: punto d'ingresso, pin di nixpkgs, configurazioni NixOS, dev shell.
- `modules/kernel.nix`: usa `linuxPackages_latest` e applica le opzioni di config extra.
- `modules/auto-update.nix`: timer, servizio e dispatcher per leggere `stable`.
- `modules/agents.nix`: agent CLI e tool dev preinstallati, senza configurazione.
- `hosts/reboot-iso.nix`: configurazione dell'ISO ibrida BIOS/UEFI/USB.
- `hosts/reboot-desktop.nix`: profilo installato con Cinnamon, LightDM e GRUB.
- `.github/workflows/stable.yml`: aggiorna `flake.lock` ogni 6 ore e pubblica `stable`.

## Perché il lock ha un solo writer

Se ogni nodo aggiornasse il proprio `flake.lock`, ogni macchina potrebbe
finire con una revisione diversa. Qui invece:

- Actions aggiorna il lock su `main` e lo pubblica su `stable`;
- i nodi leggono la revisione remota con `git ls-remote`;
- il rebuild usa un flake ref pinnato allo SHA: `github:owner/repo/<sha>#host`;
- `--no-write-lock-file` impedisce scritture locali.

Il risultato è un parco macchine convergente e verificabile.

## Kernel

Il kernel non è un binario preso da una distro: nixpkgs costruisce il pacchetto
dal sorgente. Il default è `pkgs.linuxPackages_latest.kernel`, quindi il kernel
segue il rilascio più nuovo presente nel nixpkgs pinnato. Siccome la CI aggiorna
`flake.lock` ogni 6 ore, il kernel si aggiorna senza modificare i file del repo.

`boot.kernelPackages` usa `pkgs.linuxPackagesFor kernel`, quindi moduli e initrd
vengono costruiti contro lo stesso derivato.

Opzioni di config esplicite:

- `CONFIG_BPF_SYSCALL=y`
- `CONFIG_CGROUP_BPF=y`
- `CONFIG_WIREGUARD=m`
- `CONFIG_OVERLAY_FS=m`
- `CONFIG_SQUASHFS=m`
- `CONFIG_IKCONFIG=y`
- `CONFIG_IKCONFIG_PROC=y`

## Flusso di aggiornamento

```text
push main
  -> Actions: nix flake update
  -> commit flake.lock
  -> push stable
  -> nodi: git ls-remote stable
  -> se SHA diverso: nixos-rebuild switch/boot --no-write-lock-file
```

Il `repository_dispatch` emesso da Actions serve a integrazioni esterne; i nodi
non dipendono da un webhook pubblico.

## Verifica

```bash
nix eval --raw .#nixosConfigurations.reboot-iso.config.boot.kernelPackages.kernel.version
nix flake check --no-build --show-trace
```

Dentro il sistema avviato:

```bash
uname -r
readlink -f /run/current-system/kernel
zcat /proc/config.gz | grep -E '^CONFIG_(IKCONFIG|IKCONFIG_PROC)='
```
