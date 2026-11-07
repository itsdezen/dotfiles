local pack = require("config.pack")

-- Mason manages the language servers and the tools.
pack.eager("mason", function()
  require("mason").setup({})
end)

-- Installs the tools that mise does not provide. Its `plugin/` script hooks
-- VimEnter to run the check, so it is loaded as an entrypoint.
pack.eager("mason-tool-installer", function()
  require("mason-tool-installer").setup({
    -- Only tools that mise does not already provide (see mise/config.toml).
    ensure_installed = {
      "tree-sitter-cli",
      "lua-language-server",
      "vtsls",
      "bash-language-server",
      "stylua",
      "shfmt",
      "prettierd",
      "prettier",
    },
    auto_update = false,
    run_on_start = true,
  })
end)

-- The server definitions have to exist before the first client attaches.
pack.eager("nvim-lspconfig", function()
  -- nvim-lspconfig v2 only ships `lsp/*.lua` config files; nothing to set up.
  --
  -- blink.cmp's plugin/ script is not sourced under vim.pack, so the global LSP
  -- capabilities have to be declared here.
  vim.lsp.config("*", {
    capabilities = require("blink.cmp").get_lsp_capabilities({
      workspace = {
        fileOperations = {
          didRename = true,
          willRename = true,
        },
      },
    }),
  })

  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME },
        },
        diagnostics = {
          disable = { "incomplete-signature-doc", "trailing-space" },
        },
      },
    },
  })

  vim.lsp.config("vtsls", {
    settings = {
      complete_function_calls = true,
      vtsls = {
        autoUseWorkspaceTsdk = true,
      },
    },
  })

  vim.lsp.config("basedpyright", {
    settings = {
      python = {
        analysis = { typeCheckingMode = "basic" },
      },
    },
  })

  vim.lsp.config("gopls", {
    settings = {
      gopls = {
        gofumpt = true,
        completeUnimported = true,
        staticcheck = true,
      },
    },
  })

  vim.lsp.config("rust_analyzer", {
    settings = {
      ["rust-analyzer"] = {
        check = { command = "clippy" },
      },
    },
  })

  -- The single source of truth for which servers are active.
  vim.lsp.enable({
    "lua_ls",
    "vtsls",
    "basedpyright",
    "ruff",
    "gopls",
    "rust_analyzer",
    "bashls",
  })
end)

-- Inlay hints and code lenses are opt-in in Neovim 0.11+ (they default to
-- disabled per buffer), so nothing enables them here.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("LspKeys", { clear = true }),
  callback = function(event)
    local buf = event.buf
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    local function has(method)
      return client ~= nil and client:supports_method(method)
    end

    local function map(mode, lhs, rhs, desc, opts_)
      opts_ = opts_ or {}
      opts_.buffer = buf
      opts_.desc = desc
      opts_.silent = true
      vim.keymap.set(mode, lhs, rhs, opts_)
    end

    if has("textDocument/definition") then
      map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
    end
    if has("textDocument/references") then
      map("n", "gr", vim.lsp.buf.references, "References", { nowait = true })
    end
    if has("textDocument/implementation") then
      map("n", "gI", vim.lsp.buf.implementation, "Goto Implementation")
    end
    if has("textDocument/typeDefinition") then
      map("n", "gy", vim.lsp.buf.type_definition, "Goto Type Definition")
    end
    if has("textDocument/declaration") then
      map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
    end
    if has("textDocument/hover") then
      map("n", "K", vim.lsp.buf.hover, "Hover")
    end
    if has("textDocument/signatureHelp") then
      map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
      map("i", "<c-k>", vim.lsp.buf.signature_help, "Signature Help")
    end
    if has("textDocument/codeAction") then
      map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
    end
    if has("textDocument/rename") then
      map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
    end
    if has("textDocument/documentHighlight") then
      map("n", "]]", function() Snacks.words.jump(vim.v.count1) end, "Next Reference")
      map("n", "[[", function() Snacks.words.jump(-vim.v.count1) end, "Prev Reference")
      map("n", "<a-n>", function() Snacks.words.jump(vim.v.count1, true) end, "Next Reference")
      map("n", "<a-p>", function() Snacks.words.jump(-vim.v.count1, true) end, "Prev Reference")
    end
  end,
})
