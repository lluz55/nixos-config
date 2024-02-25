{lib, ...}:
with lib; {
  options = {
    wayland = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enables the wayland configuration
            > Gets enabled when using a wayland wm
        '';
      };
    };
    x11 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enables the x11 configuration
            > Gets enabled when using a x11 wm
        '';
      };
    };
    nvidia = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mkDoc ''
          Enables nvidia drivers
        '';
      };
    };
    gnome = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enable gnome within this flake
        '';
      };
    };
    frigate = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mkDoc ''
          Enable Frigate
        '';
      };
    };
    vscode-server = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mkDoc ''
          Enable VS Code Server
        '';
      };
    };
    hass = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mkDoc ''
          Enable Home Assistant
        '';
      };
    };
    glances = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mkDoc ''
          Enable Glances and creating a startup service for it
        '';
      };
    };
    twingate = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mkDoc ''
          Enable twingate connector
        '';
      };
    };
    hyprland = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mkDoc ''
          Enable hyprland connector
        '';
      };
    };
    virt-tools = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mkDoc ''
          Enable virtualization tools
        '';
      };
    };
  };
}
