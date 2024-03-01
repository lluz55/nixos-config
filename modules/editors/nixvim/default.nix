{ pkgs, ... }:
{
	imports = [
		./nvim-cmp.nix
		./telescope.nix
		./lsp.nix
		./neotree.nix
	];
	programs.nixvim = {
		enable = true;
    # colorschemes.gruvbox.enable = true;
		colorschemes.catppuccin.enable = true;

		options = {
			number = true;
			relativenumber = true;

			shiftwidth = 2;
			fileencoding = "utf-8";
		};

		globals = {
			mapleader = " ";
			maplocalleader = " ";
		};

		plugins.bufferline = {
			enable = true;
		};

		plugins.lightline = {
			enable = true;
			  active = {
          left = [
            ["mode" "paste"]
            ["redaonly" "filename" "modified" ]
          ];
        };
		};
		plugins.treesitter.enable = true;

		extraPlugins = with pkgs;[
			vimPlugins.lazygit-nvim			
			vimPlugins.which-key-nvim
		];
	};
}
