{ pkgs, ... }:

# Niente configurazione qui: solo strumenti già dentro il sistema.
# Ogni agente parte con i CLI che serve e fa come vuole.
{
  environment.systemPackages = with pkgs; [
    # agent CLI
    opencode
    claude-code
    codex
    copilot-cli
    crush
    gemini-cli
    amp
    goose

    # modelli locali e automazione
    ollama
    n8n

    # devops
    docker
    docker-compose
    k9s
    terraform
    pulumi

    # strumenti Nix
    direnv
    nixfmt
    statix
    deadnix
    nil
    nixd
    alejandra

    # terminale
    ghostty
    wezterm
    kitty
    alacritty
    foot
    tmux
    zsh
    fzf
    ripgrep
    fd
    bat
    eza
    zoxide
    lazygit
    lazydocker
    btop

    # editor
    neovim
    helix
    vscode
    vscodium
    zed

    # base
    git
    curl
    jq
    yq
  ];
}
