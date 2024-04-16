{ config, unstable, lib, ... }:

with lib;
{
  config =
    mkIf.arduino.enable {
      # TODO: Must do: sudo `chmod a+rw /dev/tty****`
      environment.systemPackages = with unstable; [
        arduino
      ];
      users.users.lluz = {
        extraGroups = [
          "dialout" # For Arduino
        ];
      };
    };
}
