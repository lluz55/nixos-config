{ pkgs, lib, config, masterUser, ... }:
let
  launch_vnc = (pkgs.writeScriptBin "launch_vnc" ''
    #!${pkgs.stdenv.shell}
    ${pkgs.turbovnc}/bin/Xvnc -iglx -depth 24 -rfbwait 120000 -deferupdate 1 -securitytypes none & DISPLAY=:0 ${pkgs.i3}/bin/i3 -c /home/${masterUser.name}/.config/i3/config 
  ''
  );
in
with lib; {
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.opengl.enable = true;

  gnome.enable = false;
  vscode-server.enable = false;

  networking.interfaces.eno1.wakeOnLan.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };
  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 3389 ];
  networking.hostName = "b450";

  # HOW TO RUN TURBOVNC SERVER 
  # Xvnc -iglx -depth 24 -rfbwait 120000 -deferupdate 1 -securitytypes none & DISPLAY=:0 i3 
  programs.turbovnc.ensureHeadlessSoftwareOpenGL = true;

  environment.pathsToLink = [ "/libexec" ];
  services = {
    xserver = {
      enable = false;
      videoDrivers = [ "nvidia" ];

      desktopManager = {
        xterm.enable = false;
        xfce.enable = false;
      };
      displayManager = {
        lightdm.enable = false;
        autoLogin = {
          enable = true;
          user = "lluz";
        };
      };
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          i3status # gives you the default i3 status bar
          i3lock #default i3 screen locker
          i3blocks #if you are planning on using i3blocks over i3status
          picom-next
          rofi
          dmenu #application launcher most people use
        ];
      };
    };
  };
  # Automatic start Xvnc
  systemd.services.xvnc = {
    script = ''
      echo "Launch VNC"
      #${pkgs.turbovnc}/bin/Xvnc -iglx -depth 24 -rfbwait 120000 -deferupdate 1 -securitytypes none & DISPLAY=:0 ${pkgs.i3}/bin/i3 -c /home/${masterUser.name}/.config/i3/config 
    '';
    wantedBy = [ "multi-user.target" ];
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 2;
    };
  };

  programs.light.enable = true;

  #sway.enable = true;

  environment = {
    systemPackages = with pkgs; [
      turbovnc
      vscode
      vivaldi
      launch_vnc
    ];
  };

}
