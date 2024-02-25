{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viwer
    spice
    spice-gtk
    spice-protocol
    wim-virtio
    win-spice
  ];

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [pkgs.OVMFFull.fd];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
}
