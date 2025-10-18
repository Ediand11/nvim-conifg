return {
  "lewis6991/gitsigns.nvim",
  opts = {
    current_line_blame = true, -- включает blame на текущей строке
    current_line_blame_opts = {
      virt_text = true, -- показывать текст рядом
      virt_text_pos = "eol", -- позиция: "eol", "overlay", "right_align"
      delay = 10, -- без задержки
      ignore_whitespace = false,
    },
    current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> • <summary>", -- формат текста
  },
}
