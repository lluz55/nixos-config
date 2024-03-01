{ }:
{
	imports = [
		./nvim-cmp.nix
		./telescope.nix
		./lsp.nix
		./neotree.nix
	];
	programs.nixvim = {
		enable = true;
    colorschemes.gruvbox.enable = true;

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
	};
}
