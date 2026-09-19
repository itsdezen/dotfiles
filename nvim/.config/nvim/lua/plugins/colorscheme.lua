return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "night",
			transparent = true,
			styles = {
				sidebars = "transparent",
				floats = "transparent",
			},
			on_highlights = function(highlights, colors)
				highlights.WinSeparator = { fg = colors.border, bold = true }
				highlights.LineNr = { fg = colors.fg_gutter }
				highlights.LineNrAbove = { fg = colors.fg_gutter }
				highlights.LineNrBelow = { fg = colors.fg_gutter }
			end,
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight")
		end,
	},
}
