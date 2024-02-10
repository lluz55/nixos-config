{
  masterUser = {
    name = "lluz";
    terminal = "kitty";
    editor = "nvim";
    wallpaper = "./wallpapers/landscape.png";
    is_router = true;
    user = {
      users.users.lluz = {
        isNormalUser = true;
        hashedPassword = "$6$JogEHvo2duy/W0Wa$6cFqRMbSTcry5v8kkfsXna61/TsWH0F5q0HsbXP.tMZvfvXydQX8EanJdiIcMijuLhyqj5Deg8HL/cerMuEO7/";
        extraGroups = [ "audio" "camera" "networkmanager" "video" "wheel" "docker" ];
      };
    };
  };
  karolayne = {
    name = "karolayne";
    user = {
      users.users.karolayne = {
        isNormalUser = true;
        hashedPassword = "$6$/yQn3vgw4HMwHhrm$TPlUa7xHtN3c3dXOFL5kOk7jVugIYtr.DmoI7v7lFy9sQNkLOwmxf.ksfMm7nXmeJTGuqW58Qdi.NISbxbjlg1";
        extraGroups = [ "audio" "camera" "video" ];
      };
    };
  };
}
