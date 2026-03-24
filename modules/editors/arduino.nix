{ config, unstable, lib, masterUser, ... }:

with lib;
{
  options.arduino.enable = mkOption {
    type = types.bool;
    default = false;
    description = mdDoc "Enable use of Arduino IDE";
  };

  config =
    mkIf config.arduino.enable {
      # TODO: Must do: sudo `chmod a+rw /dev/tty****`
      environment.systemPackages = with unstable; [
        arduino
      ];
      users.users."${masterUser.name}" = {
        extraGroups = [
          "dialout" # For Arduino
        ];
      };
    };
}
