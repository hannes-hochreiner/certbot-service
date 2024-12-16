export def build [] {
  nix build
}

export def update [] {
  nix flake update
}