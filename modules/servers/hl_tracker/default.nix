#
# Editors
#
{pkgs, inputs, ...}:{

imports = [
   inputs.hl-caddy.nixosModules.default
 ];

  services.hl-caddy = {
    enable = true;
    
    # zrok configuration
    zrok = {
      enable = true;
      environmentFile = "/home/lluz/.nixos-config/modules/servers/hl_tracker/.env"; 
    };

    # Definition of the "hat" app
    services.hat = {
      path = "/hat/";             # Path that Caddy will use to listen for the app
      proxyTo = "localhost:8080"; # Local port where the real 'hat' app is running
    };
  };

}
