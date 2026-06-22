-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local opts = { noremap = true, silent = true }
--
-- Window resizing (available everywhere)
local resize_mappings = {
 { "n", "<M-Up>", ":resize +5<CR>" },
 { "n", "<M-Down>", ":resize -5<CR>" },
 { "n", "<M-Left>", ":vertical resize -5<CR>" },
 { "n", "<M-Right>", ":vertical resize +5<CR>" },
}

for _, mapping in ipairs(resize_mappings) do
 vim.keymap.set(mapping[1], mapping[2], mapping[3], opts)
end

-- VSCode-specific keymaps
if vim.g.vscode then
 local vscode_mappings = {
  -- Word Navigation
  { "n", "w", "cursorWordPartRight" },
  { "n", "b", "cursorWordPartLeft" },
  { "v", "w", "cursorWordPartRightSelect" },
  { "v", "b", "cursorWordPartLeftSelect" },
 }

 for _, mapping in ipairs(vscode_mappings) do
  local mode, key, command = mapping[1], mapping[2], mapping[3]
  vim.keymap.set(mode, key, function()
   vim.fn.VSCodeNotify(command)
  end, opts)
 end
end

-- NeoVim-specific keymaps
if not vim.g.vscode then
 -- Blink completion
 vim.keymap.set("i", "<C-M-Right>", function()
  require("blink.cmp").show()
 end, { desc = "Принудительно открыть автодополнение (blink.cmp)" })

 -- ToggleTerm
 vim.keymap.set("n", "<D-j>", "<cmd>ToggleTerm<cr>", vim.tbl_extend("force", opts, { desc = "Toggle terminal" }))
 vim.keymap.set("t", "<D-j>", [[<C-\><C-n><cmd>ToggleTerm<cr>]], opts)

 -- Перемещение строк вверх/вниз
 local move_mappings = {
  { "n", "<D-S-Up>", ":m .-2<CR>==", "Move line up" },
  { "n", "<D-S-Down>", ":m .+1<CR>==", "Move line down" },
  { "v", "<D-S-Up>", ":m '<-2<CR>gv=gv", "Move selection up" },
  { "v", "<D-S-Down>", ":m '>+1<CR>gv=gv", "Move selection down" },
 }

 for _, mapping in ipairs(move_mappings) do
  vim.keymap.set(mapping[1], mapping[2], mapping[3], { desc = mapping[4] })
 end

 -- Save & Format
 vim.keymap.set({ "n", "i", "v" }, "<D-s>", function()
  vim.cmd("silent! w")
  vim.cmd("silent! Format")
 end, { desc = "Save & Format" })
end
