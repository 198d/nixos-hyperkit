{config, pkgs, ...}:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  isoImage.isoBaseName = "nixos-custom";

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrDC6yvgqTWFQdUT/DW9BCU84OPV4VWzHinLsk9HUTrhqZ3q09sPhqtwgcVopenKKyVOQbejBhkgzQFDC4rMq+ChIPTSxcVI7Ft0sfmaDX9YmQDNZGJI+70gDD7tbWH6nB6IwzNVkjO2fQYP/rRDPEXOIl64R6w3LjxtNfs9lkzvkDZB8psI0Y9u3DuGDRz4WnPZckAA9BtgzoyYt3MhP7m0DKtNCUWaMGtAqq10O3KeWlY1zN370+sAzQd7wi/yZtSmB+yb2O0llq+wB15kUMntl2FeQab+WYKmfBHv++Y3OLWXjuusEjNzD3g546z1Uvah5Ytq5U91J3a95nKgoL"
  ];
}
