return {
  "stevearc/conform.nvim",
  optional = true,
  opts = {
    formatters_by_ft = {
      ["yaml"] = { "yamlfix" },
      ["yml"] = { "yamlfix" },
    },
  },
}
