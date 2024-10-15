{ pkgs, config, lib, unstable, modulesPath, ... }:
with lib;{
  imports = [
    ./disk-config.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

  system.stateVersion = "24.11";
                
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };

  environment.systemPackages = with unstable; [
    arp-scan
    killall
    du-dust
    htop
    nmap
    nixfmt-classic

    helix
    nushell
    neovim

    fastfetch
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;        
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # TODO: Create new ssh key and paste public key here
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEuQb+luFJEkBjPJxhQe27+Uo63aVFJs5sQi/N+bgmw lluz@nixos"
  ];

}
