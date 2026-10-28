return {
	{
		"gbprod/nord.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true,
			on_highlights = function(highlights, colors)
				highlights.WinSeparator = { fg = colors.polar_night.brightest, bold = true }
				highlights.LineNr = { fg = colors.polar_night.light }
				highlights.LineNrAbove = { fg = colors.polar_night.light }
				highlights.LineNrBelow = { fg = colors.polar_night.light }
				-- nord.nvim's `transparent` only clears Normal/SignColumn; floats and
				-- non-current windows need explicit overrides (old `styles.floats`/`sidebars`)
				highlights.NormalFloat = { fg = colors.snow_storm.origin, bg = colors.none }
				highlights.FloatBorder = { fg = colors.polar_night.brightest, bg = colors.none }
				highlights.WhichKeyFloat = { bg = colors.none }
				highlights.NormalNC = { fg = colors.snow_storm.origin, bg = colors.none }
			end,
		},
		config = function(_, opts)
			require("nord").setup(opts)
			vim.cmd.colorscheme("nord")
		end,
	},
}
