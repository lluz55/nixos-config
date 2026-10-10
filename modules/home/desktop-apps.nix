{
  lib,
  osConfig,
  unstable,
  codeaf,
  ...
}:
{
  # Personal interactive applications belong to Home Manager. The condition
  # prevents headless hosts that import desktopProfile (notably n100) from
  # receiving GUI applications when profiles.desktop.enable is false.
  home.packages = lib.optionals osConfig.profiles.desktop.enable (with unstable; [
    vscode
    brave
    (vivaldi.override {
      proprietaryCodecs = true;
    })
    vivaldi-ffmpeg-codecs
    remmina
    x2goclient
    turbovnc
    twingate
    codeaf
  ]);
}
