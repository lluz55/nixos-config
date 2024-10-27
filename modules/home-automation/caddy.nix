{ config, lib, ... }:
with lib;
{
  config = mkIf (config.hass.enable)
    {
      services.caddy = {
        enable = false;

        extraConfig = ''
          "http://z2m.home" {
              reverse_proxy 10.1.1.10:8080
          }
          "http://hass.home" {
              reverse_proxy 10.1.1.10:8123
          }
          "http://frigate.home" {
              reverse_proxy 10.1.1.9:5000 
          }
        '';
      };
    };
}
