{ pkgs, config, lib, ... }:
with lib;{
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
  containers.webserver = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br-lan";
    localAddress = "192.168.1.9/24";
    config = { ... }: {
      environment.systemPackages = with pkgs; [
        netcat
        tcpdump
      ];
      system.stateVersion = "23.11";
      services.httpd.enable = true;
      services.httpd.adminAddr = "foo@example.org";
      networking = {
        defaultGateway = "192.168.1.1";
        firewall.enable = false;
        firewall.allowedTCPPorts = [ 80 8080 ];
        useHostResolvConf = mkForce false;
      };
      services.resolved.enable = true;
    };
  };

  containers.ntp = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br-lan";
    localAddress = "192.168.1.123/24";
    config = { ... }: {
      system.stateVersion = "23.11";
      environment.systemPackages = [ ];

      networking = {
        defaultGateway = "192.168.1.1";
        firewall.enable = false;
        firewall.allowedTCPPorts = [ ];
        firewall.allowedUDPPorts = [ 123 ];
        useHostResolvConf = mkForce false;
      };
      services.resolved.enable = true;
    };
  };

  users.users.lluz = {
    isNormalUser = true;
    extraGroups = [ "qemu-libvirtd" "libvirtd" "wheel" "video" "disk" "networkmanager" ];
    group = "users";
  };
}
