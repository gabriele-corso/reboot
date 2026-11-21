# reboot

NixOS self-updating, con kernel Linux compilato dal sorgente tramite nixpkgs.

Il progetto produce un'ISO ibrida BIOS/UEFI/USB e mantiene i nodi aggiornati
leggendo solo il branch `stable` di questo repository. GitHub Actions è l'unico
writer di `flake.lock`; i nodi non scrivono mai il lockfile locale.

## Stato

- Base: `nixpkgs/nixos-unstable`
- Kernel predefinito: `linuxPackages_latest`, attualmente Linux 7.3.5, compilato dal sorgente
- Via di fuga kernel: `reboot.kernel.series = "6_18"`
- Aggiornamento lockfile: ogni 6 ore via GitHub Actions
- Desktop installato: Cinnamon + LightDM
- Agenti e tool dev già dentro: vedi [docs/AGENTS.md](docs/AGENTS.md)
- Architettura ISO supportata: `x86_64-linux`
- Canale di update: `github:gabriele-corso/reboot/stable`

## Build dell'ISO

```bash
nix build .#nixosConfigurations.reboot-iso.config.system.build.isoImage
# oppure
nix build .#iso
```

L'ISO viene generata in `result/iso/`.

Per copiarla nella destinazione di lavoro:

```bash
mkdir -p ~/distro-env/images
cp result/iso/*.iso ~/distro-env/images/
```

## Aggiornamenti

Il flusso è:

1. push su `main`;
2. `.github/workflows/stable.yml` esegue `nix flake update`;
3. il lock aggiornato viene committato sul branch `stable`;
4. i nodi rilevano la nuova revisione e applicano
   `nixos-rebuild switch --flake github:gabriele-corso/reboot/<sha>#<host>`.

Se il nodo è offline, il timer systemd riprova all'avvio e il dispatcher
NetworkManager scatena un controllo appena la rete torna up.

Vedi [docs/UPDATE.md](docs/UPDATE.md).

## Reboot

La policy predefinita è `manual`: l'aggiornamento viene applicato con
`switch`, senza riavvio automatico. Per server gestiti è disponibile la modalità
`managed`, con `boot`, finestra di reboot, boot counting e healthcheck.

## Documentazione

- [Architettura](docs/ARCHITECTURE.md)
- [Aggiornamenti](docs/UPDATE.md)
- [Agenti e tool](docs/AGENTS.md)
- [Compatibilità hardware](docs/HARDWARE.md)

## Licenza

MIT. Vedi [LICENSE](LICENSE).
