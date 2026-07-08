return {
  {
    "NvChad/nvim-colorizer.lua",
    event = "LazyFile",
    opts = {
      filetypes = {
        "css",
        "scss",
        "html",
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "vue",
        "svelte",
        "lua",
        "conf",
        "toml",
      },
      user_default_options = {
        RGB      = true,
        RRGGBB   = true,
        names    = false,
        RRGGBBAA = true,
        css      = true,
        css_fn   = true,
        mode     = "background",
      },
    },
  },
}
