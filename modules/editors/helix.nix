{ masterUser
, lib
, unstable
, ...
}:
{
  home-manager.users."${masterUser.name}" = {
    programs.helix = {
      enable = true;
      package = unstable.helix;
      defaultEditor = true;

      extraPackages = with unstable; [
        nil
        alejandra
        marksman
        taplo
        yaml-language-server
        bash-language-server
        shellcheck
        shfmt
        wl-clipboard
      ];

      languages = {
        language = [
          {
            name = "nix";
            auto-format = true;
            formatter = { command = "alejandra"; };
          }
          {
            name = "markdown";
            auto-format = true;
          }
          {
            name = "bash";
            auto-format = true;
            formatter = { command = "shfmt"; args = [ "-i" "2" "-ci" ]; };
          }
          {
            name = "toml";
            auto-format = true;
          }
        ];
      };

      settings = {
        theme = lib.mkForce "nocturne_plus";

        editor = {
          true-color = true;
          undercurl = true;
          color-modes = true;
          cursorline = true;
          line-number = "relative";
          bufferline = "multiple";
          popup-border = "all";
          rulers = [ 80 100 ];
          end-of-line-diagnostics = "hint";

          statusline = lib.mkForce {
            left = [ "mode" "spinner" "version-control" "file-name" "read-only-indicator" "file-modification-indicator" ];
            center = [ ];
            right = [ "diagnostics" "workspace-diagnostics" "selections" "position" "position-percentage" "file-type" ];
            separator = "  ";
            mode.normal = "  NORMAL ";
            mode.insert = "  INSERT ";
            mode.select = "  SELECT ";
            diagnostics = [ "warning" "error" ];
            workspace-diagnostics = [ "warning" "error" ];
          };

          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };

          lsp = {
            display-color-swatches = true;
            display-inlay-hints = true;
            display-messages = true;
          };

          file-picker = {
            hidden = false;
            git-ignore = true;
            git-global = true;
            git-exclude = true;
          };

          indent-guides = {
            render = true;
            character = lib.mkForce "│";
            skip-levels = 1;
          };

          gutters = {
            layout = [ "diff" "diagnostics" "line-numbers" "spacer" ];
            line-numbers.min-width = 2;
          };

          inline-diagnostics = {
            cursor-line = "warning";
            other-lines = "error";
            prefix-len = 1;
          };

          soft-wrap = {
            enable = true;
            wrap-indicator = "↪ ";
          };

          whitespace = {
            render = {
              space = "none";
              tab = "all";
              nbsp = "all";
              newline = "none";
            };
            characters = {
              tab = "→";
              tabpad = "·";
              nbsp = "⍽";
            };
          };
        };

        keys.normal = {
          space.space = "file_picker";
          space.F = "file_picker_in_current_directory";
          space.g = "changed_file_picker";
          space.b = "buffer_picker";
          space.d = "diagnostics_picker";
          space.D = "workspace_diagnostics_picker";

          # Atalhos rápidos de navegação e busca
          "C-h" = "goto_previous_buffer";
          "C-l" = "goto_next_buffer";
          "C-w" = ":bc";
          space.f = "global_search";
          space.t.h = ":toggle lsp.display-inlay-hints";
          space.t.s = ":toggle whitespace";
        };
      };

      themes.nocturne_plus = {
        inherits = "catppuccin_mocha";

        "ui.background" = { bg = "base"; };
        "ui.background.separator" = { fg = "surface0"; };
        "ui.cursorline.primary" = { bg = "mantle"; };
        "ui.cursor.match" = { fg = "peach"; modifiers = [ "bold" ]; };
        "ui.gutter" = { fg = "surface2"; bg = "mantle"; };
        "ui.gutter.selected" = { fg = "text"; bg = "mantle"; };
        "ui.linenr" = { fg = "overlay0"; };
        "ui.linenr.selected" = { fg = "yellow"; modifiers = [ "bold" ]; };
        "ui.virtual.ruler" = { bg = "surface0"; };
        "ui.virtual.indent-guide" = { fg = "surface1"; };
        "ui.virtual.indent-guide.active" = { fg = "surface2"; };
        "ui.virtual.whitespace" = { fg = "surface2"; };
        "ui.virtual.inlay-hint" = { fg = "overlay0"; modifiers = [ "italic" ]; };

        "ui.statusline" = { fg = "text"; bg = "mantle"; };
        "ui.statusline.inactive" = { fg = "overlay1"; bg = "crust"; };
        "ui.statusline.normal" = { fg = "base"; bg = "blue"; modifiers = [ "bold" ]; };
        "ui.statusline.insert" = { fg = "base"; bg = "green"; modifiers = [ "bold" ]; };
        "ui.statusline.select" = { fg = "base"; bg = "mauve"; modifiers = [ "bold" ]; };
        "ui.statusline.separator" = { fg = "surface2"; bg = "mantle"; };

        "ui.bufferline" = { fg = "overlay1"; bg = "mantle"; };
        "ui.bufferline.active" = { fg = "text"; bg = "base"; modifiers = [ "bold" ]; };
        "ui.bufferline.background" = { bg = "mantle"; };

        "ui.popup" = { fg = "text"; bg = "mantle"; };
        "ui.popup.border" = { fg = "surface1"; };
        "ui.popup.info" = { fg = "text"; bg = "surface0"; };
        "ui.window" = { fg = "surface1"; };
        "ui.help" = { fg = "text"; bg = "mantle"; };
        "ui.menu" = { fg = "text"; bg = "mantle"; };
        "ui.menu.selected" = { fg = "base"; bg = "blue"; modifiers = [ "bold" ]; };
        "ui.menu.scroll" = { fg = "blue"; bg = "surface0"; };
        "ui.text.focus" = { fg = "text"; bg = "surface0"; modifiers = [ "bold" ]; };
        "ui.text.directory" = { fg = "blue"; modifiers = [ "bold" ]; };
        "ui.selection" = { bg = "surface1"; };
        "ui.selection.primary" = { bg = "surface2"; };
        "ui.highlight" = { bg = "surface0"; };
        "ui.highlight.frameline" = { bg = "red"; };

        "diagnostic.error" = { underline = { color = "red"; style = "curl"; }; };
        "diagnostic.warning" = { underline = { color = "yellow"; style = "curl"; }; };
        "diagnostic.info" = { underline = { color = "blue"; style = "curl"; }; };
        "diagnostic.hint" = { underline = { color = "teal"; style = "curl"; }; };
        error = "red";
        warning = "yellow";
        info = "blue";
        hint = "teal";

        "diff.plus" = "green";
        "diff.minus" = "red";
        "diff.delta" = "yellow";
        "diff.plus.gutter" = "green";
        "diff.minus.gutter" = "red";
        "diff.delta.gutter" = "yellow";
      };
    };
  };
}
