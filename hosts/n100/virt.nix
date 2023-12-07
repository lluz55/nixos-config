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

  containers.webserver_test = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br-lan";
    localAddress = "192.168.1.9/24";
    config = {
      system.stateVersion = "23.11";
      services.httpd.enable = true;
      services.httpd.adminAddr = "foo@example.org";
      networking.firewall.allowedTCPPorts = [ 80 ];
    };
  };

  containers.cams-test = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br-cams";
    localAddress = "10.1.1.9/24";
    config = { ... }: {
      system.stateVersion = "23.11";
      environment.systemPackages = with pkgs; [
        nmap
      ];
    };
  };

  users.users.lluz = {
    isNormalUser = true;
    extraGroups = [ "qemu-libvirtd" "libvirtd" "wheel" "video" "disk" "networkmanager" ];
    group = "users";
  };
}
