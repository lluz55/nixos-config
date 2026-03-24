{ pkgs
, lib
, config
, ...
}:
with lib; {
  options.virt-tools.enable = mkOption {
    type = types.bool;
    default = false;
    description = mdDoc "Enable virtualization tools";
  };

  config = mkIf config.virt-tools.enable {
    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      virtio-win
      win-spice
    ];

    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
          # ovmf.enable = true;
          # ovmf.packages = [pkgs.OVMFFull.fd];
        };
      };
      spiceUSBRedirection.enable = true;
    };
    services.spice-vdagentd.enable = true;
  };
}
