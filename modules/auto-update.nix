{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkMerge
    types
    literalExpression;

  cfg = config.services.rebootAutoUpdate;
  stateFile = "${cfg.stateDir}/seen-rev";
  desiredFile = "${cfg.stateDir}/desired-rev";
  apiBase = "https://api.github.com/repos/${cfg.repo}";

  updateScript = pkgs.writeShellScript "reboot-auto-update" ''
    set -euo pipefail

    repo=${lib.escapeShellArg cfg.repo}
    branch=${lib.escapeShellArg cfg.branch}
    host=${lib.escapeShellArg cfg.host}
    state=${lib.escapeShellArg stateFile}
    desired=${lib.escapeShellArg desiredFile}
    mode=${lib.escapeShellArg cfg.reboot.mode}
    verify=${lib.boolToString cfg.verifySignature}

    mkdir -p "$(dirname "$state")"

    remote="$(git ls-remote --exit-code "https://github.com/$repo.git" \
      "refs/heads/$branch" | awk 'NR == 1 { print $1 }')" || {
      echo "Impossibile leggere $repo/$branch" >&2
      exit 1
    }

    [[ "$remote" =~ ^[0-9a-f]{40}$ ]] || {
      echo "SHA remoto non valido: $remote" >&2
      exit 1
    }

    seen=""
    [[ -r "$state" ]] && seen="$(cat "$state")"
    if [[ "$seen" == "$remote" ]]; then
      echo "stable già applicato: $remote"
      exit 0
    fi

    if [[ "$verify" == "true" ]]; then
      verified="$(curl -fsSL --max-time 20 \
        -H 'Accept: application/vnd.github+json' \
        -H 'X-GitHub-Api-Version: 2022-11-28' \
        "${apiBase}/commits/$remote" | jq -r '.commit.verification.verified')"
      [[ "$verified" == "true" ]] || {
        echo "Commit $remote non verificato da GitHub" >&2
        exit 1
      }
    fi

    flakeRef="github:$repo/$remote#$host"
    echo "Applico $flakeRef"

    if [[ "$mode" == "managed" ]]; then
      nixos-rebuild boot --flake "$flakeRef" --no-write-lock-file
      printf '%s\n' "$remote" > "$desired"
    else
      nixos-rebuild switch --flake "$flakeRef" --no-write-lock-file
      rm -f "$desired"
    fi

    printf '%s\n' "$remote" > "$state"
    echo "Applicato $remote"
  '';

  rebootScript = pkgs.writeShellScript "reboot-auto-update-reboot" ''
    set -euo pipefail

    desired=${lib.escapeShellArg desiredFile}
    [ -f "$desired" ] || exit 0

    ${lib.optionalString (cfg.reboot.window != null) ''
      lower=${lib.escapeShellArg cfg.reboot.window.lower}
      upper=${lib.escapeShellArg cfg.reboot.window.upper}
      now="$(date +%H%M)"
      if [[ "$lower" < "$upper" ]]; then
        [[ "$now" > "$lower" && "$now" < "$upper" ]] || exit 0
      else
        [[ "$now" > "$lower" || "$now" < "$upper" ]] || exit 0
      fi
    ''}

    booted="$(readlink -f /run/current-system)"
    profile="$(readlink -f /nix/var/nix/profiles/system)"
    if [[ "$booted" == "$profile" ]]; then
      rm -f "$desired"
      exit 0
    fi

    echo "Riavvio nella generazione staged: $profile"
    systemctl reboot
  '';

  healthScript = pkgs.writeShellScript "reboot-auto-update-healthcheck" ''
    set -uo pipefail
    failed=0
    for unit in ${lib.concatMapStringsSep " " lib.escapeShellArg cfg.reboot.healthCheck.units}; do
      if ! systemctl is-active --quiet "$unit"; then
        echo "healthcheck fallito: $unit" >&2
        failed=1
      fi
    done
    exit "$failed"
  '';
in
{
  options.services.rebootAutoUpdate = {
    enable = mkEnableOption "aggiornamento NixOS dal branch stable di GitHub";

    host = mkOption {
      type = types.str;
      default = config.networking.hostName;
      defaultText = literalExpression "config.networking.hostName";
      description = "Attributo nixosConfigurations.<host> da costruire.";
    };

    repo = mkOption {
      type = types.strMatching "[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+";
      default = "gabriele-corso/reboot";
      description = "Repository GitHub in formato OWNER/NAME.";
    };

    branch = mkOption {
      type = types.str;
      default = "stable";
      description = "Branch remoto letto dai nodi.";
    };

    stateDir = mkOption {
      type = types.path;
      default = "/var/lib/reboot-auto-update";
      description = "Stato root-only. Il nodo non scrive mai flake.lock.";
    };

    checkInterval = mkOption {
      type = types.str;
      default = "hourly";
      description = "Espressione systemd.time(7) per il timer di controllo.";
    };

    randomizedDelaySec = mkOption {
      type = types.str;
      default = "15m";
      description = "Jitter per evitare che tutti i nodi cellulino insieme.";
    };

    timeoutSec = mkOption {
      type = types.int;
      default = 1800;
      description = "Timeout massimo di un nixos-rebuild.";
    };

    verifySignature = mkOption {
      type = types.bool;
      default = false;
      description = "Verifica commit.verification.verified tramite API GitHub.";
    };

    reboot = {
      mode = mkOption {
        type = types.enum [ "manual" "managed" ];
        default = "manual";
        description = ''
          manual: nixos-rebuild switch, nessun reboot automatico.
          managed: nixos-rebuild boot + reboot nella finestra configurata.
        '';
      };

      window = mkOption {
        type = types.nullOr (types.submodule {
          options.lower = mkOption {
            type = types.strMatching "[0-9]{2}:[0-9]{2}";
            default = "03:00";
            description = "Limite inferiore HH:MM, ora locale.";
          };
          options.upper = mkOption {
            type = types.strMatching "[0-9]{2}:[0-9]{2}";
            default = "04:00";
            description = "Limite superiore HH:MM, ora locale.";
          };
        });
        default = null;
        description = "Finestra di reboot. null = reboot appena possibile.";
      };

      bootCountingTries = mkOption {
        type = types.int;
        default = 3;
        description = "Tentativi systemd-boot prima del fallback automatico.";
      };

      healthCheck = {
        enable = mkEnableOption "reboot se un'unità critica non parte";

        units = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Unità systemd che devono essere attive prima di boot-complete.target.";
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      boot.loader.systemd-boot.bootCounting.enable = true;
      boot.loader.systemd-boot.bootCounting.tries = cfg.reboot.bootCountingTries;

      systemd.tmpfiles.settings."10-reboot-auto-update"."${cfg.stateDir}".d = {
        mode = "0700";
        user = "root";
        group = "root";
      };

      systemd.services.reboot-auto-update = {
        description = "Aggiorna NixOS da github:${cfg.repo}/${cfg.branch}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = with pkgs; [ git coreutils gawk curl jq nix nixos-rebuild ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = updateScript;
          TimeoutStartSec = cfg.timeoutSec + 60;
          User = "root";
        };
      };

      systemd.timers.reboot-auto-update = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.checkInterval;
          RandomizedDelaySec = cfg.randomizedDelaySec;
          Persistent = true;
          Unit = "reboot-auto-update.service";
        };
      };

      networking.networkmanager.dispatcherScripts = [
        {
          type = "basic";
          source = pkgs.writeShellScript "reboot-auto-update-nm" ''
            [ "$2" = "up" ] || exit 0
            ${pkgs.networkmanager}/bin/nm-online -q -x -t 5 || exit 0
            systemctl start --no-block reboot-auto-update.service
          '';
        }
      ];
    }

    (mkIf (cfg.reboot.mode == "managed") {
      systemd.services.reboot-auto-update-reboot = {
        description = "Riavvio nella generazione staged nella finestra configurata";
        after = [ "reboot-auto-update.service" ];
        path = with pkgs; [ coreutils systemd ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = rebootScript;
          User = "root";
        };
      };

      systemd.timers.reboot-auto-update-reboot = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/5";
          Persistent = true;
          Unit = "reboot-auto-update-reboot.service";
        };
      };
    })

    (mkIf (cfg.reboot.mode == "managed" && cfg.reboot.healthCheck.enable) {
      systemd.services.reboot-auto-update-healthcheck = {
        description = "Healthcheck di boot per reboot-auto-update";
        before = [ "boot-complete.target" ];
        wantedBy = [ "boot-complete.target" ];
        path = with pkgs; [ systemd ];
        unitConfig.FailureAction = "reboot";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = healthScript;
          User = "root";
        };
      };
    })
  ]);
}
