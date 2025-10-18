-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<C-M-Up>", ":resize +5<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-M-Down>", ":resize -5<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-M-Left>", ":vertical resize -5<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-M-Right>", ":vertical resize +5<CR>", { noremap = true, silent = true })

if vim.g.vscode then
  local opts = { noremap = true, silent = true }

	local mappings = {
		-- Word Navigation
		{ 'n', 'w', 'cursorWordPartRight' },
		{ 'n', 'b', 'cursorWordPartLeft' },
		{ 'v', 'w', 'cursorWordPartRightSelect' },
		{ 'v', 'b', 'cursorWordPartLeftSelect' },
	}

	for _, mapping in ipairs(mappings) do
		local mode, key, command = mapping[1], mapping[2], mapping[3]

		vim.keymap.set(mode, key, function() vim.fn.VSCodeNotify(command) end, opts)
	end
end

vim.keymap.set("i", "<C-M-Right>", function()
  require("blink.cmp").show()
end, { desc = "Принудительно открыть автодополнение (blink.cmp)" })

-- ToggleTerm: открыть/закрыть терминал по Cmd+J
if not vim.g.vscode then
  local opts = { noremap = true, silent = true, desc = "Toggle terminal (Cmd+J)" }
  vim.keymap.set("n", "<C-j>", "<cmd>ToggleTerm<cr>", opts)
  -- в режиме терминала тоже удобно закрывать/переключать
  vim.keymap.set("t", "<C-j>", [[<C-\><C-n><cmd>ToggleTerm<cr>]], { noremap = true, silent = true })
end

-- Перемещение сторок вврех/вниз 
if not vim.g.vscode then
  vim.keymap.set("n", "<C-S-Up>", ":m .-2<CR>==", { desc = "Move line up" })
  vim.keymap.set("n", "<C-S-Down>", ":m .+1<CR>==", { desc = "Move line down" })
  vim.keymap.set("v", "<C-S-Up>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
  vim.keymap.set("v", "<C-S-Down>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
end
