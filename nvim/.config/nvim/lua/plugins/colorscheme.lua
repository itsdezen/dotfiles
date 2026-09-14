return {
	{
		"ellisonleao/gruvbox.nvim",
		name = "gruvbox",
		lazy = false,
		priority = 1000,
		opts = {
			transparent_mode = true,
			overrides = {
				NormalFloat = { bg = "NONE" },
				FloatBorder = { bg = "NONE" },
				FloatTitle = { bg = "NONE" },
				WinSeparator = { fg = "#7c6f64", bold = true },
				LineNr = { fg = "#928374" },
				LineNrAbove = { fg = "#928374" },
				LineNrBelow = { fg = "#928374" },
			},
		},
		config = function(_, opts)
			require("gruvbox").setup(opts)
			vim.cmd.colorscheme("gruvbox")
		end,
	},
}
