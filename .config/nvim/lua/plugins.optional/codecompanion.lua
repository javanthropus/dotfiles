return {
  "olimorris/codecompanion.nvim",
  version = "^18.0.0",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
    -- Optional: For prettier markdown rendering
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown", "codecompanion" }
    },
  },
  opts = {
    interactions = {
      chat = {
        adapter = "gemini_cli",
      },
    },
    display = {
      chat = {
        window = {
          layout = "horizontal",
          position = "bottom",
          height = 0.3,
        },
      },
    },
    -- opts = {
    --   log_level = "DEBUG",
    -- },
  },
  keys = {
    {
      "<leader>a",
      mode = { "n", "v" },
      desc = "🤖 AI", -- This description is what appears in the hint panel
    },
    -- 1. Normal Mode Keymap: <leader>ac to open chat with file context
    {
      "<leader>ac",
      ":CodeCompanionChat Toggle<CR>",
      mode = "n",
      desc = "💬 Toggle CodeCompanion Chat",
    },
    -- 2. Normal Mode Keymap: <leader>an to open a new chat
    {
      "<leader>an",
      ":CodeCompanionChat<CR>",
      mode = "n",
      desc = "💬 New CodeCompanion Chat",
    },
    -- 3. Visual Mode Keymap: <leader>as to add selection to chat
    {
      "<leader>as",
      ":CodeCompanionChat Add<CR>",
      mode = "v",
      desc = "💬 Add selection to Chat",
    },
  },
}


