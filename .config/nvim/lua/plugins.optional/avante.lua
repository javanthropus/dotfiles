return {
  {
    "javanthropus/avante.nvim",
    branch = 'fixes',
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- ⚠️ must add this setting! ! !
    -- build = vim.fn.has("win32") and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      -- or "make",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    ---@module 'avante'
    ---@type avante.Config
    opts = {
      --debug = true,
      -- add any opts here
      -- for example
      windows = {
        position = "smart",
        force_stacked_layout = true,
      },
      mappings = {
        submit = {
          -- insert = "<C-CR>",
        },
      },
      provider = "gemini-cli",
      acp_providers = {
        ["gemini-cli"] = {
          env = {
            NODE_NO_WARNINGS = "1",
          },
          -- This disables any attempt to authenticate explicitly, which for
          -- gemini-cli means that oauth-personal is used.
          auth_method = false,
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "nvim-mini/mini.pick", -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "stevearc/dressing.nvim", -- for input provider dressing
      "folke/snacks.nvim", -- for input provider snacks
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
