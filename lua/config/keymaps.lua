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
  vim.keymap.set("n", "<D-j>", "<cmd>ToggleTerm<cr>", opts)
  -- в режиме терминала тоже удобно закрывать/переключать
  vim.keymap.set("t", "<D-j>", [[<C-\><C-n><cmd>ToggleTerm<cr>]], { noremap = true, silent = true })
end

-- Перемещение сторок вврех/вниз 
if not vim.g.vscode then
  vim.keymap.set("n", "<D-S-Up>", ":m .-2<CR>==", { desc = "Move line up" })
  vim.keymap.set("n", "<D-S-Down>", ":m .+1<CR>==", { desc = "Move line down" })
  vim.keymap.set("v", "<D-S-Up>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
  vim.keymap.set("v", "<D-S-Down>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })

	vim.keymap.set({ "n", "i", "v" }, "<D-s>", function()
		vim.cmd("silent! w")
		vim.cmd("silent! Format")
	end, { desc = "Save & Format" })
end

-- WebOS плагин keymaps
if not vim.g.vscode then
  local webos = require("plugins.webos")
  
  -- Открыть модальное окно WebOS
  vim.keymap.set("n", "<leader>wo", function() webos.open() end, { desc = "WebOS: Открыть меню" })
  
  -- Быстрые команды (используют устройство по умолчанию)
  vim.keymap.set("n", "<leader>wi", function() webos.install() end, { desc = "WebOS: Установить приложение" })
  vim.keymap.set("n", "<leader>wr", function() webos.install_and_run() end, { desc = "WebOS: Установить и запустить" })
  vim.keymap.set("n", "<leader>wd", function() webos.inspect() end, { desc = "WebOS: Инспектировать" })
  vim.keymap.set("n", "<leader>wc", function() webos.connect() end, { desc = "WebOS: Подключиться (novacom)" })
  
  -- Управление устройствами
  vim.keymap.set("n", "<leader>wf", function() webos.refresh_devices() end, { desc = "WebOS: Обновить список устройств" })
  vim.keymap.set("n", "<leader>wp", function() webos.set_default_device() end, { desc = "WebOS: Установить устройство по умолчанию" })
  
  -- Команды для конкретного устройства
  vim.keymap.set("n", "<leader>wI", function() webos.install_to_device() end, { desc = "WebOS: Установить на устройство" })
  vim.keymap.set("n", "<leader>wT", function() webos.install_and_run_to_device() end, { desc = "WebOS: Установить и запустить на устройстве" })
  vim.keymap.set("n", "<leader>wD", function() webos.inspect_device() end, { desc = "WebOS: Инспектировать устройство" })
  vim.keymap.set("n", "<leader>wC", function() webos.connect_to_device() end, { desc = "WebOS: Подключиться к устройству" })
end
