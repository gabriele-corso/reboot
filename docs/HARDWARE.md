# Compatibilità hardware

"Funziona su qualunque computer" non è realistico: UEFI, BIOS, schede di rete e
firmware proprietari cambiano molto. Questa pagina tiene traccia di ciò che è
verificato.

## ISO

- BIOS: Syslinux, abilitato su x86.
- UEFI: GRUB EFI con `makeEfiBootable = true`.
- USB: isohybrid con `makeUsbBootable = true`.
- Laboratorio: QEMU con OVMF `/usr/share/OVMF/OVMF_CODE.fd`.

## Firmware

L'ISO abilita `hardware.enableRedistributableFirmware` e
`nixpkgs.config.allowUnfree = true`. Copre il firmware WiFi redistribuibile più
comune, incluso MediaTek mt7xxx usato su ThinkPad T14s Gen 2a.

Firmware non redistribuibili richiedono la variante specifica della macchina;
non sono inclusi nell'ISO generica.

## Matrice

| Dispositivo | Stato | Note |
|---|---|---|
| ThinkPad T14s Gen 2a, Ryzen 7 PRO 5850U | da verificare | WiFi mt7xxx, Radeon Vega |
| QEMU x86_64 BIOS | da verificare | test con `-bios` |
| QEMU x86_64 UEFI | da verificare | test con OVMF |
| ARM64 | non coperto dalla ISO attuale | servono `nixosConfigurations` aggiuntive |

## Test QEMU

```bash
qemu-system-x86_64 -m 4096 -smp 4 \
  -cdrom result/iso/reboot-*.iso
```

UEFI:

```bash
cp /usr/share/OVMF/OVMF_VARS.fd /tmp/opencode/OVMF_VARS-reboot.fd
qemu-system-x86_64 -m 4096 -smp 4 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=/tmp/opencode/OVMF_VARS-reboot.fd \
  -cdrom result/iso/reboot-*.iso
```
