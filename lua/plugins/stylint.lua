return {
  {
    "neoclide/coc.nvim",
    branch = "release",
    dependencies = {
      "neoclide/coc-stylelint"
    },
    config = function()
      vim.g.coc_global_extensions = {
        'coc-stylelint'
      }
    end
  }
}
