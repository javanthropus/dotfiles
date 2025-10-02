return {
  {
    "Pocco81/auto-save.nvim",
    lazy = false,
    opts = {
      condition = function(buf)
        local fn = vim.fn
        local utils = require("auto-save.utils.data")

        -- First check the default conditions
        if not (fn.getbufvar(buf, "&modifiable") == 1 and utils.not_in(fn.getbufvar(buf, "&filetype"), {})) then
          return false
        end

        -- Exclude claudecode diff buffers by buffer name patterns
        local bufname = vim.api.nvim_buf_get_name(buf)
        if bufname:match("%(proposed%)") or
          bufname:match("%(NEW FILE %- proposed%)") or
          bufname:match("%(New%)") then
          return false
        end

        -- Exclude by buffer variables (claudecode sets these)
        if vim.b[buf].claudecode_diff_tab_name or
          vim.b[buf].claudecode_diff_new_win or
          vim.b[buf].claudecode_diff_target_win then
          return false
        end

        -- Exclude by buffer type (claudecode diff buffers use "acwrite")
        local buftype = fn.getbufvar(buf, "&buftype")
        if buftype == "acwrite" then
          return false
        end

        return true -- Safe to auto-save
      end,
      debounce_delay = 500,
      execution_message = {
        message = function()
          return ""
        end,
      },
    },
    keys = {
      { "<leader>uv", "<cmd>ASToggle<CR>", desc = "Toggle autosave" },
    },
  },
}
