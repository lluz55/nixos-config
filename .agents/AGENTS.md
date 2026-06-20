# NixOS Config Workspace Rules

Essas regras servem como guia padrão para qualquer agente operando neste repositório.

## 1. Estrutura e Modularidade
* **Organização**: Toda configuração deve ser modular. Evite colocar configurações genéricas diretamente nos arquivos de host (em `/hosts/`). Se um serviço puder ser reaproveitado, coloque-o como um módulo em `/modules/` e importe-o.
* **Overlays e Pacotes**: Pacotes customizados (como `openai-codex` ou `waydroidsu`) devem ser mantidos em `/pkgs/` e expostos na flake principal (`flake.nix`).

## 2. Segurança e Segredos (SOPS-NIX)
* **Segredos Criptografados**: Sob nenhuma circunstância declare senhas, chaves privadas, hashes de senhas em texto plano, ou tokens diretamente no código Nix.
* **Uso do SOPS**: Todos os segredos devem ser inseridos em `/secrets/secrets.yaml` utilizando a ferramenta SOPS e importados na configuração via módulo `sops-nix`.

## 3. Construção e Atualização
* **Compilação**: Sempre utilize o build puro sempre que possível. Quando utilizar `--impure`, garanta que os caminhos absolutos adicionados façam sentido para a máquina alvo.
* **Flake Lock**: Não atualize os inputs do flake (`flake.lock`) arbitrariamente via `nix flake update` a menos que seja especificamente necessário ou solicitado pelo usuário.
* **Nixos Anywhere**: Para deploy em novas máquinas, verifique se a chave SSH pública foi adicionada na configuração correspondente antes de executar.
