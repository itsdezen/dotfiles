return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
██████╗ ███████╗███████╗███████╗███╗   ██╗
██╔══██╗██╔════╝╚══███╔╝██╔════╝████╗  ██║
██║  ██║█████╗    ███╔╝ █████╗  ██╔██╗ ██║
██║  ██║██╔══╝   ███╔╝  ██╔══╝  ██║╚██╗██║
██████╔╝███████╗███████╗███████╗██║ ╚████║
╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝]],
        },
      },
      picker = {
        icons = {
          tree = {
            vertical = "│ ",
            middle   = "├╴",
            last     = "╰╴",
          },
        },
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
          },

          files = {
            hidden = true,
            ignored = false,
          },
        },
      },
    },
  },
}
