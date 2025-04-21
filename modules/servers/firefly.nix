{ config, unstable, lib, ... }:

with lib;
{
  services.firefly-iii = {
    enable = true;
    virtualHost = "0.0.0.0";
    enableNginx = true;
    settings = {
      DB_CONNECTION = "sqlite";
      APP_KEY_FILE = "/home/lluz/.firefly/keyfile";
      DB_HOST = "localhost";
      APP_URL = "0.0.0.0";
      TZ = "America/Recife";
      TRUSTED_PROXIES = "**";
    };
  };
  
  services.nginx.virtualHosts.fireflyiii.virtualHost = {
    listen = [
      {
        addr = "0.0.0.0";
        port = 9080;
      }
    ];
  };
}
