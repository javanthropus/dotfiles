-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable diagnostics by default
vim.diagnostic.enable(false)

vim.g.autoformat = false
-- Using auto-save plugin instead
vim.g.autowrite = false

local opt = vim.opt

opt.ignorecase = false
opt.modeline = true
opt.title = true
