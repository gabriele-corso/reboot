# Agenti e tool preinstallati

`reboot` è pensato come tavolo da lavoro per agenti. Non impone provider,
modelli, chiavi o configurazioni di OpenCode: ogni utente si autentica e lavora
come vuole.

Il modulo `modules/agents.nix` installa solo strumenti.

## Agent CLI

- `opencode`
- `claude-code`
- `codex`
- `copilot-cli`
- `crush`
- `gemini-cli`
- `amp`
- `goose`

## Modelli locali e automazione

- `ollama`
- `n8n`

## DevOps

- `docker`
- `docker-compose`
- `k9s`
- `terraform`
- `pulumi`

## Strumenti Nix

- `direnv`
- `nixfmt`
- `statix`
- `deadnix`
- `nil`
- `nixd`
- `alejandra`

## Terminale e editor

- `ghostty`, `wezterm`, `kitty`, `alacritty`, `foot`
- `tmux`, `zsh`, `fzf`
- `ripgrep`, `fd`, `bat`, `eza`, `zoxide`
- `lazygit`, `lazydocker`, `btop`
- `neovim`, `helix`, `vscode`, `vscodium`, `zed`

## Base

- `git`, `curl`, `jq`, `yq`

## Nota

Non c'è un comando `reboot-agent` e non c'è una configurazione OpenCode di
default. L'idea è che ogni utente apra il proprio agente dentro il proprio
worktree e decida da sé cosa fare.
