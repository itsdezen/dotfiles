return {
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = false,
		priority = 1000,
		opts = {
			dark_variant = "main",
			styles = {
				transparency = true,
			},
			highlight_groups = {
				NormalFloat = { bg = "none" },
				FloatBorder = { bg = "none" },
				FloatTitle = { bg = "none" },
				WinSeparator = { fg = "highlight_high", bold = true },
				LineNr = { fg = "muted" },
				LineNrAbove = { fg = "muted" },
				LineNrBelow = { fg = "muted" },
			},
		},
		config = function(_, opts)
			require("rose-pine").setup(opts)
			vim.cmd.colorscheme("rose-pine")
		end,
	},
}
