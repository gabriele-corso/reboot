# Aggiornamenti automatici

## Modello

`stable` è l'unico canale consumato dai nodi. GitHub Actions è l'unico writer.

Il nodo confronta lo SHA locale salvato in
`/var/lib/reboot-auto-update/seen-rev` con ilrefs/heads/stable remoto.
Se sono diversi, esegue il rebuild pinnando lo SHA remoto.

## Attivazione su un nodo

Esempio desktop, senza reboot automatico:

```nix
{
  imports = [ ./modules/auto-update.nix ];

  services.rebootAutoUpdate = {
    enable = true;
    host = "t14s";
    checkInterval = "hourly";
    reboot.mode = "manual";
  };
}
```

Esempio server gestito:

```nix
{
  imports = [ ./modules/auto-update.nix ];

  services.rebootAutoUpdate = {
    enable = true;
    host = "server01";
    checkInterval = "03:00";
    randomizedDelaySec = "10m";
    reboot = {
      mode = "managed";
      window.lower = "03:00";
      window.upper = "04:00";
      healthCheck = {
        enable = true;
        units = [ "sshd.service" ];
      };
    };
  };
}
```

## Comandi utili

```bash
systemctl list-timers 'reboot-auto-update*'
systemctl status reboot-auto-update.service
journalctl -u reboot-auto-update.service -f

cat /var/lib/reboot-auto-update/seen-rev
```

Per forzare un nuovo tentativo dopo un rollback:

```bash
sudo rm /var/lib/reboot-auto-update/seen-rev
sudo systemctl start reboot-auto-update.service
```

## Rollback

NixOS mantiene le generazioni. In modalità `managed`, boot counting e
healthcheck riducono il rischio di restare su una generazione difettosa.
Per tornare indietro manualmente:

```bash
sudo nixos-rebuild --rollback
```
