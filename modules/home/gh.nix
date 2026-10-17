{...}: {
  # O Git usa a sessão autenticada do gh sem gravar tokens na configuração Nix.
  # Declarativo: `gh auth setup-git` não pode editar o gitconfig do Home Manager.
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };
}
