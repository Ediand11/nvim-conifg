-- bootstrap lazy.nvim, LazyVim and your plugins
-- vim.opt.foldmethod = "expr"
-- vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- vim.opt.foldlevel = 99
-- vim.opt.foldlevelstart = 1
-- vim.cmd("language en_US.UTF-8")

-- Устанавливаем размер табуляции (например, 2 пробела)
-- vim.opt.tabstop = 2
-- vim.opt.shiftwidth = 2
-- vim.opt.softtabstop = 2
--
-- -- Включаем использование пробелов вместо табуляции
-- vim.opt.expandtab = true

vim.opt.spell = false
require("config.lazy")
