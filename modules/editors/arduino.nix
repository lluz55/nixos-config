{ config, lib, ... }:

with lib;
{
  config =
    mkIf.arduino.enable {
      users.users.lluz = {
        extraGroups = [
          "dialout" # For Arduino
        ];
      };
    };
}
