return {
	{
		"rebelot/kanagawa.nvim",
		name = "kanagawa",
		priority = 1000,
		opts = {
			theme = "dragon",
			transparent = true,
			-- per kanagawa.nvim README: `transparent` only clears Normal's bg,
			-- gutter and floats need to be cleared separately.
			colors = {
				theme = { all = { ui = { bg_gutter = "none" } } },
			},
			overrides = function(colors)
				return {
					NormalFloat = { bg = "none" },
					FloatBorder = { bg = "none" },
					FloatTitle = { bg = "none" },
					-- default WinSeparator uses dragonBlack0 (near-black, clashes with the palette)
					WinSeparator = { fg = colors.palette.dragonBlack4 },
				}
			end,
		},
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "kanagawa-dragon",
		},
	},
}
