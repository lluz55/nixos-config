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
    neovim

    fastfetch
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;        
  };
  
  services.openssh.settings.PermitRootLogin = "no";

  users.users = {
    lluz = {
      isNormalUser = true;    
       extraGroups = [
         "networkmanager"
         "wheel"
         "docker"
      ];
      hashedPassword = "$y$j9T$nrOY4ikYU3Fsa5e1lKQ47/$MKmDUG2OZmIhNtlpOf4sx7RH2IHVZnZhIoLzAQOvqT0";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEuQb+luFJEkBjPJxhQe27+Uo63aVFJs5sQi/N+bgmw lluz@nixos"
      ];
    };
  };

}
