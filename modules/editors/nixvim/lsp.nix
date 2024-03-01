{ unstable, ...}:
{
	programs.nixvim = {

		plugins.lsp = {
			enable = true;
			servers = {
				lua-ls.enable = true;

				tsserver.enable = true;

				rust-analyzer = {
					enable = true;
					installRustc = true;
					rustcPackage = unstable.rustc;
					installCargo = true;
					cargoPackage = unstable.cargo;
					autostart = true;
					settings = {
						numThreads = 8;						
					};
				};

				neo-tree = {
					enable = true;
					
				}
;
				nil_ls.enable = true;
				treesitter.enable = true;

			};
		};

	};
}
