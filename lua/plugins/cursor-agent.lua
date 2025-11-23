return {
  "xTacobaco/cursor-agent.nvim",
  config = function()
    vim.keymap.set("n", "<leader>ci", ":CursorAgent<CR>", { desc = "Cursor Agent: Toggle terminal" })
    vim.keymap.set("v", "<leader>ci", ":CursorAgentSelection<CR>", { desc = "Cursor Agent: Send selection" })
    vim.keymap.set("n", "<leader>cI", ":CursorAgentBuffer<CR>", { desc = "Cursor Agent: Send buffer" })
  end,
}
