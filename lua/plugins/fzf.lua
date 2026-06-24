-- ~/.config/nvim/lua/plugins/fzf.lua

return {
  {
    "ibhagwan/fzf-lua",
    opts = function(_, opts)
      opts.fzf_opts = vim.tbl_deep_extend("force", opts.fzf_opts or {}, {
        ["--layout"] = "reverse-list",
        ["--info"] = "inline-right",
        ["--no-scrollbar"] = true,
      })

      opts.winopts = vim.tbl_deep_extend("force", opts.winopts or {}, {
        width = 0.9,
        height = 0.85,
        row = 0.5,
        col = 0.5,
        border = "rounded",

        preview = {
          layout = "horizontal",
          horizontal = "right:55%",
          scrollbar = "float",
        },
      })

      return opts
    end,
  },
}
