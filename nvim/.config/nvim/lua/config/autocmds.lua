-- LazyVim sets sane autocmds by default.
-- See: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- LazyVim enables spell for text filetypes (markdown, gitcommit, etc.) — disable it
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "mdx" },
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- Prevent "save Untitled?" prompt caused by snacks dashboard/image/preview
-- buffers getting marked modified. Picker file previews use buftype="" (not
-- "nofile"), so key off bufhidden="wipe" too — that's how snacks marks any
-- disposable scratch buffer, regardless of buftype.
vim.api.nvim_create_autocmd("QuitPre", {
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local is_scratch = vim.bo[buf].buftype == "nofile" or vim.bo[buf].bufhidden == "wipe"
      if is_scratch and vim.bo[buf].modified and vim.api.nvim_buf_get_name(buf) == "" then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end,
})
