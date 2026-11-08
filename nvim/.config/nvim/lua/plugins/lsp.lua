-- Server definitions and global capabilities. These have to exist before the
-- first client attaches.
--
-- nvim-lspconfig v2 only ships `lsp/*.lua` config files; nothing to set up.
-- Tool binaries come from mise (see mise/config.toml); no plugin installs them.
vim.lsp.config("*", {
  capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
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
    vtsls = { autoUseWorkspaceTsdk = true },
  },
})

vim.lsp.config("basedpyright", {
  settings = {
    python = { analysis = { typeCheckingMode = "basic" } },
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

-- LSP keymaps + native inline completion (`vim.lsp.completion` replaces
-- blink.cmp: autotrigger on insert, <C-n>/<C-p> to pick from the menu).
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("LspKeys", { clear = true }),
  callback = function(event)
    local buf = event.buf
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then return end

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
    end

    map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
    map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
    map("n", "gr", vim.lsp.buf.references, "References")
    map("n", "gI", vim.lsp.buf.implementation, "Goto Implementation")
    map("n", "gy", vim.lsp.buf.type_definition, "Goto Type Definition")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
    map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
    map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")

    vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })

    -- Words under the cursor, across the whole buffer.
    if client:supports_method("textDocument/documentHighlight") then
      map("n", "]]", function() Snacks.words.jump(vim.v.count1) end, "Next Reference")
      map("n", "[[", function() Snacks.words.jump(-vim.v.count1) end, "Prev Reference")
    end
  end,
})
