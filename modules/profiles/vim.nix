{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.profiles.vim;
in {
  options.profiles.vim = with lib; {
    enable = mkEnableOption "enable vim profile";
    dev = mkOption {
      # TODO unused, but not sure where all it's referenced
      type = types.bool;
      default = false;
      description = "Whether to enable development plugins like haskell/js";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      viAlias = true;
      vimAlias = true;

      colorschemes.gruvbox.enable = true;

      globals = {
        # Tab/Indent Settings
        tabstop = 2;
        shiftwidth = 2;
        softtabstop = 2;
        expandtab = true;
        autoindent = true;

        # Line Numbers
        number = true;
        relativenumber = true;

        # Leader/Clipboard/Junk Files
        mapleader = " ";
        maplocalleader = " ";
        clipboard = "unnamedplus";
        noswapfile = true;
        nobackup = true;
        nowritebackup = true;

        # Appearance/Term
        termguicolors = true;
        t_Co = 256;

        # Other Basic Settings
        mouse = "a";
        cmdheight = 2;
        updatetime = 300;
        signcolumn = true;
        splitbelow = true;
        splitright = true;
        virtualedit = "none";
        syntax = "on";
        ignorecase = true;
        smartcase = true;
        hidden = true;
        autoread = true;
        wildmenu = true;
      };

      globals = {
        gruvbox_bold = true;
        gruvbox_italic = true;
        gruvbox_transparent_bg = true;
        gruvbox_hls_cursor = true;
        nord_uniform_status_line = true;
        nvim_tree_side = true;
        nvim_tree_width = true;
      };

      keymaps = [
        {
          key = "<leader>lA";
          action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
        }
        {
          key = "<leader>lD";
          action = "<cmd>lua require('telescope.builtin').lsp_definitions()<CR>";
        }
        {
          key = "<leader>le";
          action = "<cmd>lua require('telescope.builtin').diagnostics({bufnr=0})<CR>";
        }
        {
          key = "<leader>lE";
          action = "<cmd>lua require('telescope.builtin').diagnostics()<CR>";
        }
        {
          key = "<leader>lI";
          action = "<cmd>lua require('telescope.builtin').lsp_implementations()<CR>";
        }
        {
          key = "<leader>lr";
          action = "<cmd>lua require('telescope.builtin').lsp_references()<CR>";
        }
        {
          key = "<leader>lR";
          action = "<cmd>lua vim.lsp.buf.rename()<CR>";
        }
        {
          key = "<leader>ls";
          action = "<cmd>lua vim.diagnostic.setloclist()<CR>";
        }
        {
          key = "[d";
          action = "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>";
        }
        {
          key = "]d";
          action = "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>";
        }
        {
          key = "<leader>t";
          action = "<cmd>terminal<CR>";
        }
        {
          key = "<leader>ft";
          action = "<cmd>NvimTreeToggle<cr>";
        }
        {
          key = "<f10>";
          action = "<cmd>lua require('dap').step_over()<CR>";
        }
        {
          key = "<f11>";
          action = "<cmd>lua require('dap').step_into()<CR>";
        }
        {
          key = "<f12>";
          action = "<cmd>lua require('dap').step_out()<CR>";
        }
        {
          key = "<f5>";
          action = "<cmd>lua require('dap').continue()<CR>";
        }
        {
          key = "<f9>";
          action = "<cmd>lua require('dap').repl.open()<CR>";
        }
      ];

      plugins = {
        avante = {
          enable = true;
        };

        lsp = {
          enable = true;
          servers = {
            hls = {
	      enable = true;
              installGhc = false;
	    };
            rust_analyzer = {
	      enable = true;
	      installCargo = false;
              installRustc = false;
	    };
            pyright.enable = true;
            ts_ls.enable = true;
            phpactor.enable = true;
            elmls.enable = true;
            bashls.enable = true;
            clangd.enable = true;
            cmake.enable = true;
            cssls.enable = true;
            dockerls.enable = true;
            elixirls.enable = true;
            gopls.enable = true;
            html.enable = true;
            jsonls.enable = true;
            vimls.enable = true;
            yamlls.enable = true;
            zls.enable = true;
          };
        };

        cmp = {enable = true;};
        luasnip.enable = true;
        friendly-snippets.enable = true;
        lsp-signature.enable = true;

        treesitter = {
          enable = true;
          grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            nix
            haskell
            rust
            php
            python
            javascript
            typescript
            tsx
            elm
            bash
            c
            cpp
            json
            yaml
            go
            html
            css
          ];
        };

        nvim-tree.enable = true;
        web-devicons.enable = true;

        which-key.enable = true;
        colorizer.enable = true;
        indent-blankline.enable = true;
        telescope.enable = true;
        lualine.enable = true;
        vim-dadbod-ui.enable = true;
        vim-test.enable = true;
      };

      extraPackages = with pkgs; [
        ripgrep
        fd
        nil
        rust-analyzer
        pyright
        typescript-language-server
        phpactor
        unison
        clang-tools
        elixir-ls
      ];

      # option doesn't exist, I might need to find out where to put these
      #luaConfig = lib.concatLines [
      #  ''
      #    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
      #      vim.lsp.handlers.hover,
      #      { border = 'rounded' }
      #    )
      #    vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
      #      vim.lsp.handlers.signature_help,
      #      { border = 'rounded' }
      #    )
      #    require 'colorizer'.setup()
      #    vim.cmd [[highlight IndentOdd guifg=NONE guibg=#222222 gui=nocombine]]
      #    vim.cmd [[highlight IndentEven guifg=NONE guibg=#333333 gui=nocombine]]
      #    vim.g.indent_blankline_char_highlight_list = {"IndentOdd", "IndentEven"}
      #    vim.g.indent_blankline_char = " "
      #    vim.g.indent_blankline_show_trailing_blankline_indent = false
      #  ''
      #];
    };
  };
}
