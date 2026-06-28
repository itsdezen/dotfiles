-- LazyVim sets sane autocmds by default.
-- See: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Prevent "save Untitled?" prompt caused by snacks dashboard/image marking nofile buffers modified
vim.api.nvim_create_autocmd("QuitPre", {
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].buftype == "nofile" and vim.bo[buf].modified then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end,
})
