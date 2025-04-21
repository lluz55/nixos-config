{ config, unstable, lib, ... }:

with lib;
{
  virtualisation.oci-containers.containers = {
          actual = {
            image = "ghcr.io/actualbudget/actual-server:latest";
            extraOptions = [
              "--network=host"
            ];
            volumes = [
              "/home/lluz/.actual:/data"
            ];
            environment = {
              TZ = "America/Recife";
            };
            ports = [
              "5006:5006"
            ];
          };
        };
}
