-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<C-M-Up>", ":resize +5<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-M-Down>", ":resize -5<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-M-Left>", ":vertical resize -5<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-M-Right>", ":vertical resize +5<CR>", { noremap = true, silent = true })

vim.keymap.set("i", "<C-M-Right>", function()
  require("blink.cmp").show()
end, { desc = "Принудительно открыть автодополнение (blink.cmp)" })
