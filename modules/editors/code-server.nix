{ config, lib, ... }:
with lib;
{
  config = mkIf (config.vscode-server.enable) {
    services.vscode-server.enable = true;
  };
}
