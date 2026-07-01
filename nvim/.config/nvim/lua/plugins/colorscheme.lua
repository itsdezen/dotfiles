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
			overrides = function()
				return {
					NormalFloat = { bg = "none" },
					FloatBorder = { bg = "none" },
					FloatTitle = { bg = "none" },
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
