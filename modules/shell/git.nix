{ pkgs, ... }:
{
  home-manager.users.lluz = {
    programs.git = {
      enable = true;
      userName = "lluz55";
      userEmail = "lucasluz55@gmail.com";
    };
  };
}
