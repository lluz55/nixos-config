{...}:
{
  programs.nixvim = {
    plugins = {
      neo-tree = {
        enable = true;
        sourceSelector.statusline = true;
      };
    };
  };
}
