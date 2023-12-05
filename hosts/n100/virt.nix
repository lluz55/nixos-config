{ pkgs, config, lib, ... }: {
  #virtualisation.libvirtd.enable = true;
  #virtualisation = {
  #  #cores = 2;

  #  #memorySize = 2048;
  #  #diskSize = 4096;

  #  lxc.lxcfs.enable = true;
  #  lxd.enable = true;
  #  lxc.enable = true;
  #};

  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

  #networking = {
  #  bridges = {
  #    "virbr0" = {
  #      interfaces = [ "enp2s0" "enp3s0" "enp4s0" ];
  #    };
  #  };
  #  interfaces.virbr0.ipv4.addresses = [{
  #    address = "10.0.0.1";
  #    prefixLength = 24;
  #  }];
  #  defaultGateway = "192.168.100.1";
  #  nameservers = [ "1.1.1.1" ];
  #};

  users.users.lluz = {
    isNormalUser = true;
    extraGroups = [ "qemu-libvirtd" "libvirtd" "wheel" "video" "disk" "networkmanager" ];
    group = "users";
  };
}
