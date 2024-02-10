{ pkgs, lib, ... }:
with lib;{
  virtualisation.libvirtd = {
    enable = true;
    allowedBridges = [ "br-lan" "br-cams" "virbr0" ];
  };
  virtualisation = {
    #  #cores = 2;

    #  #memorySize = 2048;
    #  #diskSize = 4096;

    #  lxc.lxcfs.enable = true;
    lxd.enable = true;
    lxc.enable = true;
    #qemu = {
    #  options = [
    #    "-enable-kvm "
    #    "-m 512"
    #    "-smp 2 "
    #    "-drive file=/home/lluz/Downloads/openwrt-23.05.2-x86-64-generic-ext4-combined.img,format=raw"
    #    "-device virtio-net-pci,netdev=net0 "
    #    "-netdev bridge,id=net0,br=br-lan "
    #    "-nographic"
    #  ];
    #};
  };
  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];
  #containers.webserver = {
  #  autoStart = true;
  #  privateNetwork = true;
  #  hostBridge = "br-lan";
  #  localAddress = "192.168.1.9/24";
  #  config = { ... }: {
  #    environment.systemPackages = with pkgs; [
  #      netcat
  #      tcpdump
  #    ];
  #    system.stateVersion = "23.11";
  #    services.httpd.enable = true;
  #    services.httpd.adminAddr = "foo@example.org";
  #    networking = {
  #      defaultGateway = "192.168.1.1";
  #      firewall.enable = false;
  #      firewall.allowedTCPPorts = [ 80 8080 ];
  #      useHostResolvConf = mkForce false;
  #    };
  #    services.resolved.enable = true;
  #  };
  #};

  #containers.ntp = {
  #  autoStart = true;
  #  privateNetwork = true;
  #  hostBridge = "br-lan";
  #  localAddress = "192.168.1.123/24";
  #  config = { ... }: {
  #    system.stateVersion = "23.11";
  #    environment.systemPackages = [ ];

  #    networking = {
  #      defaultGateway = "192.168.1.1";
  #      firewall.enable = false;
  #      firewall.allowedTCPPorts = [ ];
  #      firewall.allowedUDPPorts = [ 123 ];
  #      useHostResolvConf = mkForce false;
  #    };
  #    services.resolved.enable = true;
  #  };
  #};

  # Launch HASOS
  #systemd.services.createHAOSVM =
  #  let
  #    virtInstall = "${pkgs.virt-mancager}/bin/virt-install";
  #  in
  #  {
  #    wantedBy = [ "multi-agent.target" ];
  #    script = ''
  #      #TODO: check if hass already exists
  #      #TODO: check if haos image exists
  #      ${virtInstall} \
  #      --name hass \
  #      --description "Home Assistant OS" \
  #      --os-variant=generic \
  #      --ram=2048 \
  #      --vcpus=2 \
  #      --disk /home/${masterUser.name}/Downloads/haos_ova-11.3.qcow2,bus=sata \
  #      --import \
  #      --graphics none \
  #      --network bridge=br-lan \
  #      --boot uefi
  #    '';
  #  };

  #environment.systemPackages = with pkgs; [
  #  virt-manager
  #  virt-viewer
  #  qemu
  #  ## USE UEFI with qemu
  #  #(pkgs.writeScriptBin "qemu-system-x86_64-uefi" ''
  #  #  ${pkgs.qemu}/bin/qemu-system-x86_64 \
  #  #  -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
  #  #  "$@"''
  #  #)

  #  (
  #    pkgs.writeScriptBin "launch_haos" ''
  #      ${pkgs.qemu}/bin/qemu-system-x86_64 \
  #        -enable-kvm \
  #        -m 512 \
  #        -smp 2 \
  #        -drive file=/home/lluz/Downloads/openwrt-23.05.2-x86-64-generic-ext4-combined.img,format=raw \
  #        -device virtio-net-pci,netdev=net0 \
  #        -netdev bridge,id=net0,br=br-lan \
  #        -device virtio-net-pci,netdev=net1 \
  #        -netdev bridge,id=net1,br=br-cams \
  #        -nographic
  #    ''
  #  )
  #];

  users.users.lluz = {
    isNormalUser = true;
    extraGroups = [ "qemu-libvirtd" "libvirtd" "wheel" "video" "disk" "networkmanager" "lxc" "lxd" ];
    group = "users";
  };
}
