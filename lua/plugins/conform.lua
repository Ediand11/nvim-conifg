return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      -- JS / TS только eslint_d
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },

      -- CSS через stylelint
      css = { "stylelint" },
      scss = { "stylelint" },
      less = { "stylelint" },
    },

    format_on_save = {
      lsp_fallback = true,
      timeout_ms = 3000,
    },

    formatters = {
      eslint_d = {
        condition = function(self, ctx)
          return vim.fs.find({
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.json",
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.cjs",
          }, { path = ctx.dirname, upward = true })[1] ~= nil
        end,
      },
    },
  },
}
