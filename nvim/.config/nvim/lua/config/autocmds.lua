-- LazyVim sets sane autocmds by default.
-- See: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- LazyVim enables spell for text filetypes (markdown, gitcommit, etc.) — disable it
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "mdx" },
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- Prevent "save Untitled?" prompt on quit. Snacks picker file previews flip
-- their scratch buffer to buftype="" (bufhidden stays "hide", not "wipe") and
-- mark it modified, so match by what it is: an unlisted, unnamed, modified
-- buffer — plugin scratch debris a user buffer (:enew is listed) never matches.
vim.api.nvim_create_autocmd("QuitPre", {
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if
        vim.api.nvim_buf_is_loaded(buf)
        and vim.bo[buf].modified
        and not vim.bo[buf].buflisted
        and vim.api.nvim_buf_get_name(buf) == ""
      then
        vim.bo[buf].modified = false
      end
    end
  end,
})
